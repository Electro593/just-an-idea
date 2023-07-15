#import "Compiler";

#run {
	meta_options := get_build_options();
	set_build_options_dc(.{
		do_output=false, 
		write_added_strings=false
	});
  
	workspace := compiler_create_workspace("Meta");
	
	options := get_build_options(workspace);
	options.output_type = .NO_OUTPUT;
	options.write_added_strings = false;
  options.interactive_bytecode_debugger = true;
	set_optimization(*options, .VERY_DEBUG);
	set_build_options(options, workspace);

  add_build_file(meta_options.compile_time_command_line[0], workspace);
}