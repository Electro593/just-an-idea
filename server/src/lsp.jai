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
  result.capabilities.declarationProvider = alloc_any(!!params.capabilities.textDocument.declaration);
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
  launch_compiler(data, params.textDocument.uri);
}

lsp_textDocument_didChange :: (data: *Data, params: *LSP_DidChangeTextDocumentParams) {
  assert_running();
  decode_uri(*params.textDocument.uri);
  // apply_document_changes(data, params.textDocument.uri, params.contentChanges);
}

lsp_textDocument_didSave :: (data: *Data, params: *LSP_DidSaveTextDocumentParams) {
  assert_running();
  decode_uri(*params.textDocument.uri);
  launch_compiler(data, params.textDocument.uri);
}

lsp_textDocument_didClose :: (data: *Data, params: *LSP_DidCloseTextDocumentParams) {
  assert_running();
}

lsp_textDocument_declaration :: (data: *Data, params: *LSP_DeclarationParams) -> LSP_DeclarationResult {
  assert_running();
  decode_uri(*params.textDocument.uri);
  
  header, success := lock_and_open_record_file(null, false);
  assert(success, "Could not open the index");
  
  declarations := read_entire_file("database/declarations");
  defer free(declarations);
  lines := split(declarations, cast(u8) #char "\n");
  links: [..] LSP_LocationLink;
  for lines {
    _, ref, decl := split_from_left(it, #char ";");
    
    _, ref_file, ref_loc := split_from_right(ref, #char ",");
    _, decl_file, decl_loc := split_from_right(decl, #char ",");
    if params.textDocument.uri != ref_file continue;
    
    _, ref_start, ref_end := split_from_left(ref_loc, #char "-");
    _, decl_start, decl_end := split_from_left(decl_loc, #char "-");
    
    _, ref_l0, ref_c0 := split_from_left(ref_start, #char ":");
    _, ref_l1, ref_c1 := split_from_left(ref_end, #char ":");
    _, decl_l0, decl_c0 := split_from_left(decl_start, #char ":");
    _, decl_l1, decl_c1 := split_from_left(decl_end, #char ":");
    
    ref_range := LSP_Range.{
      .{xx string_to_int(ref_l0), xx string_to_int(ref_c0)},
      .{xx string_to_int(ref_l1), xx string_to_int(ref_c1)}
    };
    
    decl_range := LSP_Range.{
      .{xx string_to_int(decl_l0), xx string_to_int(decl_c0)},
      .{xx string_to_int(decl_l1), xx string_to_int(decl_c1)}
    };
    
    if params.position.line < ref_range.start.line continue;
    if params.position.line > ref_range.end.line continue;
    if params.position.character < ref_range.start.character continue;
    if params.position.character >= ref_range.end.character continue;
    
    array_add(*links, .{
      originSelectionRange = ref_range,
      targetUri = copy_string(decl_file),
      targetRange = decl_range,
      targetSelectionRange = decl_range
    });
  }
  
  close_and_unlock_record_file(*header);
  return .{alloc_any(links)};
  
  // links, found := find_declaration_links(*header, params.textDocument.uri, params.position);
  // close_and_unlock_record_file(*header);
  // return .{make_null_any()};
  // if !found return .{make_null_any()};
  
  // if data.capabilities.textDocument.declaration.linkSupport
  //   return .{alloc_any(links)};
  // locations := location_links_to_locations(links);
  // return .{alloc_any(locations)};
}

lsp_textDocument_definition :: (data: *Data, params: *LSP_DefinitionParams) -> LSP_DefinitionResult {
  assert_running();
  
  header, success := lock_and_open_record_file(null, false);
  assert(success, "Could not open the index");
  
  links, found := find_definition_links(*header, params.textDocument.uri, params.position);
  close_and_unlock_record_file(*header);
  if !found return .{make_null_any()};
  
  if data.capabilities.textDocument.definition.linkSupport
    return .{alloc_any(links)};
  locations := location_links_to_locations(links);
  return .{alloc_any(locations)};
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

apply_document_changes :: (data: *Data, uri: LSP_DocumentUri, content_changes: [] LSP_TextDocumentContentChangeEvent) {
  // header, success := lock_and_open_record_file(*data.compiler, true);
  // assert(success, "Could not open the index");
  
  // //TODO: If we get an earlier version, something screwed up, so flush the database
  
  // for content_changes {
  //   if is_any_of_type(it._, _LSP_TextDocumentContentChangeEvent_Full) {
  //     success = remove_document(*header, uri);
  //     assert(success, "Could not remove % from the index", uri);
  //     break;
  //   } else {
  //     change := cast_any(it._, _LSP_TextDocumentContentChangeEvent_Range);
  //     apply_document_change(*header, change.range);
  //   }
  // }
  
  // close_and_unlock_record_file(*header);
}

launch_compiler :: (data: *Data, document: LSP_DocumentUri) {
  //TODO: Find main/module file
  //TODO: Use config if jai is not in path
  //TODO: Allow for user metaprograms and arguments for specific files
  
  // Wait for, or kill, the compiler
  header, success := lock_and_open_record_file(*data.compiler, false);
  assert(success, "Could not open the index");
  
  success = create_process(*data.compiler, "jai", document, "file", "--", "import_dir", "server/src/modules", "meta", "Parse", capture_and_return_output = true);
  close_and_unlock_record_file(*header);
  assert(success, "Failed to launch compiler: 'jai % file -- import_dir server/src/modules meta Parse' in extension directory", document);
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
    } else {
      uri.*[j] = uri.*[i];
      i += 1;
    }
    j += 1;
  }
  
  uri.count = j;
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