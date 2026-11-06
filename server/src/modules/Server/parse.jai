Location :: Code_Node.Location;

Document :: struct {
	references: [..] *Code_Ident;
}

Project :: struct {
	filename: string;

	workspace: Workspace;

	is_running: bool;
	thread: Thread;

	parser: *Parser;
}

Parser :: struct {
	options: Build_Options;
	documents: Table(string, Document);

	project: Project;

	mutex: Mutex;
}

init_parser :: (using parser: *Parser) -> string {
	options = get_build_options();
	options.dead_code_elimination = .NONE;
	set_optimization(*options, .VERY_DEBUG);

	options.compile_time_command_line = array_copy(options.compile_time_command_line);
	filename := options.compile_time_command_line[0];
	array_ordered_remove_by_index(*options.compile_time_command_line, 0);

	init(*mutex);

	return filename;
}

deinit :: (using parser: *Parser) {
	destroy_project(*project);

	for documents array_free(it.references);
	deinit(*documents);

	destroy(*mutex);
}

parse_project :: (using parser: *Parser, filename: string) {
	destroy_project(*project);

	project.filename = copy_string(filename);
	project.parser = parser;

	project.thread.data = *project;
  project.thread.starting_context = context;
	thread_init(*project.thread, run_parser);

	project.is_running = true;
	thread_start(*project.thread);
}

wait_for_file :: (using parser: *Parser, filename: string, milliseconds: s32 = 0) -> (ready: bool) {
	if project.is_running
		return thread_is_done(*project.thread, milliseconds);

	return true;
}

get_declaration :: (parser: *Parser, filename: string, line: s32, character: s32) -> *Code_Declaration {
	reference := get_reference(parser, filename, line, character);
	return ifx reference then reference.resolved_declaration else null;
}

#scope_file

run_parser : Thread_Proc : (thread: *Thread) -> s64 {
	using,except(thread) project: *Project = xx thread.data;

	workspace = compiler_create_workspace("just-an-idea:parse");
	set_build_options(parser.options, workspace);

	compiler_begin_intercept(workspace);
	add_build_file(filename, workspace);

  visited: Table(*Code_Node, void);
  visitor := Ast_Visitor.{
    root = null,
    visited = *visited
  };

  while is_running {
		message := compiler_wait_for_message();
		if message.workspace != workspace continue;

		if message.kind == {
			case .COMPLETE;
				break;

			case .ERROR; // TODO: Report the error

			case .TYPECHECKED;
				msg: *Message_Typechecked = xx message;
        for typechecked: msg.all {
          emit_root(project, *visitor, typechecked.expression);
          for typechecked.subexpressions emit_root(project, *visitor, it);
        }
    }
	}

	compiler_end_intercept(workspace);
	deinit(*visited);

	is_running = false;
	return 0;
}

destroy_project :: (using project: *Project) {
	if thread.index {
		is_running = false;

		done := thread_is_done(*thread, -1);
		assert(done, "Failed to kill parser thread");
		thread_deinit(*thread);
	}

	if workspace then compiler_destroy_workspace(workspace);
	if filename free(filename);
}

emit_root :: (project: *Project, visitor: *Ast_Visitor, root: *Code_Node) {
  visitor.root = root;
  for visitor {
    if it.kind == {
      case .IDENT;
        add_reference(project, xx it);
    }
  }
}

add_reference :: (project: *Project, ident: *Code_Ident) {
	filename := get_filename(ident);
  if !filename || ident.l0 < 1 || ident.c0 < 1 || ident.l1 < 1 || ident.c1 < 1 return;

	lock(*project.parser.mutex);
	defer unlock(*project.parser.mutex);

	document := find_or_add(*project.parser.documents, filename);

	found, _, index := binary_search(
		document.references,
		ident,
		(target: *Code_Ident, current: *Code_Ident) -> int {
			return compare_locations(target, current);
		}
	);

	if found then document.references[index] = ident;
	else array_insert_at(*document.references, ident, index);
}

get_reference :: (parser: *Parser, filename: string, line: s32, character: s32) -> *Code_Ident {
	lock(*parser.mutex);
	defer unlock(*parser.mutex);

	found, document := table_find(*parser.documents, filename);
	if !found return null;

	location := Location.{
		l0 = line,
		c0 = character,
		l1 = line,
		c1 = character
	};

	found=, reference, index := binary_search(
		document.references,
		location,
		(target: Location, current: *Code_Ident) -> int {
			return compare_locations(target, current);
		});

	if found && location_contains(reference, line, character)
		return reference;

	if index > 0 {
		just_before := document.references[index - 1];
		if location_contains(just_before, line, character)
			return just_before;
	}

	return null;
}

// Assumes locations are from the same file, non-intersecting
compare_locations :: (a: Location, b: Location) -> int {
	if a.l0 != b.l0 return a.l0 - b.l0;
	if a.c0 != b.c0 return a.c0 - b.c0;
	return 0;
}

location_contains :: (location: Location, line: s32, character: s32) -> bool {
	if location.l0 > line return false;
	if location.l1 < line return false;
	if location.l0 == line && location.c0 > character return false;
	if location.l1 == line && location.c1 <= character return false;
	return true;
}

print_location :: (using location: Location) -> string {
	builder: String_Builder;
	init_string_builder(*builder);

	filename := ifx enclosing_load then enclosing_load.fully_pathed_filename else "";
	valid_end := l1 > l0 || (l1 == l0 && c1 > c0);

	if filename append(*builder, filename);
	if l0 > 0 {
		if filename append(*builder, "::");
		print_to_builder(*builder, "%", l0);
		if c0 > 0 print_to_builder(*builder, ":%", c0);
		if l1 > l0 || (l1 == l0 && c1 > c0) {
			print_to_builder(*builder, "-%", l1);
			if c1 > 0 print_to_builder(*builder, ":%", c1);
		}
	}

	return builder_to_string(*builder);
}

#import "Basic";
#import "Compiler";
#import "Hash_Table";
#import "Thread";

#import "Ast_Visitor";
#import "Set";
