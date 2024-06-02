LOG_FOLDER :: "log";
SERVER_NAME :: "Jai Language Server";
SERVER_VERSION :: "0.0.1";

#run {
  make_directory_if_it_does_not_exist("../out");
  delete_directory(tprint("../../%", LOG_FOLDER));
  
  set_build_options_dc(.{
    output_executable_name = "server",
    output_path = "../out"
  });
}

TextDocument :: struct {
  version: s32;
  lines: [..] string;
}

Data :: struct {
  client: Process;
  compiler: Process;
  capabilities: LSP_ClientCapabilities;
  
  buffer: [..] u8;
  buffer_filename: string;
  
  is_initialized: bool;
  is_shutdown: bool;
  trace: LSP_TraceValue = LSP_TraceValue_Off;
}

main :: () {
  #if OS == .WINDOWS {
    timeBeginPeriod(1);
  }
  
  data: Data;
  
  make_directory_if_it_does_not_exist(LOG_FOLDER);
  data.buffer_filename = sprint("%/%.log", LOG_FOLDER, current_time_monotonic().low);
  
  make_directory_if_it_does_not_exist(INDEX_FOLDER);
  file_close(*file_open(tprint("%/%", INDEX_FOLDER, LOCK_NAME), true));
  file_close(*file_open(tprint("%/%", INDEX_FOLDER, INDEX_NAME), true, true));
  
  initialize_rpc(*data, read_message_from_stdin, send_message_to_stdout, debug_log);
  
  add_rpc_request_handler("$/setTrace",                     lsp_setTrace);
  add_rpc_request_handler("exit",                           lsp_exit);
  add_rpc_request_handler("initialize",                     lsp_initialize);
  add_rpc_request_handler("initialized",                    lsp_initialized);
  add_rpc_request_handler("shutdown",                       lsp_shutdown);
  add_rpc_request_handler("textDocument/declaration",       lsp_textDocument_declaration);
  add_rpc_request_handler("textDocument/definition",        lsp_textDocument_definition);
  add_rpc_request_handler("textDocument/didChange",         lsp_textDocument_didChange);
  add_rpc_request_handler("textDocument/didClose",          lsp_textDocument_didClose);
  add_rpc_request_handler("textDocument/didOpen",           lsp_textDocument_didOpen);
  add_rpc_request_handler("textDocument/didSave",           lsp_textDocument_didSave);
  add_rpc_request_handler("textDocument/willSave",          lsp_textDocument_willSave);
  add_rpc_request_handler("textDocument/willSaveWaitUntil", lsp_textDocument_willSaveWaitUntil);
  
  // add_rpc_response_handler("client/registerCapability", lsp_client_registerCapability, lsp_client_registerCapability_error);
  
  //TODO: Periodic checker thread that kills the server if the client dies
  
  start_rpc();
}

#scope_file

#import "Basic";
#import "Compiler";
#import "File";
#import "String";
#import "Process";
#import "Thread";
#import "Hash_Table";
#import "Cast_Json";
#import "Json_Rpc" (SCOPE = #code main);

#if OS == .WINDOWS {
  #import "Windows";
} else {
  #import "POSIX";
}

#load "io.jai";
#load "lsp.jai";
#load "lsif.jai";