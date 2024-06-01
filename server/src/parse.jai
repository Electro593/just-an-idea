#run {
	meta_options := get_build_options();
	set_build_options_dc(.{
		do_output = false, 
		write_added_strings = false
	});
	
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
	add_build_file(file_name, workspace);
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