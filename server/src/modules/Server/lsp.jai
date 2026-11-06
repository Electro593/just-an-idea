lsp_initialize :: (data: *Data, params: *LSP_InitializeParams) -> LSP_InitializeResult {
	result := LSP_InitializeResult.{};
	error := LSP_InitializeError.{false};
	set_error_data(error);

	assert(!data.is_shutdown, "Cannot initialize because the server was shut down");
	assert(!data.is_initialized, "The server is already initialized.");

	data.client = .{};
	if !is_any_null(params.processId) {
		pid := cast_any(params.processId, s32).*;
		#if OS == .WINDOWS {
			data.client.info.dwProcessId = xx pid;
		} else #if OS == .LINUX || OS == .MACOS {
			data.client.pid = pid;
		}
	}

	result.serverInfo.name = copy_string(SERVER_NAME);
	result.serverInfo.version = copy_string(SERVER_VERSION);

	result.capabilities.definitionProvider = alloc_any(!!params.capabilities.textDocument.definition);

	data.capabilities = copy_casted_json(params.capabilities);

	data.is_initialized = true;
	return result;
}

lsp_initialized :: (data: *Data, params: *LSP_InitializedParams) {
	assert_running();

	thread := *data.watchdog_thread;
	thread.data = data;
  thread.starting_context = context;

	thread_init(thread, (thread: *Thread) -> s64 {
		data: *Data = xx thread.data;

		while true {
			if !is_process_running(data.client) {
				rpc_debug_log("Watchdog detected that the child process was terminated. Exiting...");
				lsp_exit(data);
			}

			sleep_milliseconds(1000);
		}

		return 0;
	});

	lsp_logTrace(
		data,
		tprint("Launching watchdog thread %", thread.index)
	);
	thread_start(thread);

	parse_project(*data.parser, data.build_filename);
}

lsp_setTrace :: (data: *Data, params: *LSP_SetTraceParams) {
	assert_running();
	data.trace = params.value;
}

lsp_logTrace :: (data: *Data, message: string, verbose_extra := "") {
	assert_running();
	rpc_debug_log("Trace is %", data.trace);
	if data.trace == LSP_TraceValue_Off return;
	params := LSP_LogTraceParams.{message = message};
	if data.trace == LSP_TraceValue_Verbose
		params.verbose = verbose_extra;
	add_request_to_batch("$/logTrace", params, true);
}

lsp_shutdown :: (data: *Data) {
	assert_running();

	data.is_shutdown = true;

	deinit(*data.parser);
}

lsp_exit :: (data: *Data) {
	if data.is_shutdown exit(0);
	exit(1);
}

lsp_textDocument_definition :: (data: *Data, params: *LSP_DefinitionParams) -> LSP_DefinitionResult {
	assert_running();

	filename := decode_uri(params.textDocument.uri);
	line: s32 = xx (params.position.line + 1);
	character: s32 = xx (params.position.character + 1);

	declaration := get_declaration(*data.parser, filename, line, character);

	if declaration && is_valid_location(declaration)
		return .{ alloc_any(get_location(declaration)) };

	return .{ make_null_any() };
}

// lsp_textDocument_didOpen :: (data: *Data, params: *LSP_DidOpenTextDocumentParams) {
// 	assert_running();

	// We're technically not supposed to use this document once it's opened. In
	// the future, we could symlink the project to a temporary directory, and
	// write the true file into it whenever it's opened. That would allow us to
	// react to changes on the fly rather than waiting for a save.
// }

lsp_workspace_didChangeWatchedFiles :: (data: *Data, params: *LSP_DidChangeWatchedFilesParams) {
	assert_running();

	parse_project(*data.parser, data.build_filename);
}

#scope_file

assert_running :: () #expand {
	{
		if !is_process_running(`data.client) then lsp_exit(`data);
		push_error(.NOT_INITIALIZED);
		assert(`data.is_initialized);
		set_error(.INVALID_REQUEST);
		assert(!`data.is_shutdown);
	}
}

is_process_running :: (process: Process) -> bool {
	#if OS == .WINDOWS {
		kernel32 :: #library,system "kernel32";
		OpenProcess :: (dwDesiredAccess: DWORD, bInheritHandle: BOOL, dwProcessId: DWORD) -> HANDLE #foreign kernel32;
		SYNCHRONIZE : DWORD : 0x00100000;

		if process.info.dwProcessId == -1 then return true;
		handle := OpenProcess(SYNCHRONIZE, xx false, xx process.info.dwProcessId);
		status := WaitForSingleObject(handle, 0);
		CloseHandle(handle);
		return status == WAIT_TIMEOUT;
	} else #if OS == .LINUX || OS == .MACOS {
		if process.pid == 0 return true;
		return kill(process.pid, 0) != -1;
	}
}

is_valid_location :: (using location: Location) -> bool {
	if !location.enclosing_load return false;
	if !location.enclosing_load.fully_pathed_filename return false;
	if l0 < 1 || c0 < 1 return false;
	if l1 < l0 || (l1 == l0 && c1 <= c0) return false;
	return true;
}

get_location :: (using location: Location) -> LSP_Location {
	uri := encode_uri(location.enclosing_load.fully_pathed_filename);
	return .{ uri, .{ .{ xx (l0 - 1), xx (c0 - 1) }, .{ xx (l1 - 1), xx (c1 - 1) } } };
}

encode_uri :: (filename: string) -> string {
	// TODO: Do this properly
	PREFIX :: #ifx OS == .WINDOWS then "file:///" else "file://";
	return sprint("%%", PREFIX, filename);
}

decode_uri :: (uri: string) -> string {
	get_hex_value :: inline (char: u8) -> u8 {
		return char - cast(u8)
			ifx char <= #char "9" then #char "0"
			else ifx char <= #char "Z" then #char "A" - 10
			else #char "a" - 10;
	}

	result := uri;

	PREFIX :: #ifx OS == .WINDOWS then "file:///" else "file://";
	has_prefix:, result = contains(result, PREFIX);
	assert(has_prefix);

	result = copy_string(result,, temp);

	i, j := 0;
	while i < result.count {
		if result[i] == #char "%" {
			value := (get_hex_value(result[i+1]) << 4) | get_hex_value(result[i+2]);
			result[j] = value;
			i += 3;
		} else if result[i] == #char "\\" {
			result[j] = #char "/";
			i += 1;
		} else {
			result[j] = result[i];
			i += 1;
		}
		j += 1;
	}
	result.count = j;

	// Make the drive letter uppercase for consistency
	#if OS == .WINDOWS {
		if result[1] == #char ":"
			result[0] = xx to_upper(xx result[0]);
	}

	//TODO: Implement the URI spec
	return result;
}

#import "Basic";
#import "Process";
