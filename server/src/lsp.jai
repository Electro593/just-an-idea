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

	result.serverInfo.name = copy_string(SERVER_VERSION);
	result.serverInfo.version = copy_string(SERVER_NAME);
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
	// TODO: Handle externally-modified files?
	launch_compiler(data);
}

lsp_textDocument_didChange :: (data: *Data, params: *LSP_DidChangeTextDocumentParams) {
	assert_running();
	decode_uri(*params.textDocument.uri);
}

lsp_textDocument_didSave :: (data: *Data, params: *LSP_DidSaveTextDocumentParams) {
	assert_running();
	decode_uri(*params.textDocument.uri);
	launch_compiler(data);
}

lsp_textDocument_didClose :: (data: *Data, params: *LSP_DidCloseTextDocumentParams) {
	assert_running();
}

lsp_textDocument_definition :: (data: *Data, params: *LSP_DefinitionParams) -> LSP_DefinitionResult {
	assert_running();
	decode_uri(*params.textDocument.uri);

	lsif := get_lsif(data);

	document := table_find_pointer(*lsif.documents, params.textDocument.uri);
	if !document
		return .{make_null_any()};

	// Binary search to find a fitting result set
	low := 0;
  high := document.range_ids.count;
	target := LSIF_Range.{ l0 = params.position.line, c0 = params.position.character };
  while low < high {
		cmp := 0;
    index := low + (high - low) / 2;
		t := target;

		c := table_find_pointer(*lsif.ranges, document.range_ids[index]);
		if !c then cmp = 0; // Shouldn't happen

		// T [C..] -> Move T backward
		else if t.l0 < c.l0 || t.l0 == c.l0 && t.c0 < c.c0
			cmp = -1;

		// [C..] T -> Move T forward
		else if t.l0 > c.l1 || t.l0 == c.l1 && t.c0 >= c.c1
			cmp = 1;

		// [C..T..] -> Move T backward (smaller ranges come first)
		else cmp = -1;

    if cmp < 0 high = index;
    else if cmp > 0 low = index + 1;
    else break;
  }
	range_index := low;

	// It won't be found, but the insertion index will be just below the smallest
	// fitting range, e.g., our target.
	// However, result sets don't need to have every kind of result. We'll move
	// forward until we find a result or no longer fit within the range.
	range: *LSIF_Range;
	definition: *LSIF_Definition;
	while true {
		if range_index >= document.range_ids.count
			return .{make_null_any()};

		range = table_find_pointer(*lsif.ranges, document.range_ids[range_index]);
		if range {
			if range.l0 > target.l0 || range.l1 < target.l0 || range.c0 > target.c0 || range.c1 <= target.c0
				return .{make_null_any()};

			result_set := table_find_pointer(*lsif.result_sets, range.result_set_id);
			if result_set {
				definition = table_find_pointer(*lsif.definitions, result_set.definition_id);
				if definition {
					// We finally found it!
					break;
				}
			}
		}

		range_index += 1;
	}

	links: [..] LSP_LocationLink;

	for item_ids, uri: definition.item_ids {
		for item_id: item_ids {
			item := table_find_pointer(*lsif.ranges, item_id);
			if !item continue;

			array_add(*links, .{
				originSelectionRange = .{ .{ xx range.l0, xx range.c0 }, .{ xx range.l1, xx range.c1 } },
				targetUri = copy_string(uri),
				targetRange = .{ .{ xx item.l0, xx item.c0 }, .{ xx item.l1, xx item.c1 } },
				targetSelectionRange = .{ .{ xx item.l0, xx item.c0 }, .{ xx item.l1, xx item.c1 } }
			});
		}
	}

	return .{alloc_any(links)};
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
		kernel32 :: #system_library "kernel32";
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

launch_compiler :: (data: *Data) {
	// Wait for, or kill, the compiler
  kill_process(*data.compiler);
	deinit(*data.compiler);
	// success := lock_and_open_record_file(*data.ast_state, *data.compiler, false);
	// assert(success, "Could not open the index");
	// defer close_and_unlock_record_file(*data.ast_state);

	success := create_process(*data.compiler, .. data.compiler_command, capture_and_return_output = true);
	assert(success, "Failed to launch compiler: % in extension directory", data.compiler_command);

	data.compiler_pending = true;
}

get_lsif :: (data: *Data) -> LSIF {
	if !data.compiler_pending return data.lsif;

	// TODO remove
	return data.lsif;

// 	success, result := get_process_result(*data.compiler, 0);
// 	if result.type != .STILL_RUNNING
// 		data.compiler_pending = false;
// 	if result.type != .EXITED
// 		return data.lsif;
//
// 	if result.exit_code != 0 {
// 		debug_log(data, tprint("Compiler exited with exit code %\n", result.exit_code));
// 		return data.lsif;
// 	}
//
// 	raw_lsif:, success = read_entire_file("database/lsif.json");
// 	if !success return data.lsif;
// 	defer free(raw_lsif);
//
// 	free_lsif(data, *data.lsif);
// 	data.lsif = populate_lsif(data, parse_json(raw_lsif));
// 	return data.lsif;
}

location_links_to_locations :: (links: [] LSP_LocationLink) -> [] LSP_Location {
	locations: [] LSP_Location;
	locations.count = links.count;
	locations.data = alloc(links.count * size_of(LSP_Location));

	for links {
		locations[it_index] = .{
			uri = it.targetUri,
			range = it.targetRange
		};
	}

	free(links.data);
	return locations;
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

apply_document_change :: (lines: *[..] string, text: string, start_line: s64, start_column: s64, end_line: s64, end_column: s64) {
	remove_selection :: (lines: *[..] string, sl: s64, sc: s64, el: s64, ec: s64) {
		assert(sl >= 0 && sc >= 0 && el >= 0 && ec >= 0, "Cannot have a negative range (%,%)->(%,%)", sl, sc, el, ec);
		assert(sc <= ec && sl <= el, "Cannot have an end (%,%) before the start (%,%)", el, ec, sl, sc);
		assert(lines.count > el, "Cannot remove line % of only % lines", el, lines.count);

		start_line := lines.*[sl];
		end_line := lines.*[el];
		lead := sc;
		tail := end_line.count - ec;

		// Merge the parts before and after the selection
		line: string;
		line.count = lead + tail;
		line.data = alloc(line.count);
		memcpy(line.data, start_line.data, lead);
		memcpy(line.data + lead, end_line.data + ec, tail);
		free(start_line);
		lines.*[sl] = line;

		// Remove the remaining lines
		for sl+1..el free(lines.*[it]);
		memcpy(lines.data + sl+1, lines.data + el+1, (lines.count - (el+1)) * size_of(type_of(lines.*[0])));
		lines.count -= el - sl;
	}

	insert_text :: (lines: *[..] string, text: string, sl: s64, sc: s64) {
		assert(sl >= 0 && sc >= 0, "Cannot have a negative insertion point (%,%)", sl, sc);
		start := lines.*[sl];

		// Get the number of added lines
		j := 0;
		lines_to_add := 0;
		while j < text.count {
			defer j += 1;
			if !is_any(text[j], "\r\n") continue;
			lines_to_add += 1;
			j += xx (j+1 < text.count && text[j] == #char "\r" && text[j+1] == #char "\n");
		}

		if lines_to_add {
			// Insert the new lines
			original_line_count := lines.count;
			array_resize(lines, original_line_count + lines_to_add, false);
			memcpy(lines.data + sl + 1 + lines_to_add, lines.data + sl + 1, (original_line_count - sl - 1) * size_of(type_of(lines.*[0])));
			memset(lines.data + sl + 1, 0, lines_to_add * size_of(type_of(lines.*[0])));

			// Split the insert point into two
			tail_line := string.{start.count - sc, null};
			tail_line.data = alloc(tail_line.count);
			memcpy(tail_line.data, start.data + sc, tail_line.count);
			free(lines.*[sl + lines_to_add]);
			lines.*[sl + lines_to_add] = tail_line;
			lines.*[sl].count = sc;
		}

		// Insert the new text
		j = 0;
		l := sl;
		line_start := 0;
		while j <= text.count {
			defer j += 1;
			if j < text.count && !is_any(text[j], "\r\n") continue;

			old_line := lines.*[l];
			lead := ifx l == sl then sc else 0;
			insertion := j - line_start;
			tail := old_line.count - lead;

			line := string.{lead + insertion + tail, null};
			line.data = alloc(line.count);
			memcpy(line.data, old_line.data, lead);
			memcpy(line.data + lead, text.data + line_start, insertion);
			memcpy(line.data + lead + insertion, old_line.data + lead, tail);
			free(old_line);
			lines.*[l] = line;

			j += xx (j+1 < text.count && text[j] == #char "\r" && text[j+1] == #char "\n");
			l += 1;
			line_start = j + 1;
		}
	}

	//TODO encoding
	if !lines.count array_add(lines, "");
	remove_selection(lines, start_line, start_column, end_line, end_column);
	insert_text(lines, text, start_line, start_column);
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
