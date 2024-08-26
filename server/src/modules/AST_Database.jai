#module_parameters (DATABASE_FOLDER := "database") ();

LOCK_FILE_NAME :: "lock";
WORKSPACE_MAP_FILE_NAME :: "workspaces_map";
BLOCK_EXP :: 12;

AST_State :: struct {
  initialized: bool;
  
  lock_file: File;
  lock_file_name: string;
  locked: bool;
  
  workspace_map_file: File;
  workspace_map_file_name: string;
  workspace_map: Workspace_Map_Header;
  
  ast_file_states: [..] AST_File_State;
  
  AST_File_State :: struct {
    workspace_index: u64;
    file: File;
    file_name: string;
    header: AST_File_Header;
  }
}

Workspace_Map_Header :: struct {
  map: Table(string, u64); // Document URI -> Workspace Index
  string_table: [..] u8;
}

AST_File_Header :: struct {
  documents: Table(string, [] *Code_Node); // Document URI -> Nodes
  node\       _table: [..] u8;
  message\    _table: [..] u8;
  type_info\  _table: [..] u8;
  string\     _table: [..] u8;
  node_pointer_table: [..] *Code_Node;
}

ast_file_name :: inline (index: u64) -> string {
  return tprint("workspace_%", index);
}

initialize_ast_database_state :: () -> AST_State {
  state: AST_State;
  state.lock_file_name = tprint("%/%", DATABASE_FOLDER, LOCK_FILE_NAME);
  state.workspace_map_file_name = tprint("%/%", DATABASE_FOLDER, WORKSPACE_MAP_FILE_NAME);
  state.initialized = true;
  return state;
}

initialize_ast_database :: (using state: *AST_State, workspace_map_block_exp: u8 = 10) {
  assert_initialized(state);
  
  Map_Entry :: Workspace_Map_Header.map.Entry;
  block_size := cast(s64) 1 << workspace_map_block_exp;
  assert(workspace_map_block_exp <= 63, "Blocks cannot be larger than a 2**63 bytes, but you tried 2**%!", workspace_map_block_exp);
  assert(block_size >= size_of(Map_Entry), "Blocks must be at least the size of a workspace map entry, which is % bytes, but you tried %", size_of(Map_Entry), block_size);
  assert(block_size / size_of(Map_Entry) * size_of(Map_Entry) == block_size, "Map entry must be a power of 2, but it's %", size_of(Map_Entry));
  
  make_directory_if_it_does_not_exist(DATABASE_FOLDER);
  
  lock_file=, success := file_open(lock_file_name, true);
  assert(success, "Could not open the lockfile '%' to initialize the AST database", lock_file_name);
  defer file_close(*lock_file);
  
  if !file_exists(workspace_map_file_name) {
    workspace_map_file, success = file_open(workspace_map_file_name, true);
    assert(success, "Could not open the workspace map '%' to initialize the AST database", workspace_map_file_name);
    defer file_close(*workspace_map_file);
    
    workspace_map: *Workspace_Map_Header = alloc(block_size);
    defer free(workspace_map);
    
    allocated := block_size / size_of(Map_Entry);
    workspace_map.file_size = xx (3 * block_size); // header + workspace_map + string_table
    workspace_map.block_exp = workspace_map_block_exp;
    workspace_map.map.count = 0;
    workspace_map.map.allocated = xx allocated;
    workspace_map.map.slots_filled = 0;
    workspace_map.map.allocator = .{};
    workspace_map.map.entries.count = xx allocated;
    workspace_map.map.entries.data = xx (1 * block_size); // header
    workspace_map.string_table.count = 0;
    workspace_map.string_table.data = xx (2 * block_size); // header + workspace_map
    workspace_map.string_table.allocated = block_size;
    workspace_map.string_table.allocator = .{};
    
    block := alloc(block_size);
    memset(block, 0, block_size);
    defer free(block);
    
    file_write(*workspace_map_file, workspace_map, block_size);
    file_write(*workspace_map_file, block, block_size);
    file_write(*workspace_map_file, block, block_size);
  }
}

lock_record_file :: (using state: *AST_State, for_writing: bool) {
  assert_initialized(state);
  if locked return;
  
  lock_file=, success := file_open(lock_file_name, for_writing);
  while !success {
    sleep_milliseconds(10);
    lock_file, success = file_open(lock_file_name, for_writing);
  }
  
  locked = true;
}

read_blocks :: inline (file: File, position: *u64, data: *void, size: u64) -> success: bool {
  block_offset = get_block_offset(BLOCK_EXP, position.*);
  
  success := file_set_position(file, block_offset);
  if !success return false;
  
  success=, bytes_read := file_read(file, data, size);
  if !success || bytes_read != size return false;
  
  position.* = block_offset + size;
  return true;
}

read_table :: inline (file: File, position: *u64, table: *Table) -> success: bool {
  size := table.allocated * size_of(table.Entry);
  table.allocator = context.allocator;
  table.entries.data = alloc(size);
  return read_blocks(file, position, table.entries.data, size);
}

read_table :: inline (file: File, position: *u64, table: *[..] $T) -> success: bool {
  size := table.allocated * size_of(T);
  table.allocator = context.allocator;
  table.data = alloc(size);
  return read_blocks(file, position, table.data, size);
}

//TODO: Check that locking actually works
lock_and_open_record_file :: (using state: *AST_State, terminate: *Process, for_writing: bool) -> success: bool {
  assert_initialized(state);
  
  lock_record_file(state, for_writing);
  
  if terminate {
    kill_process(terminate);
    deinit(terminate);
  }
  
  workspace_map_file=, success := file_open(workspace_map_file_name, for_writing, true);
  if !success {
    file_close(*lock_file);
    return false;
  }
  
  success=, bytes_read := file_read(workspace_map_file, *workspace_map, size_of(Workspace_Map_Header));
  if !success || bytes_read != size_of(Workspace_Map_Header) {
    file_close(*workspace_map_file);
    file_close(*lock_file);
    return false;
  }
  
  map_block_offset := get_block_offset(workspace_map.block_exp, size_of(Workspace_Map_Header));
  success = file_set_position(workspace_map_file, xx map_block_offset);
  if !success {
    file_close(*workspace_map_file);
    file_close(*lock_file);
    return false;
  }
  workspace_map_size := workspace_map.map.allocated * size_of(Workspace_Map_Header.map.Entry);
  workspace_map.map.allocator = context.allocator;
  workspace_map.map.entries.data = alloc(workspace_map_size);
  success, bytes_read = file_read(workspace_map_file, workspace_map.map.entries.data, workspace_map_size);
  if !success || bytes_read != workspace_map_size {
    free(workspace_map.map.entries.data);
    file_close(*workspace_map_file);
    file_close(*lock_file);
    return false;
  }
  
  table_block_offset := get_block_offset(workspace_map.block_exp, map_block_offset + xx workspace_map_size);
  success = file_set_position(workspace_map_file, xx table_block_offset);
  if !success {
    free(workspace_map.map.entries.data);
    file_close(*workspace_map_file);
    file_close(*lock_file);
    return false;
  }
  string_table_size := workspace_map.string_table.allocated;
  workspace_map.string_table.allocator = context.allocator;
  workspace_map.string_table.data = alloc(string_table_size);
  success, bytes_read = file_read(workspace_map_file, workspace_map.string_table.data, string_table_size);
  if !success || bytes_read != string_table_size {
    free(workspace_map.map.entries.data);
    free(workspace_map.string_table.data);
    file_close(*workspace_map_file);
    file_close(*lock_file);
    return false;
  }
  
  return true;
}

read_ast_file :: (using state: *AST_State, workspace_index: u64) -> ast_file_state: *AST_State.AST_File_State {
  assert_initialized(state);
  
  file_name := sprint("%", workspace_index);
  file: File;
  header: Ast_File_Header;
  position: 0;
  
  verify :: (success: boolean) #expand {
    if !success {
      using `header;
      free(`file_name);
      if documents.allocator deinit(*documents);
      if node\       _table.allocator array_free(node\       _table);
      if message\    _table.allocator array_free(message\    _table);
      if type_info\  _table.allocator array_free(type_info\  _table);
      if string\     _table.allocator array_free(string\     _table);
      if node_pointer_table.allocator array_free(node_pointer_table);
      `return null;
    }
  }
  
  verify(file_exists(file_name));
  file=, success := file_open(file_state.file_name, for_writing, true);
  verify(success);
  verify(read_blocks(file, *position, *header, size_of(Ast_File_Header)));
  verify(read_table(file, *position, *header.documents));
  verify(read_table(file, *position, *header.node_table));
  verify(read_table(file, *position, *header.message_table));
  verify(read_table(file, *position, *header.type_info_table));
  verify(read_table(file, *position, *header.string_table));
  verify(read_table(file, *position, *header.node_pointer_table));
  
  visited: Table(*Code_Node, void);
  for * entry: header.documents.entries {
    entry.key.data += header.string_table.data;
    entry.value.data += header.node_pointer_table.data;
    
    for * root: entry.value {
      for * node: Ast_Visitor.{ root, *visited } {
        node.* += header.node_table.data;
      }
    }
  }
  
  file_state := array_add(*ast_file_states);
  file_state.* = .{
    workspace_index = workspace_index,
    file_name = print("%", workspace_index),
    file = file,
    header = header
  };
  
  return file_state;
}

close_and_unlock_record_file :: (using state: *AST_State) {
  assert_initialized(state);
  
  for * ast_file_states {
    //TODO: Free nodes
    free(it.file_name);
    file_close(*it.file);
    remove it;
  }
  
  file_close(*workspace_map_file);
  file_close(*lock_file);
}

get_node_from_location :: (state: *AST_State, kind: Code_Node.Kind, uri: string, line: u64, char: u64) -> *Code_Node {
  assert_initialized(state);
  
  if !lock_and_open_record_file(state, null, false) return null;
  defer close_and_unlock_record_file(state);
  
  workspace_index, success := table_find(*workspace_map.map, uri);
  if !success return null;
  
  ast_file_state := open_ast_file(state, workspace_index);
  if !ast_file_state return null;
  
  nodes, success= := table_find(*ast_file_state.data.documents, uri);
  visited: Table(*Code_Node, void);
  defer deinit(*visited);
  
  for node: nodes {
    for Ast_Visitor.{node, *visited} {
      if !is_position_within_range(line, char, it) continue;
      if it.kind == kind return it;
    }
  }
  
  return null;
}

is_location_within_node :: inline (uri: string, line: u64, char: u64, using node: *Code_Node) -> bool {
  if !node || !enclosing_load return false;
  if uri != tprint("file:///%", enclosing_load.fully_pathed_filename) return false;
  within_l0 := (line == l0 && char >= c0) || line > l0;
  within_l1 := (line == l1 && char < c1) || line < l1;
  return within_l0 && within_l1; 
}

// Continue will skip all subnodes of the current
Ast_Visitor :: struct {
  union {
    root: *Code_Node;
    root_pointer: **Code_Node;
  }
  visited: *Table(*Code_Node, void);
}
for_expansion :: (visitor: Ast_Visitor, body: Code, flags: For_Flags) #expand {
  is_reverse := flags & .REVERSE;
  is_pointer := flags & .POINTER;
  #assert(!is_reverse);
  
  // To avoid cycles, we're using a visited hashset. Callers can pass their own if they're
  // processing multiple roots to avoid iterating over the same nodes.
  _visited := Table(*Code_Node, void);
  _visited.entries = .{count = 0, data = null};
  visited := ifx visitor.visited then visitor.visited else *_visited;
  defer deinit(*_visited);
  
  // We're using an iterative depth-first traversal of the AST graph
  #if is_pointer {
    stack: [..] **Code_Node;
    array_add(*stack, visitor.root_pointer);
  } else {
    stack: [..] *Code_Node;
    array_add(*stack, visitor.root);
  }
  defer free(stack);
  index := 0;
  
  //TODO: Test continue
  //TODO: Test that visited works with pointers
  
  while stack.count {
    `it := stack[stack.count - 1];
    stack.count -= 1;
    
    // Mark the current node as visited, or skip it if we've already seen it
    curr := #ifx is_pointer then `it.* else `it;
    if !curr continue;
    if table_contains(visited, curr) continue;
    table_add(visited, curr);
    
    // The body comes first so 'continue' skips all subnodes
    #insert (remove=#assert false) body;
    
    // If is_pointer, body can change `it.* so we need to refresh curr's value
    #if is_pointer curr = `it.*;
    
    // Add subnodes to the stack
    if curr.kind == {
      case .BLOCK;
        using node: *Code_Block = xx curr;
        for < members array_add(*stack, it);
        array_add(*stack, belongs_to_struct);
        array_add(*stack, parent);
      
      case .LITERAL;
        using node: *Code_Literal = xx curr;
        if value_type == {
          case .ARRAY;
            for < array_literal_info.array_members array_add(*stack, it);
            array_add(*stack, array_literal_info.alignment);
            array_add(*stack, array_literal_info.element_type);
          
          case .STRUCT;
            for < struct_literal_info.arguments array_add(*stack, it);
            array_add(*stack, struct_literal_info.type_expression);
          
          case .POINTER;
            if pointer_literal_info.pointer_literal_type == {
              case .GLOBAL_SYMBOL;
                array_add(*stack, pointer_literal_info.global_symbol);
              
              case .STRING_OR_ARRAY_LITERAL_DATA_POINTER;
                array_add(*stack, pointer_literal_info.string_or_array_literal);
            }
        }
      
      case .IDENT;
        using node: *Code_Ident = xx curr;
        array_add(*stack, resolved_declaration);
      
      case .UNARY_OPERATOR;
        using node: *Code_Unary_Operator = xx curr;
        array_add(*stack, subexpression);
      
      case .BINARY_OPERATOR;
        using node: *Code_Binary_Operator = xx curr;
        array_add(*stack, right);
        array_add(*stack, left);
      
      case .PROCEDURE_BODY;
        using node: *Code_Procedure_Body = xx curr;
        array_add(*stack, header);
        array_add(*stack, block);
      
      case .PROCEDURE_CALL;
        using node: *Code_Procedure_Call = xx curr;
        if context_modification
          for < context_modification.modification_expressions
            array_add(*stack, it);
        array_add(*stack, macro_expansion_block);
        for < arguments_sorted array_add(*stack, it);
        for < arguments_unsorted {
          array_add(*stack, it.expression);
          array_add(*stack, it.name);
        }
        if overloads
          for < overloads.* array_add(*stack, it);
        array_add(*stack, resolved_procedure_expression);
        array_add(*stack, procedure_expression);
      
      case .CONTEXT;
        using node: *Code_Context = xx curr;
      
      case .WHILE;
        using node: *Code_While = xx curr;
        array_add(*stack, block);
        array_add(*stack, condition);
      
      case .IF;
        using node: *Code_If = xx curr;
        array_add(*stack, else_block);
        array_add(*stack, then_block);
        array_add(*stack, condition);
      
      case .LOOP_CONTROL;
        using node: *Code_Loop_Control = xx curr;
        array_add(*stack, target_ident);
      
      case .CASE;
        using node: *Code_Case = xx curr;
        array_add(*stack, owning_if);
        array_add(*stack, then_block);
        array_add(*stack, condition);
      
      case .RETURN;
        using node: *Code_Return = xx curr;
        for < arguments_sorted array_add(*stack, it);
        for < arguments_unsorted {
          array_add(*stack, it.expression);
          array_add(*stack, it.name);
        }
      
      case .FOR;
        using node: *Code_For = xx curr;
        array_add(*stack, macro_expansion_procedure_call);
        array_add(*stack, want_reverse_expression);
        array_add(*stack, want_pointer_expression);
        array_add(*stack, want_replacement_for_expansion);
        array_add(*stack, index_decl);
        array_add(*stack, ident_decl);
        array_add(*stack, ident_it_index);
        array_add(*stack, ident_it);
        array_add(*stack, block);
        array_add(*stack, iteration_expression_right);
        array_add(*stack, iteration_expression);
      
      case .TYPE_DEFINITION;
        using node: *Code_Type_Definition = xx curr;
      
      case .TYPE_INSTANTIATION;
        using node: *Code_Type_Instantiation = xx curr;
        array_add(*stack, array_dimension);
        array_add(*stack, array_element_type);
        array_add(*stack, type_directive_target);
        array_add(*stack, pointer_to);
        array_add(*stack, must_implement);
        array_add(*stack, type_valued_expression);
      
      case .ENUM;
        using node: *Code_Enum = xx curr;
        for < notes array_add(*stack, it);
        array_add(*stack, block);
        array_add(*stack, internal_type_inst);
      
      case .PROCEDURE_HEADER;
        using node: *Code_Procedure_Header = xx curr;
        for < notes array_add(*stack, it);
        array_add(*stack, body_or_null);
        for < modify_directives array_add(*stack, it);
        array_add(*stack, polymorph_source_header);
        array_add(*stack, library_identifier);
        for < parameter_usings array_add(*stack, it);
        for < returns array_add(*stack, it);
        for < arguments array_add(*stack, it);
        array_add(*stack, constants_block);
      
      case .STRUCT;
        using node: *Code_Struct = xx curr;
        for < notes array_add(*stack, it);
        array_add(*stack, constants_block);
        array_add(*stack, arguments_block);
        array_add(*stack, block);
        for < modify_directives array_add(*stack, it);
      
      case .COMMA_SEPARATED_ARGUMENTS;
        using node: *Code_Comma_Separated_Arguments = xx curr;
        for < arguments array_add(*stack, it.node);
      
      case .EXTRACT;
        using node: *Code_Extract = xx curr;
        array_add(*stack, from);
      
      case .DIRECTIVE_BYTES;
        using node: *Code_Directive_Bytes = xx curr;
        array_add(*stack, expression);
      
      case .MAKE_VARARGS;
        using node: *Code_Make_Varargs = xx curr;
        for < expressions array_add(*stack, it);
      
      case .DECLARATION;
        using node: *Code_Declaration = xx curr;
        for < notes array_add(*stack, it);
        array_add(*stack, alignment_expression);
        array_add(*stack, expression);
        array_add(*stack, type_inst);
        array_add(*stack, import_target);
      
      case .CAST;
        using node: *Code_Cast = xx curr;
        array_add(*stack, expression);
        array_add(*stack, target_type);
      
      case .DIRECTIVE_IMPORT;
        using node: *Code_Directive_Import = xx curr;
        array_add(*stack, program_parameters_call);
        array_add(*stack, module_parameters_call);
      
      case .DIRECTIVE_THIS;
      
      case .DIRECTIVE_THROUGH;
        using node: *Code_Directive_Through = xx curr;
      
      case .DIRECTIVE_LOAD;
        using node: *Code_Directive_Load = xx curr;
      
      case .DIRECTIVE_RUN;
        using node: *Code_Directive_Run = xx curr;
        array_add(*stack, procedure);
      
      case .DIRECTIVE_CODE;
        using node: *Code_Directive_Code = xx curr;
        array_add(*stack, expression);
        
        case .DIRECTIVE_POKE_NAME;
        using node: *Code_Directive_Poke_Name = xx curr;
        array_add(*stack, module_struct);
      
      case .ASM;
        using node: *Code_Asm = xx curr;
      
      case .DIRECTIVE_BAKE;
        using node: *Code_Directive_Bake = xx curr;
        array_add(*stack, procedure_call);
      
      case .DIRECTIVE_MODIFY;
        using node: *Code_Directive_Modify = xx curr;
        array_add(*stack, block);
      
      case .DIRECTIVE_LIBRARY;
        using node: *Code_Directive_Library = xx curr;
      
      case .SIZE_OR_TYPE_INFO;
        using node: *Code_Size_Or_Type_Info = xx curr;
        array_add(*stack, type_of_expression);
        array_add(*stack, type_to_query);
      
      case .PUSH_CONTEXT;
        using node: *Code_Push_Context = xx curr;
        array_add(*stack, block);
        array_add(*stack, to_push);
      
      case .NOTE;
        using node: *Code_Note = xx curr;
      
      case .DIRECTIVE_PLACE;
      
      case .DIRECTIVE_SCOPE;
        using node: *Code_Directive_Scope = xx curr;
      
      case .DIRECTIVE_LOCATION;
        using node: *Code_Directive_Location = xx curr;
        array_add(*stack, expression);
      
      case .DIRECTIVE_MODULE_PARAMETERS;
        using node: *Code_Directive_Module_Parameters = xx curr;
        array_add(*stack, common_code);
        array_add(*stack, program_parameters);
        array_add(*stack, module_parameters);
      
      case .DIRECTIVE_ADD_CONTEXT;
      
      case .DIRECTIVE_COMPILE_TIME;
      
      case .COMPOUND_DECLARATION;
        using node: *Code_Compound_Declaration = xx curr;
        for < notes array_add(*stack, it);
        array_add(*stack, alignment_expression);
        array_add(*stack, declaration_properties);
        array_add(*stack, comma_separated_assignment);
      
      case .DEFER;
        using node: *Code_Defer = xx curr;
        array_add(*stack, block);
      
      case .USING;
        using node: *Code_Using = xx curr;
        array_add(*stack, filter_expression);
        array_add(*stack, expression);
      
      case .PLACEHOLDER;
        using node: *Code_Placeholder = xx curr;
      
      case .DIRECTIVE_INSERT;
        using node: *Code_Directive_Insert = xx curr;
        array_add(*stack, remove_replacement);
        array_add(*stack, continue_replacement);
        array_add(*stack, break_replacement);
        array_add(*stack, scope_redirection);
        array_add(*stack, expression);
      
      case .DIRECTIVE_PROCEDURE_NAME;
        using node: *Code_Directive_Procedure_Name = xx curr;
        array_add(*stack, argument);
      
      case .DIRECTIVE_WILDCARD;
        using node: *Code_Directive_Wildcard = xx curr;
    }
  }
}

#scope_module

assert_initialized :: (using state: *AST_State) #expand {
  assert(initialized, "AST Database must be initialized");
}

get_block_offset :: (block_exp: u8, base_offset: u64) -> u64 {
  block_mask := (cast(u64) 1 << block_exp) - 1;
  return (base_offset + block_mask) & ~block_mask;
}

#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "Hash_Table";
#import "Process";

#import "Binary_Search";