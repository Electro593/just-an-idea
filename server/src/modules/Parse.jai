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
sepstr := "\n\t";
next_id := 1;

#run {
	set_build_options_dc(.{
		do_output = false,
		write_added_strings = false
	});
	meta_options := get_build_options();

  build_file := meta_options.compile_time_command_line[0];

  workspace := compiler_create_workspace("just-an-idea:parse");

	options := get_build_options(workspace);
	options.output_type = .NO_OUTPUT;
	options.write_added_strings = false;
	options.dead_code_elimination = .NONE;
  options.compile_time_command_line = meta_options.compile_time_command_line;
  options.import_path = meta_options.import_path;
	set_optimization(*options, .VERY_DEBUG);
	set_build_options(options, workspace);

	compiler_begin_intercept(workspace);
	add_build_file(build_file, workspace);

  //TODO: Dirty flag to only work on files that were flushed
  //TODO: For files that are too large, do an on-demand parsing and skip the index

  visited: Table(*Code_Node, void);
  visitor := Ast_Visitor.{
    root = null,
    visited = *visited
  };

  context.print_style.default_format_array.stop_printing_after_this_many_elements = -1;
  print_to_builder(*builder, "[");

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

  print_to_builder(*builder, "\n]\n");

  print(builder_to_string(*builder));
  // file_write(*file, *builder);
  // file_close(*file);
}

emit_root :: (visitor: *Ast_Visitor, root: *Code_Node) {
  visitor.root = root;
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
    print_to_builder(*builder, "%{ \"id\": %, \"type\": \"vertex\", \"label\": \"document\", \"uri\": \"file:///%\", \"languageId\": \"jai\" }", sepstr, document.id, node.enclosing_load.fully_pathed_filename);
    sepstr = ",\n\t";
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
    print_to_builder(*builder, "%{ \"id\": %, \"type\": \"vertex\", \"label\": \"range\", \"start\": { \"line\": %, \"character\": % }, \"end\": { \"line\": %, \"character\": % } }", sepstr, declaration.id, decl.l0-1, decl.c0-1, decl.l1-1, decl.c0-1 + decl.name.count);
    next_id += 1;

    declaration.result_set_id = next_id;
    print_to_builder(*builder, "%{ \"id\": %, \"type\": \"vertex\", \"label\": \"resultSet\" }", sepstr, declaration.result_set_id);
    next_id += 1;

    defn_result_id := next_id;
    print_to_builder(*builder, "%{ \"id\": %, \"type\": \"vertex\", \"label\": \"definitionResult\" }", sepstr, defn_result_id);
    next_id += 1;

    print_to_builder(*builder, "%{ \"id\": %, \"type\": \"edge\", \"label\": \"next\", \"outV\": %, \"inV\": % }", sepstr, next_id, declaration.id, declaration.result_set_id);
    next_id += 1;

    print_to_builder(*builder, "%{ \"id\": %, \"type\": \"edge\", \"label\": \"textDocument/definition\", \"outV\": %, \"inV\": % }", sepstr, next_id, declaration.result_set_id, defn_result_id);
    next_id += 1;

    print_to_builder(*builder, "%{ \"id\": %, \"type\": \"edge\", \"label\": \"item\", \"outV\": %, \"inVs\": %, \"shard\": % }", sepstr, next_id, defn_result_id, int.[declaration.id], document.id);
    next_id += 1;
  }
  return declaration;
}

add_reference :: (ref: *Code_Ident) -> *Reference {
  document := get_or_add_document(ref);
  if !document || !ref.resolved_declaration return null;
  declaration := add_declaration(ref.resolved_declaration);
  if (!declaration) return null;

  reference, newly_added := find_or_add(*references, ref);
  if newly_added {
    reference.id = next_id;
    array_add(*document.ranges, reference.id);
    print_to_builder(*builder, "%{ \"id\": %, \"type\": \"vertex\", \"label\": \"range\", \"start\": { \"line\": %, \"character\": % }, \"end\": { \"line\": %, \"character\": % } }", sepstr, reference.id, ref.l0-1, ref.c0-1, ref.l1-1, ref.c0-1 + ref.name.count);
    next_id += 1;

    reference.result_set_id = declaration.result_set_id;

    print_to_builder(*builder, "%{ \"id\": %, \"type\": \"edge\", \"label\": \"next\", \"outV\": %, \"inV\": % }", sepstr, next_id, reference.id, reference.result_set_id);
    next_id += 1;
  }
  return reference;
}

add_contains :: () {
  for documents {
    if !it.ranges.count continue;
    id := next_id;
    next_id += 1;
    print_to_builder(*builder, "%{ \"id\": %, \"type\": \"edge\", \"label\": \"contains\", \"outV\": %, \"inVs\": % }", sepstr, id, it.id, it.ranges);
  }
}

#import "Basic";
#import "Compiler";
#import "File";
#import "Hash_Table";
#import "String";
#import "Ast_Visitor";
