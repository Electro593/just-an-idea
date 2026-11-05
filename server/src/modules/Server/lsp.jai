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
	result.capabilities.definitionProvider = alloc_any(!!params.capabilities.textDocument.definition);

	data.capabilities = copy_casted_json(params.capabilities);

	data.is_initialized = true;
	return result;
}

lsp_initialized :: (data: *Data, params: *LSP_InitializedParams) {
	assert_running();
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

lsp_textDocument_definition :: (data: *Data, params: *LSP_DefinitionParams) -> LSP_DefinitionResult {
	assert_running();
	return .{};
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

decode_uri :: (uri: *string) {
	get_hex_value :: inline (char: u8) -> u8 {
		return char - cast(u8)
			ifx char <= #char "9" then #char "0"
			else ifx char <= #char "Z" then #char "A" - 10
			else #char "a" - 10;
	}

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
	//TODO: Implement the URI spec
	drive_position := "file:///".count;
	if uri.*[drive_position + 1] == #char ":"
		uri.*[drive_position] = xx to_upper(xx uri.*[drive_position]);
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
		test_decode_uri("a:\\b\\c\\d.e", "a%3A\\b\\c\\d.e");

		// Add start
		test_apply_document_change(.["za1","b2","c3"], .["a1","b2","c3"], "z", 0, 0, 0, 0);
		test_apply_document_change(.["z","!a1","b2","c3"], .["a1","b2","c3"], "z\n!", 0, 0, 0, 0);

		// Add middle
		test_apply_document_change(.["a1","bz2","c3"], .["a1","b2","c3"], "z", 1, 1, 1, 1);
		test_apply_document_change(.["a1","b!","z","?2","c3"], .["a1","b2","c3"], "!\nz\n?", 1, 1, 1, 1);

		// Add end
		test_apply_document_change(.["a1","b2","c3z"], .["a1","b2","c3"], "z", 2, 2, 2, 2);
		test_apply_document_change(.["a1","b2","c3!","z"], .["a1","b2","c3"], "!\nz", 2, 2, 2, 2);
		test_apply_document_change(.["a1","b2","",""], .["a1","b2",""], "\n", 2, 0, 2, 0);

		// Remove start
		test_apply_document_change(.["b2","c3"], .["a1","b2","c3"], "", 0, 0, 1, 0);
		test_apply_document_change(.["2","c3"], .["a1","b2","c3"], "", 0, 0, 1, 1);

		// Remove middle
		test_apply_document_change(.["a3"], .["a1","b2","c3"], "", 0, 1, 2, 1);
		test_apply_document_change(.[""], .["a1","b2","c3"], "", 0, 0, 2, 2);

		// Remove end
		test_apply_document_change(.["a1","b2"], .["a1","b2","c3"], "", 1, 2, 2, 2);
		test_apply_document_change(.["a1","b"], .["a1","b2","c3"], "", 1, 1, 2, 2);

		// Replace start
		test_apply_document_change(.["z1","b2","c3"], .["a1","b2","c3"], "z", 0, 0, 0, 1);
		test_apply_document_change(.["z2","c3"], .["a1","b2","c3"], "z", 0, 0, 1, 1);

		// Replace middle
		test_apply_document_change(.["a1","z","c3"], .["a1","b2","c3"], "z", 1, 0, 1, 2);
		test_apply_document_change(.["az3"], .["a1","b2","c3"], "z", 0, 1, 2, 1);

		// Replace end
		test_apply_document_change(.["a1","b2","cz"], .["a1","b2","c3"], "z", 2, 1, 2, 2);
		test_apply_document_change(.["a1","bz"], .["a1","b2","c3"], "z", 1, 1, 2, 2);

		// Add more than remove
		test_apply_document_change(.["a","w","x","y","z","","3"], .["a1","b2","c3"], "\nw\nx\ny\nz\n\n", 0, 1, 2, 1);

		// Remove more than add
		test_apply_document_change(.["","x","y"], .["a1","b2","c3","d4","e5","f6"], "\nx\ny", 0, 0, 5, 2);
	}
}

#import "Basic";
#import "Process";
