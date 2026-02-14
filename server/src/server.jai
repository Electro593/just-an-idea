LOG_FOLDER :: "log";

SERVER_NAME :: "Jai Language Server";
SERVER_FOLDER :: "server/src";
SERVER_VERSION :: "0.0.1";

OUTPUT_FOLDER :: "../../out";

#run {
	if get_name(get_current_workspace()) == "just-an-idea:parse" return;

	make_directory_if_it_does_not_exist(OUTPUT_FOLDER);
	delete_directory(tprint("../../%", LOG_FOLDER));

	set_build_options_dc(.{
		output_executable_name = "server",
		output_path = OUTPUT_FOLDER
	});
}

TextDocument :: struct {
	version: s32;
	lines: [..] string;
}

LSIF_Document :: struct {
	range_ids: [..] int;
}

LSIF_Range :: struct {
	l0, c0, l1, c1: int;
	result_set_id: int;
}

LSIF_Result_Set :: struct {
	definition_id: int;
}

LSIF_Definition :: struct {
	item_ids: Table(string, [..] int);
}

LSIF :: struct {
	ranges: Table(int, LSIF_Range);
	documents: Table(string, LSIF_Document);
	result_sets: Table(int, LSIF_Result_Set);
	definitions: Table(int, LSIF_Definition);

	objects: Table(int, *JSON_Object);
	json: *JSON_Array;
}

free_lsif :: (data: *Data, lsif: *LSIF) {
	deinit(*lsif.ranges);
	for lsif.documents array_free(it.range_ids);
		deinit(*lsif.documents);
	deinit(*lsif.result_sets);
	for def: lsif.definitions {
		for def.item_ids array_free(it);
		deinit(*def.item_ids);
	}
	deinit(*lsif.definitions);
	deinit(*lsif.objects);
	free_json(lsif.json);
}

populate_lsif :: (data: *Data, json: *JSON_Element) -> LSIF {
	lsif: LSIF;

	for as_array(json).value {
		obj := as_object(it);
		id : int = get_int(obj, "id");
		type := get_string(obj, "type");
		label := get_string(obj, "label");
		table_set(*lsif.objects, id, obj);

		if type == {
			case "vertex";
				if label == {
					case "range";
						start := as_object(get(obj, "start"));
						end := as_object(get(obj, "end"));
						table_set(*lsif.ranges, id, .{
							l0 = get_int(start, "line"),
							c0 = get_int(start, "character"),
							l1 = get_int(end, "line"),
							c1 = get_int(end, "character")
						});
					case "document";
						table_set(*lsif.documents, get_string(obj, "uri"), .{});
					case "resultSet";
						table_set(*lsif.result_sets, id, .{});
					case "definitionResult";
						table_set(*lsif.definitions, id, .{});
				}
			case "edge";
				if label == {
					case "contains";
						success, doc_obj := table_find(*lsif.objects, get_int(obj, "outV"));
						if !success continue;
						document := table_find_pointer(*lsif.documents, get_string(doc_obj, "uri"));
						if !document continue;
						for as_array(get(obj, "inVs")).value
							array_add(*document.range_ids, xx as_number(it).value);
					case "next";
						range := table_find_pointer(*lsif.ranges, get_int(obj, "outV"));
						if !range continue;
						range.result_set_id = get_int(obj, "inV");
					case "item";
						success, doc_obj := table_find(*lsif.objects, get_int(obj, "shard"));
						if !success continue;
						definition := table_find_pointer(*lsif.definitions, get_int(obj, "outV"));
						if !definition continue;
						item_ids, _ := find_or_add(*definition.item_ids, get_string(doc_obj, "uri"));
						for as_array(get(obj, "inVs")).value
							array_add(item_ids, xx as_number(it).value);
					case "textDocument/definition";
						result_set := table_find_pointer(*lsif.result_sets, get_int(obj, "outV"));
						if !result_set continue;
						result_set.definition_id = get_int(obj, "inV");
				}
		}
	}

	sorter :: (a_id: int, b_id: int, lsif: *LSIF) -> int {
		a := table_find_pointer(*lsif.ranges, a_id);
		b := table_find_pointer(*lsif.ranges, b_id);

		// Shouldn't occur, but we'll be safe
		if !a && !b || a.l0 == b.l0 && a.l1 == b.l1 && a.c0 == b.c0 && a.c1 == b.c1
			return 0;
		if !a return 1;
		if !b return -1;

		// [A..[B..]..] -> B A
		a0_before_b0 := a.l0 < b.l0 || a.l0 == b.l0 && a.c0 <= b.c0;
		b1_before_a1 := b.l1 < a.l1 || b.l1 == a.l1 && b.c1 <= a.c1;
		if a0_before_b0 && b1_before_a1 return 1;

		// [B..[A..]..] -> A B
		b0_before_a0 := b.l0 < a.l0 || b.l0 == a.l0 && b.c0 <= a.c0;
		a1_before_b1 := a.l1 < b.l1 || a.l1 == b.l1 && a.c1 <= b.c1;
		if b0_before_a0 && a1_before_b1 return -1;

		// [A..] [B..] -> A B
		if a.l1 < b.l0 || a.l1 == b.l0 && a.c1 <= b.c0 return -1;

		// [B..] [A..] -> B A
		if b.l1 < a.l0 || b.l1 == a.l0 && b.c1 <= a.c0 return 1;

		// Anything else is invalid, and there isn't a good way to sort them anyway,
		// so we'll just return zero.
		return 0;
	};

	for lsif.documents {
		quick_sort(it.range_ids, *lsif, sorter);
	}

	return lsif;
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

	// ast_state: AST_State;

	compiler_command: [] string;

	compiler_pending := false;
	lsif: LSIF;
}

main :: () {
	#if OS == .WINDOWS {
		timeBeginPeriod(1);
	}

	data: Data;

	compiler_command: [..] string;
	has_doubledash := false;
	was_meta := false;
	for get_command_line_arguments() {
		if it_index == 0 then continue;
		if it == "--" then has_doubledash = true;

		if it == "meta" {
			was_meta = true;
			continue;
		}
		if was_meta {
			was_meta = false;
			continue;
		}

		array_add(*compiler_command, it);
	}
	if !has_doubledash then array_add(*compiler_command, "--");
	array_add(*compiler_command, "import_dir", "server/src/modules", "meta", "Parse");
	data.compiler_command = compiler_command;

	make_directory_if_it_does_not_exist(LOG_FOLDER);
	loglog := file_open(tprint("%/log.log", LOG_FOLDER), true, true);
	loglog_data := read_entire_file(loglog);
	lines := split(loglog_data, "\n");
	file_seek(loglog, 0, .END);
	file_write(*loglog, tprint("(%): %.log\n", current_time_monotonic().low, lines.count - 1));
	file_close(*loglog);
	data.buffer_filename = sprint("%/%.log", LOG_FOLDER, lines.count - 1);

	// data.ast_state = initialize_ast_database_state();

	initialize_rpc(*data, read_message_from_stdin, send_message_to_stdout, debug_log);

	add_rpc_request_handler(LSP_NOTIFICATION_SET_TRACE,             lsp_setTrace);
	add_rpc_request_handler(LSP_NOTIFICATION_EXIT,                  lsp_exit);
	add_rpc_request_handler(LSP_REQUEST_INITIALIZE,                 lsp_initialize);
	add_rpc_request_handler(LSP_NOTIFICATION_INITIALIZED,           lsp_initialized);
	add_rpc_request_handler(LSP_REQUEST_SHUTDOWN,                   lsp_shutdown);
	add_rpc_request_handler(LSP_REQUEST_GO_TO_DEFINITION,           lsp_textDocument_definition);
	add_rpc_request_handler(LSP_NOTIFICATION_DOCUMENT_CHANGED,      lsp_textDocument_didChange);
	add_rpc_request_handler(LSP_NOTIFICATION_DOCUMENT_CLOSED,       lsp_textDocument_didClose);
	add_rpc_request_handler(LSP_NOTIFICATION_DOCUMENT_OPENED,       lsp_textDocument_didOpen);
	add_rpc_request_handler(LSP_NOTIFICATION_DOCUMENT_SAVED,        lsp_textDocument_didSave);
	add_rpc_request_handler(LSP_NOTIFICATION_WATCHED_FILES_CHANGED, lsp_workspace_didChangeWatchedFiles);

	//TODO: Periodic checker thread that kills the server if the client dies

	start_rpc();
}

#scope_file

#import "Basic";
#import "Compiler";
#import "File";
#import "Hash_Table";
#import "Process";
#import "String";
#import "Thread";

#if OS == .WINDOWS {
	#import "Windows";
} else {
	#import "POSIX";
}

#import "Json";
#import "Cast_Json";
#import "Json_Rpc" (SCOPE = #code main);
#import "Lsp_Types";
#import "Set";
// #import "AST_Database";

#load "io.jai";
#load "lsp.jai";
