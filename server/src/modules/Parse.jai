duplication_checker: Table(*Code_Node, int);
overall_count: Table(Code_Node.Kind, int);
result_sets: Table(*Code_Node, Result_Set);

Result_Set :: struct {
  id: int;
  next: *Result_Set;
  declaration: *Code_Declaration;
  definition: *Code_Node;
}

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
	
  initialize_record_file();
  
	workspace := compiler_create_workspace("just-an-idea:parse");
	
	options := get_build_options(workspace);
	options.output_type = .NO_OUTPUT;
	options.write_added_strings = false;
	options.dead_code_elimination = .NONE;
  options.import_path[0] = sprint("%/modules", file_directory);
  if file_type == "module"
    options.compile_time_command_line = .{
      meta_options.compile_time_command_line.count - 2,
      *meta_options.compile_time_command_line[2]
    };
  else
  	options.compile_time_command_line = .[];
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
  
  while true {
		message := compiler_wait_for_message();
		if message.workspace != workspace continue;
    
		if message.kind == {
      case .ERROR;
        //TODO: Ignore the error
      
      case .FILE;
				msg: *Message_File = xx message;
      
      case .IMPORT;
				msg: *Message_Import = xx message;
      
      case .FAILED_IMPORT;
				msg: *Message_Failed_Import = xx message;
      
			case .COMPLETE;
				break;
      
      case .PHASE;
        msg: *Message_Phase = xx message;
        if msg.phase == .TYPECHECKED_ALL_WE_CAN && msg.num_items_waiting_to_typecheck == 0
          break;
      
			case .TYPECHECKED;
				msg: *Message_Typechecked = xx message;
        parse_typechecked(msg);
		}
	}
	
  compiler_end_intercept(workspace);
  
  print_tables();
  
  header, success := lock_and_open_record_file(null, true);
  assert(success);
  file_close(*header.file);
  declarations_file := file_open("database/declarations", true, false, true);
  declarations_builder: String_Builder;
  init_string_builder(*declarations_builder);
  for result_sets {
    if !it_index.enclosing_load continue;
    if it.declaration && it.declaration.enclosing_load && it.declaration.l0 > 0 {
      print_to_builder(*declarations_builder, "file:///%,%:%-%:%;file:///%,%:%-%:%\n",
        it_index.enclosing_load.fully_pathed_filename,
        it_index.l0 - 1,
        it_index.c0 - 1,
        it_index.l1 - 1,
        it_index.c1 - 1,
        it.declaration.enclosing_load.fully_pathed_filename,
        it.declaration.l0 - 1,
        it.declaration.c0 - 1,
        ifx it.declaration.l1 < 0 then it.declaration.l0 - 1 else it.declaration.l1 - 1,
        ifx it.declaration.c1 < 0 then it.declaration.c0 else it.declaration.c1 - 1);
    }
  }
  file_write(*declarations_file, builder_to_string(*declarations_builder));
  close_and_unlock_record_file(*header);
}

#scope_file

print_tables :: () {
  print_location :: (using node: *Code_Node, print_kind: bool) {
    print("[");
    
    if print_kind print("(%) ", kind);
    
    if !enclosing_load print("<init>");
    else print(enclosing_load.fully_pathed_filename);
    
    print(",%:%-%:%]", l0, c0, l1, c1);
  }
  
  // for result_sets {
  //   print_location(it_index, true);
  //   print(" --next-> [ResultSet %]\n", it.id);
  //   if it.next print("  --next-> [ResultSet %]\n", it.next.id);
  //   if it.declaration {
  //     print("  |--declaration-> ");
  //     print_location(it.declaration, false);
  //     print("\n");
  //   }
  //   if it.definition {
  //     print("  --definition-> ");
  //     print_location(it.definition, false);
  //     print("\n");
  //   }
  // }
  
  // if duplication_checker.count
  //   print("\n");
  // for duplication_checker
  //   if it > 1 print("Node % (%) occurred % times\n", it_index, it_index.kind, it);
  
  if overall_count.count
    print("\n");
  for overall_count
    print("Node kind % occurred % time%\n", it_index, it, ifx it == 1 then "" else "s");
}

add_to_counters :: (code: *Code_Node) {
  count, newly_added := find_or_add(*duplication_checker, code);
  if newly_added count.* = 0;
  count.* += 1;
  
  if newly_added {
    count, newly_added = find_or_add(*overall_count, code.kind);
    if newly_added count.* = 0;
    count.* += 1;
  }
}

parse_typechecked :: (message: Message_Typechecked) {
  parse_code_node :: (code: *Code_Node) {
    if !code return;
    
    add_to_counters(code);
    if table_find_pointer(*duplication_checker, code).* > 1 return;
    
    if code.kind == {
      case .BLOCK;
        using node: *Code_Block = xx code;
        parse_code_node(parent);
        parse_code_node(belongs_to_struct);
        for members parse_code_node(it);
      
      case .LITERAL;
        using node: *Code_Literal = xx code;
        if value_type == {
          case .ARRAY;
            parse_code_node(array_literal_info.element_type);
            parse_code_node(array_literal_info.alignment);
            for array_literal_info.array_members parse_code_node(it);
          
          case .STRUCT;
            parse_code_node(struct_literal_info.type_expression);
            for struct_literal_info.arguments parse_code_node(it);
          
          case .POINTER;
            if pointer_literal_info.pointer_literal_type == {
              case .GLOBAL_SYMBOL;
                parse_code_node(pointer_literal_info.global_symbol);
              
              case .STRING_OR_ARRAY_LITERAL_DATA_POINTER;
                parse_code_node(pointer_literal_info.string_or_array_literal);
            }
        }
      
      case .IDENT;
        using node: *Code_Ident = xx code;
        parse_code_node(resolved_declaration);
        if resolved_declaration add_declaration(node, resolved_declaration);
      
      case .UNARY_OPERATOR;
        using node: *Code_Unary_Operator = xx code;
        parse_code_node(subexpression);
      
      case .BINARY_OPERATOR;
        using node: *Code_Binary_Operator = xx code;
        parse_code_node(left);
        parse_code_node(right);
      
      case .PROCEDURE_BODY;
        using node: *Code_Procedure_Body = xx code;
        parse_code_node(block);
        parse_code_node(header);
      
      case .PROCEDURE_CALL;
        using node: *Code_Procedure_Call = xx code;
        parse_code_node(procedure_expression);
        parse_code_node(resolved_procedure_expression);
        if overloads
          for overloads.* parse_code_node(it);
        for arguments_unsorted {
          parse_code_node(it.expression);
          parse_code_node(it.name);
        }
        for arguments_sorted parse_code_node(it);
        parse_code_node(macro_expansion_block);
        if context_modification
          for context_modification.modification_expressions
            parse_code_node(it);
      
      case .CONTEXT;
        using node: *Code_Context = xx code;
      
      case .WHILE;
        using node: *Code_While = xx code;
        parse_code_node(condition);
        parse_code_node(block);
      
      case .IF;
        using node: *Code_If = xx code;
        parse_code_node(condition);
        parse_code_node(then_block);
        parse_code_node(else_block);
      
      case .LOOP_CONTROL;
        using node: *Code_Loop_Control = xx code;
        parse_code_node(target_ident);
      
      case .CASE;
        using node: *Code_Case = xx code;
        parse_code_node(condition);
        parse_code_node(then_block);
        parse_code_node(owning_if);
      
      case .RETURN;
        using node: *Code_Return = xx code;
        for arguments_unsorted {
          parse_code_node(it.expression);
          parse_code_node(it.name);
        }
        for arguments_sorted parse_code_node(it);
      
      case .FOR;
        using node: *Code_For = xx code;
        parse_code_node(iteration_expression);
        parse_code_node(iteration_expression_right);
        parse_code_node(block);
        parse_code_node(ident_it);
        parse_code_node(ident_it_index);
        parse_code_node(ident_decl);
        parse_code_node(index_decl);
        parse_code_node(want_replacement_for_expansion);
        parse_code_node(want_pointer_expression);
        parse_code_node(want_reverse_expression);
        parse_code_node(macro_expansion_procedure_call);
      
      case .TYPE_DEFINITION;
        using node: *Code_Type_Definition = xx code;
      
      case .TYPE_INSTANTIATION;
        using node: *Code_Type_Instantiation = xx code;
        parse_code_node(type_valued_expression);
        parse_code_node(must_implement);
        parse_code_node(pointer_to);
        parse_code_node(type_directive_target);
        parse_code_node(array_element_type);
        parse_code_node(array_dimension);
      
      case .ENUM;
        using node: *Code_Enum = xx code;
        parse_code_node(internal_type_inst);
        parse_code_node(block);
        for notes parse_code_node(it);
      
      case .PROCEDURE_HEADER;
        using node: *Code_Procedure_Header = xx code;
        parse_code_node(constants_block);
        for arguments parse_code_node(it);
        for returns parse_code_node(it);
        for parameter_usings parse_code_node(it);
        parse_code_node(library_identifier);
        parse_code_node(polymorph_source_header);
        for modify_directives parse_code_node(it);
        parse_code_node(body_or_null);
        for notes parse_code_node(it);
      
      case .STRUCT;
        using node: *Code_Struct = xx code;
        for modify_directives parse_code_node(it);
        parse_code_node(block);
        parse_code_node(arguments_block);
        parse_code_node(constants_block);
        for notes parse_code_node(it);
      
      case .COMMA_SEPARATED_ARGUMENTS;
        using node: *Code_Comma_Separated_Arguments = xx code;
        for arguments parse_code_node(it.node);
      
      case .EXTRACT;
        using node: *Code_Extract = xx code;
        parse_code_node(from);
      
      case .DIRECTIVE_BYTES;
        using node: *Code_Directive_Bytes = xx code;
        parse_code_node(expression);
      
      case .MAKE_VARARGS;
        using node: *Code_Make_Varargs = xx code;
        for expressions parse_code_node(it);
      
      case .DECLARATION;
        using node: *Code_Declaration = xx code;
        parse_code_node(import_target);
        parse_code_node(type_inst);
        parse_code_node(expression);
        parse_code_node(alignment_expression);
        for notes parse_code_node(it);
        // add_declaration(node, node);
        // write_declaration(node, node);
      
      case .CAST;
        using node: *Code_Cast = xx code;
        parse_code_node(target_type);
        parse_code_node(expression);
      
      case .DIRECTIVE_IMPORT;
        using node: *Code_Directive_Import = xx code;
        parse_code_node(module_parameters_call);
        parse_code_node(program_parameters_call);
      
      case .DIRECTIVE_THIS;
      
      case .DIRECTIVE_THROUGH;
        using node: *Code_Directive_Through = xx code;
      
      case .DIRECTIVE_LOAD;
        using node: *Code_Directive_Load = xx code;
      
      case .DIRECTIVE_RUN;
        using node: *Code_Directive_Run = xx code;
        parse_code_node(procedure);
      
      case .DIRECTIVE_CODE;
        using node: *Code_Directive_Code = xx code;
        parse_code_node(expression);
        
        case .DIRECTIVE_POKE_NAME;
        using node: *Code_Directive_Poke_Name = xx code;
        parse_code_node(module_struct);
      
      case .ASM;
        using node: *Code_Asm = xx code;
      
      case .DIRECTIVE_BAKE;
        using node: *Code_Directive_Bake = xx code;
        parse_code_node(procedure_call);
      
      case .DIRECTIVE_MODIFY;
        using node: *Code_Directive_Modify = xx code;
        parse_code_node(block);
      
      case .DIRECTIVE_LIBRARY;
        using node: *Code_Directive_Library = xx code;
      
      case .SIZE_OR_TYPE_INFO;
        using node: *Code_Size_Or_Type_Info = xx code;
        parse_code_node(type_to_query);
        parse_code_node(type_of_expression);
      
      case .PUSH_CONTEXT;
        using node: *Code_Push_Context = xx code;
        parse_code_node(to_push);
        parse_code_node(block);
      
      case .NOTE;
        using node: *Code_Note = xx code;
      
      case .DIRECTIVE_PLACE;
      
      case .DIRECTIVE_SCOPE;
        using node: *Code_Directive_Scope = xx code;
      
      case .DIRECTIVE_LOCATION;
        using node: *Code_Directive_Location = xx code;
        parse_code_node(expression);
      
      case .DIRECTIVE_MODULE_PARAMETERS;
        using node: *Code_Directive_Module_Parameters = xx code;
        parse_code_node(module_parameters);
        parse_code_node(program_parameters);
        parse_code_node(common_code);
      
      case .DIRECTIVE_ADD_CONTEXT;
      
      case .DIRECTIVE_COMPILE_TIME;
      
      case .COMPOUND_DECLARATION;
        using node: *Code_Compound_Declaration = xx code;
        parse_code_node(comma_separated_assignment);
        parse_code_node(declaration_properties);
        parse_code_node(alignment_expression);
        for notes parse_code_node(it);
      
      case .DEFER;
        using node: *Code_Defer = xx code;
        parse_code_node(block);
      
      case .USING;
        using node: *Code_Using = xx code;
        parse_code_node(expression);
        parse_code_node(filter_expression);
      
      case .PLACEHOLDER;
        using node: *Code_Placeholder = xx code;
      
      case .DIRECTIVE_INSERT;
        using node: *Code_Directive_Insert = xx code;
        parse_code_node(expression);
        parse_code_node(scope_redirection);
        parse_code_node(break_replacement);
        parse_code_node(continue_replacement);
        parse_code_node(remove_replacement);
      
      case .DIRECTIVE_PROCEDURE_NAME;
        using node: *Code_Directive_Procedure_Name = xx code;
        parse_code_node(argument);
      
      case .DIRECTIVE_WILDCARD;
        using node: *Code_Directive_Wildcard = xx code;
    }
  }
  
  for message.all
    parse_code_node(it.expression);
}

add_declaration :: inline (ref: *Code_Node, decl: *Code_Declaration) {
  table_set(*result_sets, ref, .{id = result_sets.count, declaration = decl});
}

// write_declaration :: (ref: *Code_Node, decl: *Code_Node) {
//   header, success := lock_and_open_record_file(null, true);
//   if !success return;
  
//   ref_document := find_or_add_document(*header, tprint("file:///%", ref.fully_pathed_filename));
//   decl_document := find_or_add_document(*header, tprint("file:///%", decl.fully_pathed_filename));
  
//   ref_range := find_or_add_range(*header, ref_document, .{.{ref.l0, ref.c0}, .{ref.l1, ref.c1}});
//   decl_range := find_or_add_range(*header, decl_document, .{.{decl.l0, decl.c0}, .{decl.l1, decl.c1}});
  
//   ref_result_set := find_or_add_result_set(*header, ref_range);
//   decl_result_set := find_or_add_result_set(*header, decl_range);
//   link_result_sets(*header, ref_result_set, decl_result_set);
  
//   declaration := find_or_add_declaration(*header, decl_result_set);
//   item := find_or_add_item(*header, decl_document, declaration);
//   item_range := find_or_add_item_range(*header, item, decl_range);
  
//   close_and_unlock_record_file(*header);
// }

#import "Basic";
#import "Compiler";
#import "File";
#import "Hash_Table";
#import "String";

#import "Record_File";