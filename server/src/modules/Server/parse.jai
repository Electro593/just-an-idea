Document :: struct {
	file: *Message_File;
  references: [..] *Code_Ident;
}

Parsed_Project :: struct {
	workspace: Workspace;
	documents: Table(string, Document),
}

Parser :: struct {
	options: Build_Options;
	projects: Table(string, Parsed_Project);
	blocked_files: Table(string, void);
}

parse_project :: (using parser: *Parser, filename: string) {
	workspace = compiler_create_workspace("just-an-idea:parse")
	set_build_options(options);

	compiler_begin_intercept(workspace);
	add_build_file(filename, workspace);

  visited: Table(*Code_Node, void);
  visitor := Ast_Visitor.{
    root = null,
    visited = *visited
  };

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
          emit_root(project, *visitor, typechecked.expression);
          for typechecked.subexpressions emit_root(project, *visitor, it);
        }
    }
	}

	compiler_end_intercept(workspace);
}

destroy_parsed_project :: (using project: *Parsed_Project) {
	for documents then array_free(it);
	deinit(documents);
	compiler_destroy_workspace(workspace);
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

get_reference_at :: (using project: *Parsed_Project, filename: string, line: s32, character: s32) -> *Code_Ident {
  found, document := table_find(*documents, filename);
	if !found return null;

	location := Location.{
		l0 = line,
		c0 = character,
		l1 = line,
		c1 = character
	};

	found=, reference, index := binary_search(
		*document.references,
		location,
		(target: Location, current: *Code_Ident) -> int {
			return compare_node_locations(target, current.location);
		});

	if found return reference;

	if index > 0 {
		just_before := document.references[index - 1];
		if location_contains(just_before.location, line, character)
			return just_before;
	}

	return null;
}

#scope_file

emit_root :: (project: *Parsed_Project, visitor: *Ast_Visitor, root: *Code_Node) {
  visitor.root = root;
  for visitor {
    if it.kind == {
      case .IDENT;
        add_reference(project, xx it);
    }
  }
}

add_reference :: (project: *Parsed_Project, ident: *Code_Ident) {
	filename := get_filename(node);
  if !filename || node.l0 < 1 || node.c0 < 1 || node.l1 < 1 || node.c1 < 1 return null;

  document, newly_added := find_or_add(*project.documents, filename);
  if newly_added then document.file = node.enclosing_load;

	found, _, index := binary_search(
		*document.references,
		ident,
		(target: *Code_Ident, current: *Code_Ident) -> int {
			return compare_node_locations(target.location, current.location);
		}
	);

	if !found then array_insert_at(*document.references, ident, index);
}

#import "Compiler";
#import "Hash_Table";

#import "Ast_Visitor";
#import "Set";
