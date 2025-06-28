Document :: struct {
  id: int;
  ranges: [..] int;
}

Declaration :: struct {
  id: int;
  result_set_id: int;
}

Reference :: struct {
  id: int;
  result_set_id: int;
}

builder: String_Builder;
documents: Table(*Message_File, Document);
declarations: Table(*Code_Declaration, Declaration);
references: Table(*Code_Ident, Reference);
next_id := 1;

#run {
	set_build_options_dc(.{
		do_output = false,
		write_added_strings = false
	});
	meta_options := get_build_options();

  assert(meta_options.compile_time_command_line.count >= 2, "Expected 'jai target file|module ..args -- import_dir server/src/modules meta Parse' but the args were %", meta_options.compile_time_command_line);

  file_type := meta_options.compile_time_command_line[1];
  assert(file_type == "file" || file_type == "module", "Invalid file type %; should be 'file' or 'module'", file_type);

  file_uri := meta_options.compile_time_command_line[0];
  found, file_domain, file_path := split_from_left(file_uri, ":///");
  if !found file_domain, file_path = "", file_uri;
	full_file_path := get_absolute_path(file_path);
  if full_file_path[1] == #char ":"
    full_file_path[0] = to_upper(full_file_path[0]);
  _, file_directory, file_name := split_from_right_by_any(full_file_path, "/\\");
  found=, file_module_name, file_extension := split_from_right(file_name, #char ".");
  if !found file_module_name, file_extension = file_name, ".jai";

  // ast_state := initialize_ast_database_state();
  file, success := file_open("database/lsif.json", true);
  if !success return;

	workspace := compiler_create_workspace("just-an-idea:parse");

	options := get_build_options(workspace);
	options.output_type = .NO_OUTPUT;
	options.write_added_strings = false;
	options.dead_code_elimination = .NONE;
  options.import_path[0] = sprint("%/modules", file_directory);
  if file_type == "module" {
    options.compile_time_command_line = .{
      meta_options.compile_time_command_line.count - 2,
      *meta_options.compile_time_command_line[2]
    };
  } else {
    options.compile_time_command_line = .[];
  }
	set_optimization(*options, .VERY_DEBUG);
	set_build_options(options, workspace);

	compiler_begin_intercept(workspace);

  if file_type == "module" {
    builder: String_Builder;
    init_string_builder(*builder,, temp);
    append(*builder, "#import \"");
    append(*builder, file_module_name);
    //TODO: Prevent remote code execution
    append(*builder, "\" (");
    for 2..meta_options.compile_time_command_line.count-1
      print_to_builder(*builder, "%0%", ifx it == 2 then "" else ", ", meta_options.compile_time_command_line[it]);
    append(*builder, ");");
    add_build_string(builder_to_string(*builder), workspace);
  } else {
  	add_build_file(full_file_path, workspace);
  }

  //TODO: Dirty flag to only work on files that were flushed
  //TODO: For files that are too large, do an on-demand parsing and skip the index

  visited: Table(*Code_Node, void);
  visitor := Ast_Visitor.{
    root = null,
    visited = *visited
  };

  print_to_builder(*builder, "[\n");

  while true {
		message := compiler_wait_for_message();
		if message.workspace != workspace continue;

		if message.kind == {
      case .FILE;
      case .IMPORT;
      case .FAILED_IMPORT;
			case .COMPLETE; break;
			case .DEBUG_DUMP;
      case .ERROR; //TODO: Ignore the error?
			case .PERFORMANCE_REPORT;

      case .PHASE;
        msg: *Message_Phase = xx message;
        if msg.phase == .TYPECHECKED_ALL_WE_CAN && msg.num_items_waiting_to_typecheck == 0
          break;

			case .TYPECHECKED;
				msg: *Message_Typechecked = xx message;
        for typechecked: msg.all {
          emit_root(*visitor, typechecked.expression);
          for typechecked.subexpressions emit_root(*visitor, it);
        }
    }
	}
  compiler_end_intercept(workspace);

  add_contains();

  print_to_builder(*builder, "]\n");
  file_write(*file, *builder);
  file_close(*file);
}

emit_root :: (visitor: *Ast_Visitor, root: *Code_Node) {
  get_or_add_document(root);

  visitor.root = root;
  if !root.enclosing_load || !ends_with(root.enclosing_load.fully_pathed_filename, "test.jai") return;
  for visitor {
    if it.kind == {
      case .IDENT;
        add_reference(xx it);
      case .DECLARATION;
        add_declaration(xx it);
    }
  }
}

get_or_add_document :: (node: *Code_Node) -> *Document {
  if !node.enclosing_load return null;
  if (node.l0 < 1 || node.l1 < 1 || node.c0 < 1) return null;

  document, newly_added := find_or_add(*documents, node.enclosing_load);
  if newly_added {
    document.id = next_id;
    next_id += 1;
    print_to_builder(*builder, "\t{ \"id\": %, \"type\": \"vertex\", \"label\": \"document\", \"uri\": \"file:///%\", \"languageId\": \"jai\" },\n", document.id, node.enclosing_load.fully_pathed_filename);
  }
  return document;
}

add_declaration :: (decl: *Code_Declaration) -> *Declaration {
  document := get_or_add_document(decl);
  if !document return null;

  declaration, newly_added := find_or_add(*declarations, decl);
  if newly_added {
    declaration.id = next_id;
    array_add(*document.ranges, declaration.id);

    print_to_builder(*builder, "\t{ \"id\": %, \"type\": \"vertex\", \"label\": \"range\", \"start\": { \"line\": %, \"character\": % }, \"end\": { \"line\": %, \"character\": % } },\n", declaration.id, decl.l0-1, decl.c0-1, decl.l1-1, decl.c0-1 + decl.name.count);
    next_id += 1;

    declaration.result_set_id = next_id;
    print_to_builder(*builder, "\t{ \"id\": %, \"type\": \"vertex\", \"label\": \"resultSet\" },\n", declaration.result_set_id);
    next_id += 1;

    defn_result_id := next_id;
    print_to_builder(*builder, "\t{ \"id\": %, \"type\": \"vertex\", \"label\": \"definitionResult\" },\n", defn_result_id);
    next_id += 1;

    print_to_builder(*builder, "\t{ \"id\": %, \"type\": \"edge\", \"label\": \"next\", \"outV\": %, \"inV\": % },\n", next_id, declaration.id, declaration.result_set_id);
    next_id += 1;

    print_to_builder(*builder, "\t{ \"id\": %, \"type\": \"edge\", \"label\": \"textDocument/definition\", \"outV\": %, \"inV\": % },\n", next_id, declaration.result_set_id, defn_result_id);
    next_id += 1;

    print_to_builder(*builder, "\t{ \"id\": %, \"type\": \"edge\", \"label\": \"item\", \"outV\": %, \"inVs\": %, \"shard\": % },\n", next_id, defn_result_id, int.[declaration.id], document.id);
    next_id += 1;
  }
  return declaration;
}

add_reference :: (ref: *Code_Ident) -> *Reference {
  document := get_or_add_document(ref);
  if !document return null;
  declaration := add_declaration(ref.resolved_declaration);
  if (!declaration) return null;

  reference, newly_added := find_or_add(*references, ref);
  if newly_added {
    array_add(*document.ranges, reference.id);

    reference.id = next_id;
    print_to_builder(*builder, "\t{ \"id\": %, \"type\": \"vertex\", \"label\": \"range\", \"start\": { \"line\": %, \"character\": % }, \"end\": { \"line\": %, \"character\": % } },\n", reference.id, ref.l0, ref.c0, ref.l1, ref.c0 + ref.name.count);
    next_id += 1;

    reference.result_set_id = declaration.result_set_id;

    print_to_builder(*builder, "\t{ \"id\": %, \"type\": \"edge\", \"label\": \"next\", \"outV\": %, \"inV\": % },\n", next_id, reference.id, reference.result_set_id);
    next_id += 1;
  }
  return reference;
}

add_contains :: () {
  for documents {
    if !it.ranges.count continue;
    id := next_id;
    next_id += 1;
    print_to_builder(*builder, "\t{ \"id\": %, \"type\": \"edge\", \"label\": \"contains\", \"outV\": %, \"inVs\": % },\n", id, it.id, it.ranges);
  }
}

#import "Basic";
#import "Compiler";
#import "File";
#import "Hash_Table";
#import "String";
#import "Ast_Visitor";
