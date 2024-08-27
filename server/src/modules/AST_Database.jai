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
  string\     _table: [..] u8;
  node_pointer_table: [..] *Code_Node;
}

initialize_ast_database_state :: () -> AST_State {
  make_directory_if_it_does_not_exist(DATABASE_FOLDER);
  state: AST_State;
  state.lock_file_name = sprint("%/%", DATABASE_FOLDER, LOCK_FILE_NAME);
  state.workspace_map_file_name = sprint("%/%", DATABASE_FOLDER, WORKSPACE_MAP_FILE_NAME);
  state.initialized = true;
  return state;
}

read_blocks :: inline (file: File, position: *s64, data: *void, size: s64) -> success: bool {
  block_offset := get_block_offset(BLOCK_EXP, position.*);
  
  success := file_set_position(file, block_offset);
  if !success return false;
  
  success=, bytes_read := file_read(file, data, size);
  if !success || bytes_read != size return false;
  
  position.* = block_offset + size;
  return true;
}

read_table :: inline (file: File, position: *s64, table: *Table) -> success: bool {
  size := table.allocated * size_of(table.Entry);
  table.allocator = context.allocator;
  table.entries.data = alloc(size);
  return read_blocks(file, position, table.entries.data, size);
}

read_table :: inline (file: File, position: *s64, table: *[..] $T) -> success: bool {
  size := table.allocated * size_of(T);
  table.allocator = context.allocator;
  table.data = alloc(size);
  return read_blocks(file, position, table.data, size);
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

//TODO: Check that locking actually works
lock_and_open_record_file :: (using state: *AST_State, terminate: *Process, for_writing: bool) -> success: bool {
  assert_initialized(state);
  
  lock_record_file(state, for_writing);
  
  if terminate {
    kill_process(terminate);
    deinit(terminate);
  }
  
  position := 0;
  opened, success: bool;
  
  verify :: (success: bool) #expand {
    if !success {
      using `workspace_map;
      if opened file_close(*`workspace_map_file);
      if map.allocator.proc deinit(*map);
      if string_table.allocator.proc array_free(string_table);
      file_close(*`lock_file);
      `return false;
    }
  }
  
  exists := file_exists(workspace_map_file_name);
  workspace_map_file, success = file_open(workspace_map_file_name, for_writing, true);
  verify(success);
  opened = true;
  if exists {
    verify(read_blocks(workspace_map_file, *position, *workspace_map, size_of(Workspace_Map_Header)));
    verify(read_table(workspace_map_file, *position, *workspace_map.map));
    verify(read_table(workspace_map_file, *position, *workspace_map.string_table));
  }
  
  return true;
}

read_ast_file :: (using state: *AST_State, workspace_index: u64) -> ast_file_state: *AST_State.AST_File_State {
  assert_initialized(state);
  
  file_name := sprint("%", workspace_index);
  file: File;
  header: AST_File_Header;
  success, opened: bool;
  position := 0;
  
  verify :: (success: bool) #expand {
    if !success {
      using `header;
      free(`file_name);
      if `opened file_close(*`file);
      if documents.allocator.proc deinit(*documents);
      if node\       _table.allocator.proc array_free(node\       _table);
      if message\    _table.allocator.proc array_free(message\    _table);
      if string\     _table.allocator.proc array_free(string\     _table);
      if node_pointer_table.allocator.proc array_free(node_pointer_table);
      `return null;
    }
  }
  
  verify(file_exists(file_name));
  file, success = file_open(file_name);
  verify(success);
  opened = true;
  verify(read_blocks(file, *position, *header, size_of(AST_File_Header)));
  verify(read_table(file, *position, *header.documents));
  verify(read_table(file, *position, *header.node_table));
  verify(read_table(file, *position, *header.message_table));
  verify(read_table(file, *position, *header.string_table));
  verify(read_table(file, *position, *header.node_pointer_table));
  
  visited: Table(*Code_Node, void);
  for * entry: header.documents.entries {
    entry.key.data += cast(u64) header.string_table.data;
    entry.value.data += cast(u64) header.node_pointer_table.data;
    for * root: entry.value {
      for * node: Ast_Visitor.{ root_pointer = root, visited = *visited } {
        node.* += cast(u64) header.node_table.data;
        node.*.type = null;
        node.*.enclosing_load += cast(u64) header.message_table.data;
        if (node.*.enclosing_load) {
          node.*.enclosing_load.fully_pathed_filename.data += cast(u64) header.string_table.data;
          node.*.enclosing_load.enclosing_import += cast(u64) header.message_table.data;
          if (node.*.enclosing_load.enclosing_import) {
            node.*.enclosing_load.enclosing_import.module_name.data += cast(u64) header.string_table.data;
            node.*.enclosing_load.enclosing_import.fully_pathed_filename.data += cast(u64) header.string_table.data;
          }
        }
      }
    }
  }
  
  file_state := array_add(*ast_file_states);
  file_state.* = .{
    workspace_index = workspace_index,
    file_name = file_name,
    file = file,
    header = header
  };
  
  return file_state;
}

close_and_unlock_record_file :: (using state: *AST_State) {
  assert_initialized(state);
  
  for * ast_file_states {
    deinit(*it.header.documents);
    array_free(it.header.node_table);
    array_free(it.header.message_table);
    array_free(it.header.string_table);
    array_free(it.header.node_pointer_table);
    free(it.file_name);
    file_close(*it.file);
    remove it;
  }
  array_free(ast_file_states);
  
  deinit(*workspace_map.map);
  array_free(workspace_map.string_table);
  
  file_close(*workspace_map_file);
  file_close(*lock_file);
}

get_node_from_location :: (using state: *AST_State, target: Code_Node.Kind, uri: string, line: u64, char: u64) -> *Code_Node {
  assert_initialized(state);
  
  if !lock_and_open_record_file(state, null, false) return null;
  defer close_and_unlock_record_file(state);
  
  workspace_index, success := table_find(*workspace_map.map, uri);
  if !success return null;
  
  ast_file_state := read_ast_file(state, workspace_index);
  if !ast_file_state return null;
  
  nodes, success= := table_find(*ast_file_state.header.documents, uri);
  visited: Table(*Code_Node, void);
  defer deinit(*visited);
  
  for node: nodes {
    for Ast_Visitor.{ root = node, visited = *visited } {
      if !is_location_within_node(uri, line, char, it) continue;
      if it.kind == target return it;
    }
  }
  
  return null;
}

is_location_within_node :: inline (uri: string, line: u64, char: u64, using node: *Code_Node) -> bool {
  if !node || !enclosing_load return false;
  node_uri := sprint("file:///%", enclosing_load.fully_pathed_filename);
  defer free(node_uri);
  if uri != node_uri return false;
  within_l0 := (line == xx l0 && char >= xx c0) || line > xx l0;
  within_l1 := (line == xx l1 && char < xx c1) || line < xx l1;
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
  is_reverse :: flags & .REVERSE;
  is_pointer :: flags & .POINTER;
  #assert !is_reverse;
  
  // To avoid cycles, we're using a visited hashset. Callers can pass their own if they're
  // processing multiple roots to avoid iterating over the same nodes.
  _visited: Table(*Code_Node, void);
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
  defer array_free(stack);
  
  //TODO: Test continue
  //TODO: Test that visited works with pointers
  
  `it_index := 0;
  while stack.count {
    popped := stack[stack.count - 1];
    curr := #ifx is_pointer then popped.* else popped; // Weird compiler bug doesn't like `it.*
    `it := popped;
    stack.count -= 1;
    defer `it_index += 1;
    
    #if is_pointer {
      push :: (node: **Code_Node) #expand {
        array_add(*`stack, node);
      }
    } else {
      push :: (node: **Code_Node) #expand {
        array_add(*`stack, node.*);
      }
    }
    
    // Mark the current node as visited, or skip it if we've already seen it
    _void: void;
    if !curr continue;
    if table_contains(visited, curr) continue;
    table_add(visited, curr, _void);
    
    // The body comes first so 'continue' skips all subnodes
    #insert (remove=#assert false) body;
    
    // If is_pointer, body can change `it.* so we need to refresh curr's value
    #if is_pointer curr = popped.*;
    
    // Add subnodes to the stack
    if curr.kind == {
      case .BLOCK;
        using node: *Code_Block = xx curr;
        for * < members push(xx it);
        push(xx *belongs_to_struct);
        push(xx *parent);
      
      case .LITERAL;
        using node: *Code_Literal = xx curr;
        if value_type == {
          case .ARRAY;
            for * < array_literal_info.array_members push(xx it);
            push(xx *array_literal_info.alignment);
            push(xx *array_literal_info.element_type);
          
          case .STRUCT;
            for * < struct_literal_info.arguments push(xx it);
            push(xx *struct_literal_info.type_expression);
          
          case .POINTER;
            if pointer_literal_info.pointer_literal_type == {
              case .GLOBAL_SYMBOL;
                push(xx *pointer_literal_info.global_symbol);
              
              case .STRING_OR_ARRAY_LITERAL_DATA_POINTER;
                push(xx *pointer_literal_info.string_or_array_literal);
            }
        }
      
      case .IDENT;
        using node: *Code_Ident = xx curr;
        push(xx *resolved_declaration);
      
      case .UNARY_OPERATOR;
        using node: *Code_Unary_Operator = xx curr;
        push(xx *subexpression);
      
      case .BINARY_OPERATOR;
        using node: *Code_Binary_Operator = xx curr;
        push(xx *right);
        push(xx *left);
      
      case .PROCEDURE_BODY;
        using node: *Code_Procedure_Body = xx curr;
        push(xx *header);
        push(xx *block);
      
      case .PROCEDURE_CALL;
        using node: *Code_Procedure_Call = xx curr;
        if context_modification
          for * < context_modification.modification_expressions
            push(xx it);
        push(xx *macro_expansion_block);
        for * < arguments_sorted push(xx it);
        for * < arguments_unsorted {
          push(xx *it.expression);
          push(xx *it.name);
        }
        if overloads
          for * < overloads.* push(xx it);
        push(xx *resolved_procedure_expression);
        push(xx *procedure_expression);
      
      case .CONTEXT;
        using node: *Code_Context = xx curr;
      
      case .WHILE;
        using node: *Code_While = xx curr;
        push(xx *block);
        push(xx *condition);
      
      case .IF;
        using node: *Code_If = xx curr;
        push(xx *else_block);
        push(xx *then_block);
        push(xx *condition);
      
      case .LOOP_CONTROL;
        using node: *Code_Loop_Control = xx curr;
        push(xx *target_ident);
      
      case .CASE;
        using node: *Code_Case = xx curr;
        push(xx *owning_if);
        push(xx *then_block);
        push(xx *condition);
      
      case .RETURN;
        using node: *Code_Return = xx curr;
        for * < arguments_sorted push(xx it);
        for * < arguments_unsorted {
          push(xx *it.expression);
          push(xx *it.name);
        }
      
      case .FOR;
        using node: *Code_For = xx curr;
        push(xx *macro_expansion_procedure_call);
        push(xx *want_reverse_expression);
        push(xx *want_pointer_expression);
        push(xx *want_replacement_for_expansion);
        push(xx *index_decl);
        push(xx *ident_decl);
        push(xx *ident_it_index);
        push(xx *ident_it);
        push(xx *block);
        push(xx *iteration_expression_right);
        push(xx *iteration_expression);
      
      case .TYPE_DEFINITION;
        using node: *Code_Type_Definition = xx curr;
      
      case .TYPE_INSTANTIATION;
        using node: *Code_Type_Instantiation = xx curr;
        push(xx *array_dimension);
        push(xx *array_element_type);
        push(xx *type_directive_target);
        push(xx *pointer_to);
        push(xx *must_implement);
        push(xx *type_valued_expression);
      
      case .ENUM;
        using node: *Code_Enum = xx curr;
        for * < notes push(xx it);
        push(xx *block);
        push(xx *internal_type_inst);
      
      case .PROCEDURE_HEADER;
        using node: *Code_Procedure_Header = xx curr;
        for * < notes push(xx it);
        push(xx *body_or_null);
        for * < modify_directives push(xx it);
        push(xx *polymorph_source_header);
        push(xx *library_identifier);
        for * < parameter_usings push(xx it);
        for * < returns push(xx it);
        for * < arguments push(xx it);
        push(xx *constants_block);
      
      case .STRUCT;
        using node: *Code_Struct = xx curr;
        for * < notes push(xx it);
        push(xx *constants_block);
        push(xx *arguments_block);
        push(xx *block);
        for * < modify_directives push(xx it);
      
      case .COMMA_SEPARATED_ARGUMENTS;
        using node: *Code_Comma_Separated_Arguments = xx curr;
        for * < arguments push(xx *it.node);
      
      case .EXTRACT;
        using node: *Code_Extract = xx curr;
        push(xx *from);
      
      case .DIRECTIVE_BYTES;
        using node: *Code_Directive_Bytes = xx curr;
        push(xx *expression);
      
      case .MAKE_VARARGS;
        using node: *Code_Make_Varargs = xx curr;
        for * < expressions push(xx it);
      
      case .DECLARATION;
        using node: *Code_Declaration = xx curr;
        for * < notes push(xx it);
        push(xx *alignment_expression);
        push(xx *expression);
        push(xx *type_inst);
        push(xx *import_target);
      
      case .CAST;
        using node: *Code_Cast = xx curr;
        push(xx *expression);
        push(xx *target_type);
      
      case .DIRECTIVE_IMPORT;
        using node: *Code_Directive_Import = xx curr;
        push(xx *program_parameters_call);
        push(xx *module_parameters_call);
      
      case .DIRECTIVE_THIS;
      
      case .DIRECTIVE_THROUGH;
        using node: *Code_Directive_Through = xx curr;
      
      case .DIRECTIVE_LOAD;
        using node: *Code_Directive_Load = xx curr;
      
      case .DIRECTIVE_RUN;
        using node: *Code_Directive_Run = xx curr;
        push(xx *procedure);
      
      case .DIRECTIVE_CODE;
        using node: *Code_Directive_Code = xx curr;
        push(xx *expression);
        
        case .DIRECTIVE_POKE_NAME;
        using node: *Code_Directive_Poke_Name = xx curr;
        push(xx *module_struct);
      
      case .ASM;
        using node: *Code_Asm = xx curr;
      
      case .DIRECTIVE_BAKE;
        using node: *Code_Directive_Bake = xx curr;
        push(xx *procedure_call);
      
      case .DIRECTIVE_MODIFY;
        using node: *Code_Directive_Modify = xx curr;
        push(xx *block);
      
      case .DIRECTIVE_LIBRARY;
        using node: *Code_Directive_Library = xx curr;
      
      case .EXPRESSION_QUERY;
        using node: *Code_Expression_Query = xx curr;
        push(xx *expression_to_query);
      
      case .PUSH_CONTEXT;
        using node: *Code_Push_Context = xx curr;
        push(xx *block);
        push(xx *to_push);
      
      case .NOTE;
        using node: *Code_Note = xx curr;
      
      case .DIRECTIVE_PLACE;
      
      case .DIRECTIVE_SCOPE;
        using node: *Code_Directive_Scope = xx curr;
        
      case .TYPE_QUERY;
        using node: *Code_Type_Query = xx curr;
        push(xx *type_to_query);
      
      case .DIRECTIVE_LOCATION;
        using node: *Code_Directive_Location = xx curr;
        push(xx *expression);
      
      case .DIRECTIVE_MODULE_PARAMETERS;
        using node: *Code_Directive_Module_Parameters = xx curr;
        push(xx *common_code);
        push(xx *program_parameters);
        push(xx *module_parameters);
      
      case .DIRECTIVE_ADD_CONTEXT;
      
      case .DIRECTIVE_COMPILE_TIME;
      
      case .COMPOUND_DECLARATION;
        using node: *Code_Compound_Declaration = xx curr;
        for * < notes push(xx it);
        push(xx *alignment_expression);
        push(xx *declaration_properties);
        push(xx *comma_separated_assignment);
      
      case .DEFER;
        using node: *Code_Defer = xx curr;
        push(xx *block);
      
      case .USING;
        using node: *Code_Using = xx curr;
        push(xx *filter_expression);
        push(xx *expression);
      
      case .PLACEHOLDER;
        using node: *Code_Placeholder = xx curr;
      
      case .DIRECTIVE_INSERT;
        using node: *Code_Directive_Insert = xx curr;
        push(xx *remove_replacement);
        push(xx *continue_replacement);
        push(xx *break_replacement);
        push(xx *scope_redirection);
        push(xx *expression);
      
      case .DIRECTIVE_PROCEDURE_NAME;
        using node: *Code_Directive_Procedure_Name = xx curr;
        push(xx *argument);
      
      case .DIRECTIVE_WILDCARD;
        using node: *Code_Directive_Wildcard = xx curr;
    }
  }
}

#scope_module

assert_initialized :: (using state: *AST_State) #expand {
  assert(initialized, "AST Database must be initialized");
}

get_block_offset :: (block_exp: u8, base_offset: s64) -> s64 {
  block_mask := (cast(u64) 1 << block_exp) - 1;
  return xx ((xx base_offset + block_mask) & ~block_mask);
}

#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "Hash_Table";
#import "Process";

#import "Binary_Search";