using header: AST_File_Header;
roots: [..] *Code_Node;
nodes: Table(*Code_Node, s64);
messages: Table(*Message, s64);
strings: Table(string, s64);
documents: Table(string, [..] *Code_Node);
first_node: *Code_Node = null;

#run {
	set_build_options_dc(.{
		do_output = false, 
		write_added_strings = false
	});
	meta_options := get_build_options();
  
  assert(meta_options.compile_time_command_line.count >= 2, "Expected 'jai target file|module ..args -- import_dir server/src/modules meta Parse' but the args were %", meta_options.compile_time_command_line);
  
  file_type := meta_options.compile_time_command_line[1];
  assert(file_type == "file" || file_type == "module", "Invalid file type %; should be 'file' or 'module'", file_type);
  
  file_uri := meta_options.compile_time_command_line[0];
  found, file_domain, file_path := split_from_left(file_uri, ":///");
  if !found file_domain, file_path = "", file_uri;
	full_file_path := get_absolute_path(file_path);
  if full_file_path[1] == #char ":"
    full_file_path[0] = to_upper(full_file_path[0]);
  _, file_directory, file_name := split_from_right_by_any(full_file_path, "/\\");
  found=, file_module_name, file_extension := split_from_right(file_name, #char ".");
  if !found file_module_name, file_extension = file_name, ".jai";
	
  ast_state := initialize_ast_database_state();
  
	workspace := compiler_create_workspace("just-an-idea:parse");
	
	options := get_build_options(workspace);
	options.output_type = .NO_OUTPUT;
	options.write_added_strings = false;
	options.dead_code_elimination = .NONE;
  options.import_path[0] = sprint("%/modules", file_directory);
  if file_type == "module" {
    options.compile_time_command_line = .{
      meta_options.compile_time_command_line.count - 2,
      *meta_options.compile_time_command_line[2]
    };
  } else {
    options.compile_time_command_line = .[];
  }
	set_optimization(*options, .VERY_DEBUG);
	set_build_options(options, workspace);
  
	compiler_begin_intercept(workspace);
  
  if file_type == "module" {
    builder: String_Builder;
    init_string_builder(*builder,, temp);
    append(*builder, "#import \"");
    append(*builder, file_module_name);
    //TODO: Prevent remote code execution
    append(*builder, "\" (");
    for 2..meta_options.compile_time_command_line.count-1
      print_to_builder(*builder, "%0%", ifx it == 2 then "" else ", ", meta_options.compile_time_command_line[it]);
    append(*builder, ");");
    add_build_string(builder_to_string(*builder), workspace);
  } else {
  	add_build_file(full_file_path, workspace);
  }
	
  //TODO: Dirty flag to only work on files that were flushed
  //TODO: For files that are too large, do an on-demand parsing and skip the index
  
  serialize_root :: (root: *Code_Node) {
    uri := ifx root.enclosing_load then sprint("file:///%", root.enclosing_load.fully_pathed_filename) else "";
    document, newly_added := find_or_add(*documents, uri);
    if !newly_added free(uri);
    root_pointer := array_add(document);
    root_pointer.* = root;
    for * node_pointer: Ast_Visitor(s64).{ root_pointer = root_pointer, visited = *nodes } {
      serialize(node_pointer);
    }
  }
  
  while true {
		message := compiler_wait_for_message();
		if message.workspace != workspace continue;
    
		if message.kind == {
      case .FILE;
      case .IMPORT;
      case .FAILED_IMPORT;
			case .COMPLETE; break;
			case .DEBUG_DUMP;
      case .ERROR; //TODO: Ignore the error?
			case .PERFORMANCE_REPORT;
      
      case .PHASE;
        msg: *Message_Phase = xx message;
        if msg.phase == .TYPECHECKED_ALL_WE_CAN && msg.num_items_waiting_to_typecheck == 0
          break;
      
			case .TYPECHECKED;
				msg: *Message_Typechecked = xx message;
        for typechecked: msg.all {
          serialize_root(typechecked.expression);
          for typechecked.subexpressions serialize_root(it);
        }
    }
	}
  compiler_end_intercept(workspace);
  
  for entry: documents.entries {
    uri, array := entry.key, entry.value;
    serialize(*uri);
    array.data = xx (header.node_pointer_table.count * size_of(*Code_Node));
    table_add(*header.documents, uri, array);
    array_add(*header.node_pointer_table, ..entry.value);
  }
  
  if !lock_and_open_record_file(*ast_state, null, true) return;
  defer close_and_unlock_record_file(*ast_state);
  
  workspace_index, newly_added = find_or_add(*ast_state.workspace_map.map, workspace_uri);
  if newly_added {
    using ast_state;
    workspace_index.* = workspace_map.next_index;
    workspace_map.next_index += 1;
    offset := workspace_map.string_table.count;
    workspace_map.string_table.count += .count;
    maybe_grow(*workspace_map.string_table);
    memcpy(*workspace_map.string_table[offset], workspace_uri.data, workspace_uri.count);
    save_workspace_map(*ast_state);
  }
  
  workspace_name := sprint("%", workspace_index);
  ast_file, success := file_open(workspace_name, true, false);
  if !success return;
  defer file_close(ast_file);
  
  position := get_block_offset(size_of(AST_File_Header));
  if !write_table(ast_file, *position, *header.documents) return;
  if !write_table(ast_file, *position, *header.node_table) return;
  if !write_table(ast_file, *position, *header.message_table) return;
  if !write_table(ast_file, *position, *header.string_table) return;
  if !write_table(ast_file, *position, *header.node_pointer_table) return;
  position = 0;
  if !write_blocks(ast_file, *position, *header, size_of(AST_File_Header)) return;
}

serialize :: (data: *[..] u8, map: *Table($K, s64), key: *$T, on_first: Code) #expand {
  if !key return;
  if !key.* key.* = xx -1;
  else {
    mapped_key, newly_added := find_or_add(data, map, key.*);
    key.* = xx mapped_key;
    if newly_added {
      #insert on_first;
    }
    key.* -= cast(u64) data.data;
  }
}

serialize :: (key: **Message_File) {
  serialize(*message_table, *messages, key, #code {
    serialize(*key.*.fully_pathed_filename);
    serialize(*key.*.enclosing_import);
  });
}

serialize :: (key: **Message_Import) {
  serialize(*message_table, *messages, key, #code {
    serialize(*key.*.module_name);
    serialize(*key.*.fully_pathed_filename);
  });
}

serialize :: (key: *string) {
  if !key return;
  if !key.data {
    key.data = xx -1;
  } else {
    key.data = find_or_add(*string_table, *strings, key.*, key.data, key.count);
    key.data -= cast(u64) string_table.data;
  }
}

serialize :: inline (key: **$T/Code_Node) {
  if !key return;
  if !key.* {
    key.* = xx -1;
  } else {
    mapped_key, newly_added := find_or_add_node(key.*);
    key.* = mapped_key;
    if newly_added {
      key.*.type = null;
      serialize(*key.*.enclosing_load);
    }
    key.* -= cast(u64) node_table.data;
  }
}

find_or_add :: (data: *[..] u8, map: *Table($K, s64), key: $T, first: *K = null) -> mapped_key: K, newly_added: bool {
  mapped_key, newly_added := find_or_add(data, map, xx key, key, size_of(T), first);
  return mapped_key, newly_added;
}

find_or_add :: (data: *[..] u8, map: *Table($K, s64), key: K, key_data: $T, key_size: s64, first: *K = null) -> mapped_key: T, newly_added: bool {
  offset, newly_added_to_map := find_or_add(map, key);
  newly_added := newly_added_to_map || (first && (!first.* || (first.* != key && !offset.*)));
  if newly_added {
    if first && !first.* first.* = key;
    offset.* = data.count;
    data.count += key_size;
    if data.count >= data.allocated array_reserve(data, data.count * 2);
    memcpy(*data.*[offset.*], key_data, key_size);
  }
  return xx *data.*[offset.*], newly_added;
}

find_or_add_node :: (node: *Code_Node) -> *Code_Node, newly_added: bool {
  new_node: *Code_Node = null;
  newly_added := false;
  if !node return new_node, newly_added;
  if node.kind == {
    case .BLOCK;                       new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Block)                       node, *first_node);
    case .LITERAL;                     new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Literal)                     node, *first_node);
    case .IDENT;                       new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Ident)                       node, *first_node);
    case .UNARY_OPERATOR;              new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Unary_Operator)              node, *first_node);
    case .BINARY_OPERATOR;             new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Binary_Operator)             node, *first_node);
    case .PROCEDURE_BODY;              new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Procedure_Body)              node, *first_node);
    case .PROCEDURE_CALL;              new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Procedure_Call)              node, *first_node);
    case .CONTEXT;                     new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Context)                     node, *first_node);
    case .WHILE;                       new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_While)                       node, *first_node);
    case .IF;                          new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_If)                          node, *first_node);
    case .LOOP_CONTROL;                new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Loop_Control)                node, *first_node);
    case .CASE;                        new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Case)                        node, *first_node);
    case .RETURN;                      new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Return)                      node, *first_node);
    case .FOR;                         new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_For)                         node, *first_node);
    case .TYPE_DEFINITION;             new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Type_Definition)             node, *first_node);
    case .TYPE_INSTANTIATION;          new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Type_Instantiation)          node, *first_node);
    case .ENUM;                        new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Enum)                        node, *first_node);
    case .PROCEDURE_HEADER;            new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Procedure_Header)            node, *first_node);
    case .STRUCT;                      new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Struct)                      node, *first_node);
    case .COMMA_SEPARATED_ARGUMENTS;   new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Comma_Separated_Arguments)   node, *first_node);
    case .EXTRACT;                     new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Extract)                     node, *first_node);
    case .DIRECTIVE_BYTES;             new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Bytes)             node, *first_node);
    case .MAKE_VARARGS;                new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Make_Varargs)                node, *first_node);
    case .DECLARATION;                 new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Declaration)                 node, *first_node);
    case .CAST;                        new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Cast)                        node, *first_node);
    case .DIRECTIVE_IMPORT;            new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Import)            node, *first_node);
    case .DIRECTIVE_THIS;              new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_This)              node, *first_node);
    case .DIRECTIVE_THROUGH;           new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Through)           node, *first_node);
    case .DIRECTIVE_LOAD;              new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Load)              node, *first_node);
    case .DIRECTIVE_RUN;               new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Run)               node, *first_node);
    case .DIRECTIVE_CODE;              new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Code)              node, *first_node);
    case .DIRECTIVE_POKE_NAME;         new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Poke_Name)         node, *first_node);
    case .ASM;                         new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Asm)                         node, *first_node);
    case .DIRECTIVE_BAKE;              new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Bake)              node, *first_node);
    case .DIRECTIVE_MODIFY;            new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Modify)            node, *first_node);
    case .DIRECTIVE_LIBRARY;           new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Library)           node, *first_node);
    case .EXPRESSION_QUERY;            new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Expression_Query)            node, *first_node);
    case .PUSH_CONTEXT;                new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Push_Context)                node, *first_node);
    case .NOTE;                        new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Note)                        node, *first_node);
    case .DIRECTIVE_PLACE;             new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Place)             node, *first_node);
    case .DIRECTIVE_SCOPE;             new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Scope)             node, *first_node);
    case .TYPE_QUERY;                  new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Type_Query)                  node, *first_node);
    case .DIRECTIVE_LOCATION;          new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Location)          node, *first_node);
    case .DIRECTIVE_MODULE_PARAMETERS; new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Module_Parameters) node, *first_node);
    case .DIRECTIVE_ADD_CONTEXT;       new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Add_Context)       node, *first_node);
    case .DIRECTIVE_COMPILE_TIME;      new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Compile_Time)      node, *first_node);
    case .COMPOUND_DECLARATION;        new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Compound_Declaration)        node, *first_node);
    case .DEFER;                       new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Defer)                       node, *first_node);
    case .USING;                       new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Using)                       node, *first_node);
    case .PLACEHOLDER;                 new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Placeholder)                 node, *first_node);
    case .DIRECTIVE_INSERT;            new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Insert)            node, *first_node);
    case .DIRECTIVE_PROCEDURE_NAME;    new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Procedure_Name)    node, *first_node);
    case .DIRECTIVE_WILDCARD;          new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Wildcard)          node, *first_node);
    case .DIRECTIVE_EXISTS;            new_node, newly_added = find_or_add(*node_table, *nodes, cast(*Code_Directive_Exists)            node, *first_node);
  }
  return new_node, newly_added;
}

find_or_add_message :: (message: *Message) -> *Message, newly_added: bool {
  new_message: *Message = null;
  newly_added := false;
  if !message return new_message;
  if message.kind == {
    case .FILE;               new_message, newly_added = find_or_add(*message_table, *messages, cast(*Message_File)               message);
    case .IMPORT;             new_message, newly_added = find_or_add(*message_table, *messages, cast(*Message_Import)             message);
    case .FAILED_IMPORT;      new_message, newly_added = find_or_add(*message_table, *messages, cast(*Message_Failed_Import)      message);
    case .PHASE;              new_message, newly_added = find_or_add(*message_table, *messages, cast(*Message_Phase)              message);
    case .TYPECHECKED;        new_message, newly_added = find_or_add(*message_table, *messages, cast(*Message_Typechecked)        message);
    case .COMPLETE;           new_message, newly_added = find_or_add(*message_table, *messages, cast(*Message_Complete)           message);
    case .DEBUG_DUMP;         new_message, newly_added = find_or_add(*message_table, *messages, cast(*Message_Debug_Dump)         message);
    case .ERROR;              new_message, newly_added = find_or_add(*message_table, *messages, cast(*Message_Error)              message);
    case .PERFORMANCE_REPORT; new_message, newly_added = find_or_add(*message_table, *messages, cast(*Message_Performance_Report) message);
  }
  return new_message, newly_added;
}

validate_pair :: inline (left: *Code_Node, right: *Code_Node) -> bool {
  if !left || !left.enclosing_load || left.l0 < 1 || left.c0 < 1 return false;
  if !right || !right.enclosing_load || right.l0 < 1 || right.c0 < 1 return false;
  if left.l1 < 0 left.l1 = left.l0;
  if left.c1 < 0 left.c1 = left.c0;
  if right.l1 < 0 right.l1 = right.l0;
  if right.c1 < 0 right.c1 = right.c0;
  return true;
}

#import "AST_Database";
#import "Basic";
#import "Compiler";
#import "File";
#import "Hash_Table";
#import "String";