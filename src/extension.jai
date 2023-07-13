#import "Compiler";

#run {
	set_build_options_dc(.{
		do_output=false, 
		write_added_strings=false
	});

	workspace := compiler_create_workspace("target");
	
	options := get_build_options(workspace);
	options.output_type = .NO_OUTPUT;
	options.write_added_strings = false;
	set_optimization(*options, .VERY_DEBUG);
	set_build_options(options, workspace);

	compiler_begin_intercept(workspace)
	add_build_file(file_name, workspace);
	while true {
		message := compiler_wait_for_message();
		if message.workspace != workspace continue;

		if message.kind == {
			case .UNINITIALIZED:
				assert(false, "Uninitialized message handling not yet implemented\n");
			
			case .FILE:
				msg: Message_File = xx message;
			
			case .IMPORT:
				msg: Message_Import = xx message;
			
			case .FAILED_IMPORT:
				msg: Message_Failed_Import = xx message;

			case .PHASE:
				msg: Message_Phase = xx message;

			case .TYPECHECKED:
				msg: Message_Typechecked = xx message;

			case .COMPLETE:
				msg: Message_Complete = xx message;
				break;
			
			case .DEBUG_DUMP:
				msg: Message_Debug_Dump = xx message;
			
			case .ERROR:
				assert(false, "Error message handling not yet implemented\n");
			
			case .PERFORMANCE_REPORT:
				msg: Message_Performance_Report = xx message;

			default:
				assert(false, "Unhandled compiler message type %\n", message.kind);
		}
	}
	compiler_end_intercept(workspace);
}