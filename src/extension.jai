#import "Basic";
#import "Compiler";
#import "Hash_Table";
#import "File";

Position :: struct {
	line: int;
	column: int;
};

Location :: struct {
	path: string;
	start: Position;
	end: Position;
};

Pathed_Position :: struct {
	path: string;
	line: int;
	column: int;
}

DEBUG :: 0;
#if DEBUG == 1 {
	DEFINITION_FORMAT :: #string __STR
	{
		"key": \"%\",
		"path": \"%\",
		"start": {
			"line": %,
			"column": %
		},
		"end": {
			"line": %,
			"column": %
		}
	}%
	__STR;
} else {
	DEFINITION_FORMAT :: "{\"key\":\"%\",\"path\":\"%\",\"start\":{\"line\":%,\"column\":%},\"end\":{\"line\":%,\"column\":%}}%";
}

// debug_print :: print;
debug_print :: (args: ..Any) {};

defcmp :: (a: string, b: string) -> bool {
	return a.count == b.count && memcmp(a.data, b.data, a.count);
}
definitions: Table(string, Location, given_compare_function=defcmp);
declarations: Table(*Code_Node, *Code_Declaration);

write_definition :: (file: *File, key: string, using definition: Location, is_last: bool) {
	output := tprint(
		DEFINITION_FORMAT,
		key,
		path,
		start.line, start.column,
		end.line, end.column,
		ifx is_last then "" else ","
	);

	file_write(file, output);
}

add_definition :: (load: *Message_File, ident_l0: int, ident_c0: int, decl: *Code_Declaration) {
	if !load || !decl
	|| !ident_l0 || !ident_c0
	|| !decl.l0 || !decl.c0
		return;

	// if(load.fully_pathed_filename[17] != #char "H") return;
	// if(decl.expression && decl.expression.kind != .ENUM) return;
	// print("%\n", <<decl);

	key := tprint("%:%:%", load.fully_pathed_filename, ident_l0, ident_c0);
	table_add(*definitions, key, .{
		path = decl.enclosing_load.fully_pathed_filename,
		start = .{
			line = decl.l0,
			column = decl.c0
		},
		end = .{
			// Sometimes, the ranges are -1 for some reason
			line = ifx decl.l1 > 0 else decl.l0,
			column = decl.c0 + decl.name.count
		}
	});
}

total := 0;

find_definitions :: (node: *Code_Node) {
	if !node return;
	total += 1;
	// print("%\n", <<node);
	
	if node.kind == {
		case .UNINITIALIZED;
    case .CONTEXT;
    case .TYPE_DEFINITION;
		case .DIRECTIVE_THIS;
		case .DIRECTIVE_THROUGH;
		case .DIRECTIVE_LOAD;
		case .ASM;
		case .DIRECTIVE_LIBRARY;
    case .NOTE;
		case .DIRECTIVE_PLACE;
    case .DIRECTIVE_SCOPE;
		case .DIRECTIVE_ADD_CONTEXT;
		case .DIRECTIVE_COMPILE_TIME;
		case .PLACEHOLDER;
		case .DIRECTIVE_WILDCARD;

    case .LITERAL;
			using n := cast(*Code_Literal) node;
			debug_print("%\n", <<n);
			if value_type == {
				case .ARRAY;
					using array_literal_info;
					find_definitions(element_type);
					find_definitions(alignment);
					for array_members find_definitions(it);

				case .STRUCT;
					using struct_literal_info;
					find_definitions(type_expression);
					for arguments find_definitions(it);

				case .POINTER;
					using pointer_literal_info;
					if pointer_literal_type == {
						case .GLOBAL_SYMBOL;
							find_definitions(global_symbol);

						case .STRING_OR_ARRAY_LITERAL_DATA_POINTER;
							find_definitions(string_or_array_literal);
					}
			}

    case .BLOCK;
			using n := cast(*Code_Block) node;
			debug_print("%\n", <<n);
			// find_definitions(parent);
			// find_definitions(belongs_to_struct);
			for members {
				find_definitions(it);
				// find_definitions(it.import_target);
			}
			for statements find_definitions(it);
			// find_definitions(owning_statement);

    case .IDENT;
			using n := cast(*Code_Ident) node;
			debug_print("%\n", <<n);
			add_definition(enclosing_load, l0, c0, resolved_declaration);
    
		case .UNARY_OPERATOR;
			using n := cast(*Code_Unary_Operator) node;
			debug_print("%\n", <<n);
			find_definitions(subexpression);

    case .BINARY_OPERATOR;
			using n := cast(*Code_Binary_Operator) node;
			debug_print("%\n", <<n);
			find_definitions(left);
			find_definitions(right);

    case .PROCEDURE_BODY;
			using n := cast(*Code_Procedure_Body) node;
			debug_print("%\n", <<n);
			find_definitions(block);
			// find_definitions(header);

    case .PROCEDURE_CALL;
			using n := cast(*Code_Procedure_Call) node;
			debug_print("%\n", <<n);
			// find_definitions(procedure_expression);
			// find_definitions(resolved_procedure_expression);
			// for overloads find_definitions(it);
			if overloads {
				add_definition(enclosing_load, l0, c0, (<<overloads)[0]);
			} else {
				decl, success := table_find(*declarations, resolved_procedure_expression);
				if success add_definition(enclosing_load, l0, c0, decl);
			}
			for arguments_unsorted {
				find_definitions(it.expression);
				find_definitions(it.name);
			}
			// for arguments_sorted find_definitions(it);
			find_definitions(macro_expansion_block);

    case .WHILE;
			using n := cast(*Code_While) node;
			debug_print("%\n", <<n);
			find_definitions(condition);
			find_definitions(block);

    case .IF;
			using n := cast(*Code_If) node;
			debug_print("%\n", <<n);
			find_definitions(condition);
			find_definitions(then_block);
			find_definitions(else_block);

    case .LOOP_CONTROL;
			using n := cast(*Code_Loop_Control) node;
			debug_print("%\n", <<n);
			find_definitions(target_ident);

    case .CASE;
			using n := cast(*Code_Case) node;
			debug_print("%\n", <<n);
			find_definitions(condition);
			find_definitions(then_block);
			// find_definitions(owning_if);

    case .RETURN;
			using n := cast(*Code_Return) node;
			debug_print("%\n", <<n);
			for arguments_unsorted {
				find_definitions(it.expression);
				find_definitions(it.name);
			}
			// for arguments_sorted find_definitions(it);

    case .FOR;
			using n := cast(*Code_For) node;
			debug_print("%\n", <<n);
			find_definitions(iteration_expression);
			find_definitions(iteration_expression_right);
			find_definitions(ident_decl);
			find_definitions(index_decl);
			// find_definitions(want_replacement_for_expansion);
			// find_definitions(want_pointer_expression);
			// find_definitions(want_reverse_expression);
			// find_definitions(macro_expansion_procedure_call);

    case .TYPE_INSTANTIATION;
			using n := cast(*Code_Type_Instantiation) node;
			debug_print("%\n", <<n);
			// find_definitions(result);
			find_definitions(type_valued_expression);
			find_definitions(must_implement);
			find_definitions(pointer_to);
			find_definitions(type_directive_target);
			find_definitions(array_element_type);
			find_definitions(array_dimension);

    case .ENUM;
			using n := cast(*Code_Enum) node;
			debug_print("%\n", <<n);
			// if block for block.statements {
			// 	decl := cast(*Code_Declaration) it;
			// 	if decl.kind == .DECLARATION && (decl.l1 < 0 || decl.c1 < 0) {
			// 		decl.l1 = decl.l0;
			// 		decl.c1 = decl.c0 - 1;
			// 		decl.c0 = decl.c1 - xx decl.name.count;
			// 	}
			// }
			find_definitions(internal_type_inst);
			find_definitions(block);
			for notes find_definitions(it);

    case .PROCEDURE_HEADER;
			using n := cast(*Code_Procedure_Header) node;
			debug_print("%\n", <<n);
			find_definitions(constants_block);
			for arguments find_definitions(it);
			for returns find_definitions(it);
			for parameter_usings find_definitions(it);
			find_definitions(polymorph_source_header);
			for modify_directives find_definitions(it);
			// find_definitions(body_or_null);
			for notes find_definitions(it);

    case .STRUCT;
			using n := cast(*Code_Struct) node;
			debug_print("%\n", <<n);
			find_definitions(block);
			find_definitions(arguments_block);
			find_definitions(constants_block);
			for notes find_definitions(it);

    case .COMMA_SEPARATED_ARGUMENTS;
			using n := cast(*Code_Comma_Separated_Arguments) node;
			debug_print("%\n", <<n);
			for arguments find_definitions(it.node);
		
    case .EXTRACT;
			using n := cast(*Code_Extract) node;
			debug_print("%\n", <<n);
			find_definitions(from);

    case .DIRECTIVE_BYTES;
			using n := cast(*Code_Directive_Bytes) node;
			debug_print("%\n", <<n);
			find_definitions(expression);

    case .MAKE_VARARGS;
			using n := cast(*Code_Make_Varargs) node;
			debug_print("%\n", <<n);
			for expressions find_definitions(it);

    case .DECLARATION;
			using n := cast(*Code_Declaration) node;
			debug_print("%\n", <<n);
			if expression && expression.kind == .PROCEDURE_HEADER {
				table_add(*declarations, expression, n);
			}
			// find_definitions(import_target);
			find_definitions(type_inst);
			find_definitions(expression);
			find_definitions(alignment_expression);
			for notes find_definitions(it);
    
		case .CAST;
			using n := cast(*Code_Cast) node;
			debug_print("%\n", <<n);
			find_definitions(target_type);
			find_definitions(expression);

    case .DIRECTIVE_IMPORT;
			using n := cast(*Code_Directive_Import) node;
			debug_print("%\n", <<n);
			find_definitions(module_parameters_call);
			find_definitions(program_parameters_call);
		
		case .DIRECTIVE_RUN;
			using n := cast(*Code_Directive_Run) node;
			debug_print("%\n", <<n);
			find_definitions(procedure);

    case .DIRECTIVE_CODE;
			using n := cast(*Code_Directive_Code) node;
			debug_print("%\n", <<n);
			find_definitions(expression);
		
    case .DIRECTIVE_POKE_NAME;
			using n := cast(*Code_Directive_Poke_Name) node;
			debug_print("%\n", <<n);
			find_definitions(module_struct);
	
		case .DIRECTIVE_BAKE;
			using n := cast(*Code_Directive_Bake) node;
			debug_print("%\n", <<n);
			find_definitions(procedure_call);

    case .DIRECTIVE_MODIFY;
			using n := cast(*Code_Directive_Modify) node;
			debug_print("%\n", <<n);
			find_definitions(block);
    
		case .SIZE_OR_TYPE_INFO;
			using n := cast(*Code_Size_Or_Type_Info) node;
			debug_print("%\n", <<n);
			find_definitions(type_to_query);
			find_definitions(type_of_expression);

    case .PUSH_CONTEXT;
			using n := cast(*Code_Push_Context) node;
			debug_print("%\n", <<n);
			find_definitions(to_push);
			find_definitions(block);

    case .DIRECTIVE_STATIC_IF;
			using n := cast(*Code_Directive_Static_If) node;
			debug_print("%\n", <<n);
			find_definitions(condition);
			find_definitions(then_block);
			find_definitions(else_block);
    
		case .DIRECTIVE_LOCATION;
			using n := cast(*Code_Directive_Location) node;
			debug_print("%\n", <<n);
			find_definitions(expression);

    case .DIRECTIVE_MODULE_PARAMETERS;
			using n := cast(*Code_Directive_Module_Parameters) node;
			debug_print("%\n", <<n);
			find_definitions(module_parameters);
			find_definitions(program_parameters);

    case .COMPOUND_DECLARATION;
			using n := cast(*Code_Compound_Declaration) node;
			debug_print("%\n", <<n);
			find_definitions(comma_separated_assignment);
			find_definitions(declaration_properties);
			find_definitions(alignment_expression);
			for notes find_definitions(it);

    case .DEFER;
			using n := cast(*Code_Defer) node;
			debug_print("%\n", <<n);
			find_definitions(block);

		case .USING;
			using n := cast(*Code_Using) node;
			debug_print("%\n", <<n);
			find_definitions(expression);
			find_definitions(filter_expression);
		
    case .DIRECTIVE_INSERT;
			using n := cast(*Code_Directive_Insert) node;
			debug_print("%\n", <<n);
			find_definitions(expression);
			find_definitions(scope_redirection);

    case .DIRECTIVE_PROCEDURE_NAME;
			using n := cast(*Code_Directive_Procedure_Name) node;
			debug_print("%\n", <<n);
			find_definitions(argument);
	}
}

#run {
	meta_options := get_build_options();
	set_build_options_dc(.{
		do_output=false, 
		write_added_strings=false
	});
	
	// Avoid infinite loop when editing this file
	if meta_options.compile_time_command_line.count < 2 return;

	workspace := compiler_create_workspace("Target");
	
	options := get_build_options(workspace);
	options.output_type = .NO_OUTPUT;
	options.write_added_strings = false;
	options.dead_code_elimination = .NONE;
	options.compile_time_command_line = .[];
	set_optimization(*options, .VERY_DEBUG);
	set_build_options(options, workspace);

	file_name := meta_options.compile_time_command_line[0];
	errored := false;

	compiler_begin_intercept(workspace);
	if meta_options.compile_time_command_line[1] == {
		case "module";
			add_build_string(tprint("#import \"%\";", file_name), workspace);
		case "file";
			add_build_file(file_name, workspace);
	}
	while true {
		message := compiler_wait_for_message();
		if message.workspace != workspace continue;

		if message.kind == {
			case .TYPECHECKED;
				msg: *Message_Typechecked = xx message;
				for msg.all {
					find_definitions(it.expression);
					// for it.subexpressions find_definitions(it);
					// print("\n");
				}

			case .ERROR;
				errored = true;

			case .COMPLETE;
				break;
		}
	}
	compiler_end_intercept(workspace);

	if !errored {
		file, success := file_open("./defs.out", for_writing=true, keep_existing_content=false);
		if success {
			defer file_close(*file);
			file_write(*file, "[");

			i := 0;
			for definitions {
				write_definition(*file, it_index, it, i == definitions.count-1);
				i += 1;
			}

			file_write(*file, "]");
		}
	}

	debug_print("Nodes processed: %\n", total);
}