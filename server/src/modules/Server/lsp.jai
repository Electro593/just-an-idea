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
	if params.capabilities.textDocument.synchronization
		result.capabilities.textDocumentSync = alloc_any(LSP_TextDocumentSyncOptions.{
			openClose = true,
			change = .Incremental,
			save = ifx params.capabilities.textDocument.synchronization.didSave
				then alloc_any(LSP_SaveOptions.{ includeText = false })
				else alloc_any(false)
		});
	result.capabilities.declarationProvider = alloc_any(!!params.capabilities.textDocument.declaration);

	data.capabilities = copy_casted_json(params.capabilities);

	data.is_initialized = true;
	return result;
}

lsp_initialized :: (data: *Data, params: *LSP_InitializedParams) {
	assert_running();

	thread := *data.watchdog_thread;
	thread.data = data;

	thread_init(thread, (thread: *Thread) -> s64 {
		data: *Data = xx thread.data;

		while !data.is_shutdown {
			if !is_process_running(data.client) {
				rpc_debug_log("Watchdog detected that the child process was terminated. Exiting...");
				lsp_exit(data);
			}

			sleep_microseconds(1000);
		}

		return 0;
	});

	lsp_logTrace(
		data,
		tprint("Launching watchdog thread %", thread.index)
	);
	thread_start(thread);
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
}

lsp_exit :: (data: *Data) {
	if data.is_shutdown exit(0);
	exit(1);
}

lsp_textDocument_didOpen :: (data: *Data, params: *LSP_DidOpenTextDocumentParams) {
	assert_running();
	decode_uri(*params.textDocument.uri);
}

lsp_textDocument_didChange :: (data: *Data, params: *LSP_DidChangeTextDocumentParams) {
	assert_running();
	decode_uri(*params.textDocument.uri);
}

lsp_textDocument_didSave :: (data: *Data, params: *LSP_DidSaveTextDocumentParams) {
	assert_running();
	decode_uri(*params.textDocument.uri);
}

lsp_textDocument_didClose :: (data: *Data, params: *LSP_DidCloseTextDocumentParams) {
	assert_running();
}

lsp_textDocument_declaration :: (data: *Data, params: *LSP_DeclarationParams) -> LSP_DeclarationResult {
	assert_running();
	decode_uri(*params.textDocument.uri);

	reference := get_reference_at(
		data.parser,
		params.textDocument.uri,
		params.position.line,
		params.position.character
	);

	if reference && reference.resolved_declaration
		return .{ cast_location(reference.resolved_declaration.location) };

	return .{ make_null_any() };
}

lsp_workspace_didChangeWatchedFiles :: (data: *Data, params: *LSP_DidChangeWatchedFilesParams) {
	assert_running();
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

cast_location :: (using location: Location) -> LSP_Location {
	if l0 < 1 || l1 < 1 || c0 < 1 || c1 < 1
		return .{ .{ 0, 0 }, .{ 0, 0 } };

	return .{ .{ l0 - 1, c0 - 1 }, .{ l1 - 1, c1 - 1 } };
}

decode_uri :: (uri: *string) {
	get_hex_value :: inline (char: u8) -> u8 {
		return char - cast(u8)
			ifx char <= #char "9" then #char "0"
			else ifx char <= #char "Z" then #char "A" - 10
			else #char "a" - 10;
	}

	has_prefix:, uri = contains(uri, "file:///");
	assert(has_prefix);

	i, j := 0;
	while i < uri.count {
		if uri.*[i] == #char "%" {
			value := (get_hex_value(uri.*[i+1]) << 4) | get_hex_value(uri.*[i+2]);
			uri.*[j] = value;
			i += 3;
		} else if uri.*[i] == #char "\\" {
			uri.*[j] = #char "/";
			i += 1;
		} else {
			uri.*[j] = uri.*[i];
			i += 1;
		}
		j += 1;
	}
	uri.count = j;

	// Make the drive letter uppercase for consistency
	if uri.*[1] == #char ":"
		uri.*[0] = xx to_upper(xx uri.*[0]);

	//TODO: Implement the URI spec
}

RUN_TESTS :: false;
#if RUN_TESTS {
	#run {
		test_decode_uri :: (expected: string, uri: string) {
			document_uri: LSP_DocumentUri = copy_string(uri);
			decode_uri(*document_uri);
			assert(expected == cast(string) document_uri, "Expected % from % but got %", expected, uri, document_uri);
		}

		test_apply_document_change :: (expected_lines: [] string, start_lines: [] string, text: string, start_line: s64, start_column: s64, end_line: s64, end_column: s64) {
			lines: [..] string;
			for start_lines array_add(*lines, copy_string(it));
			// print("(%,%)->(%,%):\n%\n", start_line, start_column, end_line, end_column, text);
			// print("Start: %\n", lines);
			apply_document_change(*lines, text, start_line, start_column, end_line, end_column);
			// print("End: %\n", lines);
			// print("Expected: %\n\n", expected_lines);
			assert(expected_lines.count == lines.count, "The counts weren't the same (expected %, but got %)", expected_lines.count, lines.count);
			for lines
				assert(expected_lines[it_index] == it, "The lines weren't the same (expected line % to be '%', but got '%'", it_index, expected_lines[it_index], it);
			for lines free(it);
			array_free(lines);
		}

		test_decode_uri("a:\\b\\c\\d.e", "a:\\b\\c\\d.e");
		test_decode_uri("A:\\b\\c\\d.e", "file:\\\\\\a%3A\\b\\c\\d.e");
	}
}

#import "Basic";
#import "Process";
