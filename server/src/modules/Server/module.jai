#scope_module

SERVER_NAME :: "Jai Language Server";
SERVER_VERSION :: "0.0.1";

Data :: struct {
	client: Process;
	capabilities: LSP_ClientCapabilities;

	buffer: [..] u8;
	buffer_filename: string;

	projects: Table(string, Parsed_Project);

	is_initialized: bool;
	is_shutdown: bool;
	trace: LSP_TraceValue = LSP_TraceValue_Off;

	watchdog_thread: Thread;
}

#import "Cast_Json";
#import "Json_Rpc" (SCOPE = #code Data);
#import "Lsp_Types";

#scope_file

LOG_FOLDER :: "log";

#run {
	set_build_options_dc(.{
		do_output = false,
		write_added_strings = false
	});

	data: Data;

	make_directory_if_it_does_not_exist(LOG_FOLDER);
	loglog := file_open(tprint("%/log.log", LOG_FOLDER), true, true);
	loglog_data := read_entire_file(loglog);
	lines := split(loglog_data, "\n");
	file_seek(loglog, 0, .END);
	file_write(*loglog, tprint("(%): %.log\n", current_time_monotonic().low, lines.count - 1));
	file_close(*loglog);
	data.buffer_filename = sprint("%/%.log", LOG_FOLDER, lines.count - 1);

	initialize_rpc(*data, read_message_from_stdin, send_message_to_stdout, debug_log);

	add_rpc_request_handler(LSP_NOTIFICATION_SET_TRACE,             lsp_setTrace);
	add_rpc_request_handler(LSP_NOTIFICATION_EXIT,                  lsp_exit);
	add_rpc_request_handler(LSP_REQUEST_INITIALIZE,                 lsp_initialize);
	add_rpc_request_handler(LSP_NOTIFICATION_INITIALIZED,           lsp_initialized);
	add_rpc_request_handler(LSP_REQUEST_SHUTDOWN,                   lsp_shutdown);
	add_rpc_request_handler(LSP_REQUEST_GO_TO_DECLARATION,          lsp_textDocument_declaration);
	add_rpc_request_handler(LSP_NOTIFICATION_DOCUMENT_CHANGED,      lsp_textDocument_didChange);
	add_rpc_request_handler(LSP_NOTIFICATION_DOCUMENT_CLOSED,       lsp_textDocument_didClose);
	add_rpc_request_handler(LSP_NOTIFICATION_DOCUMENT_OPENED,       lsp_textDocument_didOpen);
	add_rpc_request_handler(LSP_NOTIFICATION_DOCUMENT_SAVED,        lsp_textDocument_didSave);
	add_rpc_request_handler(LSP_NOTIFICATION_WATCHED_FILES_CHANGED, lsp_workspace_didChangeWatchedFiles);

	start_rpc();
}

#import "Basic";
#import "Compiler";
#import "File";
#import "String";

#load "io.jai";
#load "lsp.jai";
#load "parse.jai";
