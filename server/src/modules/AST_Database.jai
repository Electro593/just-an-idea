#module_parameters (DATABASE_FOLDER := "database") ();

//
// Maintains an AST database that can be queried efficiently.
//

LOCK_FILE_NAME :: "lock";
WORKSPACE_MAP_FILE_NAME :: "workspaces_map";
AST_BLOCK_EXP :: 12;

AST_State :: struct {
  initialized: bool;

  lock_file: File;
  lock_file_name: string;
  locked: bool;

  workspace_map_file: File;
  workspace_map_file_name: string;
  workspace_map: Workspace_Map_Header;

  ast_file_states: [..] AST_File_State;

  AST_File_State :: struct {
    workspace_index: u64;
    file: File;
    file_name: string;
    header: AST_File_Header;
  }
}

Workspace_Map_Header :: struct {
  next_index: u64;
  map: Table(string, u64); // Document URI -> Workspace Index
  string_table: [..] u8;
}

AST_File_Header :: struct {
  documents: Table(string, [] *Code_Node); // Document URI -> Nodes
  node\       _table: [..] u8;
  message\    _table: [..] u8;
  string\     _table: [..] u8;
  node_pointer_table: [..] *Code_Node;
}

initialize_ast_database_state :: () -> AST_State {
  make_directory_if_it_does_not_exist(DATABASE_FOLDER);
  state: AST_State;
  state.lock_file_name = sprint("%/%", DATABASE_FOLDER, LOCK_FILE_NAME);
  state.workspace_map_file_name = sprint("%/%", DATABASE_FOLDER, WORKSPACE_MAP_FILE_NAME);
  state.initialized = true;
  return state;
}

read_blocks :: (file: File, position: *s64, data: *void, size: s64) -> success: bool {
  block_offset := get_block_offset(position.*);
  if !file_set_position(file, block_offset) return false;
  success, bytes_read := file_read(file, data, size);
  if !success || bytes_read != size return false;
  position.* = block_offset + size;
  return true;
}

read_table :: inline (file: File, position: *s64, table: *Table) -> success: bool {
  size := table.allocated * size_of(table.Entry);
  table.allocator = context.allocator;
  table.entries.data = alloc(size);
  return read_blocks(file, position, table.entries.data, size);
}

read_table :: inline (file: File, position: *s64, table: *[..] $T) -> success: bool {
  size := table.allocated * size_of(T);
  table.allocator = context.allocator;
  table.data = alloc(size);
  return read_blocks(file, position, table.data, size);
}

write_blocks :: (file: File, position: *s64, data: *void, size: s64) -> success: bool {
  block_offset := get_block_offset(position.*);
  if !file_set_position(file, block_offset) return false;
  if !file_write(file, data, size) return false;
  position.* = block_offset + size;
  return true;
}

write_table :: inline (file: File, position: *s64, table: *Table) -> success: bool {
  start_position := position.*;
  success := write_blocks(file, position, table.entries.data, table.allocated * size_of(table.Entry));
  table.allocator = .{ null, null };
  table.entries.data = start_position;
  return success;
}

write_table :: inline (file: File, position: *s64, table: *[..] $T) -> success: bool {
  start_position := position.*;
  success := write_blocks(file, position, table.data, table.allocated * size_of(T));
  table.allocator = .{ null, null };
  table.data = start_position;
  return success;
}

lock_record_file :: (using state: *AST_State, for_writing: bool) {
  assert_initialized(state);
  if locked return;

  lock_file=, success := file_open(lock_file_name, for_writing);
  while !success {
    sleep_milliseconds(10);
    lock_file, success = file_open(lock_file_name, for_writing);
  }

  locked = true;
}

//TODO: Check that locking actually works
lock_and_open_record_file :: (using state: *AST_State, terminate: *Process, for_writing: bool) -> success: bool {
  assert_initialized(state);

  lock_record_file(state, for_writing);

  if terminate {
    kill_process(terminate);
    deinit(terminate);
  }

  if !read_workspace_map(state, for_writing) {
    file_close(*lock_file);
    return false;
  }

  return true;
}

read_workspace_map :: (using state: *AST_State, for_writing: bool) -> success: bool {
  exists := file_exists(workspace_map_file_name);
  workspace_map_file=, success := file_open(workspace_map_file_name, for_writing, true);
  if !success return false;

  if exists {
    verify :: (success: bool) #expand {
      if !success {
        using `workspace_map;
        if map.allocator.proc deinit(*map);
        if string_table.allocator.proc array_free(string_table);
        file_close(*`workspace_map_file);
        `return false;
      }
    }

    position := 0;
    verify(read_blocks(workspace_map_file, *position, *workspace_map, size_of(Workspace_Map_Header)));
    verify(read_table(workspace_map_file, *position, *workspace_map.map));
    verify(read_table(workspace_map_file, *position, *workspace_map.string_table));

    for * entry: workspace_map.map.entries {
      entry.key.data += cast(u64) workspace_map.string_table.data;
    }
  }

  return true;
}

save_workspace_map :: (using state: *AST_State) -> success: bool {
  assert_locked(state);

  for * workspace_map.string_table {
    it.data -= cast(u64) workspace_map.string_table.data;
  }

  position := get_block_offset(size_of(Workspace_Map_Header));
  if !write_table(workspace_map_file, *position, *workspace_map.string_table) return false;
  if !write_table(workspace_map_file, *position, *workspace_map.map) return false;
  position = 0;
  if !write_blocks(workspace_map_file, *position, *workspace_map) return false;

  return read_workspace_map(state, true);
}

read_ast_file :: (using state: *AST_State, workspace_index: u64) -> ast_file_state: *AST_State.AST_File_State {
  assert_initialized(state);

  file_name := sprint("%", workspace_index);
  file: File;
  using header: AST_File_Header;
  messages: Table(*Message, void);
  nodes: Table(*Code_Node, void);
  success, opened: bool;
  position := 0;

  verify :: (success: bool) #expand {
    if !success {
      using `header;
      free(`file_name);
      if `opened file_close(*`file);
      if documents.allocator.proc deinit(*documents);
      if node\       _table.allocator.proc array_free(node\       _table);
      if message\    _table.allocator.proc array_free(message\    _table);
      if string\     _table.allocator.proc array_free(string\     _table);
      if node_pointer_table.allocator.proc array_free(node_pointer_table);
      `return null;
    }
  }

  deserialize :: (data: *[..] u8, visited: *Table($T, void), key: *T, on_first: Code) #expand {
    _void: void;
    if !key return;
    if key.* == xx -1 key.* = null;
    else {
      key.* += cast(u64) data.data;
      if !table_contains(visited, key.*) {
        table_add(visited, key.*, _void);
        #insert on_first;
      }
    }
  }

  deserialize :: (key: **Message_File) #expand {
    deserialize(*`message_table, *`messages, xx key, #code {
      deserialize(*key.*.fully_pathed_filename);
      deserialize(*key.*.enclosing_import);
    });
  }

  deserialize :: (key: **Message_Import) #expand {
    deserialize(*`message_table, *`messages, xx key, #code {
      deserialize(*key.*.module_name);
      deserialize(*key.*.fully_pathed_filename);
    });
  }

  deserialize :: (key: **Code_Node, not_yet_visited: bool) #expand {
    deserialize(*`node_table, *`nodes, key, #code {
      if not_yet_visited {
        deserialize(*key.*.enclosing_load);
      }
    });
  }

  deserialize :: (key: *string) #expand {
    if !key return;
    if key.data == xx -1 key.data = null;
    else key.data += cast(u64) `string_table.data;
  }

  verify(file_exists(file_name));
  file, success = file_open(file_name);
  verify(success);
  opened = true;
  verify(read_blocks(file, *position, *header, size_of(AST_File_Header)));
  verify(read_table(file, *position, *documents));
  verify(read_table(file, *position, *node_table));
  verify(read_table(file, *position, *message_table));
  verify(read_table(file, *position, *string_table));
  verify(read_table(file, *position, *node_pointer_table));

  for * entry: documents.entries {
    if entry.hash < FIRST_VALID_HASH continue;
    deserialize(*entry.key);
    entry.value.data += cast(u64) node_pointer_table.data;
    for * root: entry.value {
      for * node, not_yet_visited: Ast_Visitor.{ root_pointer = root, visited = *nodes } {
        deserialize(node, not_yet_visited);
      }
    }
  }

  deinit(*messages);
  deinit(*nodes);

  file_state := array_add(*ast_file_states);
  file_state.* = .{
    workspace_index = workspace_index,
    file_name = file_name,
    file = file,
    header = header
  };

  return file_state;
}

close_and_unlock_record_file :: (using state: *AST_State) {
  assert_initialized(state);

  for * ast_file_states {
    deinit(*it.header.documents);
    array_free(it.header.node_table);
    array_free(it.header.message_table);
    array_free(it.header.string_table);
    array_free(it.header.node_pointer_table);
    free(it.file_name);
    file_close(*it.file);
    remove it;
  }
  array_free(ast_file_states);

  deinit(*workspace_map.map);
  array_free(workspace_map.string_table);

  file_close(*workspace_map_file);
  file_close(*lock_file);
}

get_node_from_location :: (using state: *AST_State, target: Code_Node.Kind, uri: string, line: u64, char: u64) -> *Code_Node {
  assert_initialized(state);

  if !lock_and_open_record_file(state, null, false) return null;
  defer close_and_unlock_record_file(state);

  success, workspace_index := table_find(*workspace_map.map, uri);
  if !success return null;

  ast_file_state := read_ast_file(state, workspace_index);
  if !ast_file_state return null;

  success=, nodes := table_find(*ast_file_state.header.documents, uri);
  visited: Table(*Code_Node, void);
  defer deinit(*visited);

  for root: nodes {
    for node, not_yet_visited: Ast_Visitor.{ root = root, visited = *visited } {
      if not_yet_visited {
        if !is_location_within_node(uri, line, char, node) continue;
        if node.kind == target return node;
      }
    }
  }

  return null;
}

is_location_within_node :: inline (uri: string, line: u64, char: u64, using node: *Code_Node) -> bool {
  if !node || !enclosing_load return false;
  node_uri := sprint("file:///%", enclosing_load.fully_pathed_filename);
  defer free(node_uri);
  if uri != node_uri return false;
  within_l0 := (line == xx l0 && char >= xx c0) || line > xx l0;
  within_l1 := (line == xx l1 && char < xx c1) || line < xx l1;
  return within_l0 && within_l1;
}

#scope_module

assert_initialized :: inline (using state: *AST_State) #expand {
  assert(initialized, "AST Database must be initialized");
}

assert_locked :: inline (using state: *AST_State) #expand {
  assert(locked, "AST Database must be locked");
}

get_block_offset :: inline (base_offset: s64) -> s64 {
  block_mask := (cast(u64) 1 << AST_BLOCK_EXP) - 1;
  return xx ((xx base_offset + block_mask) & ~block_mask);
}

#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "Hash_Table";
#import "Process";
#import "Ast_Visitor";
