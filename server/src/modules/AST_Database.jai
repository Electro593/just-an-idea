#module_parameters (DATABASE_FOLDER := "database") ();

LOCK_FILE_NAME :: "lock";
WORKSPACE_MAP_FILE_NAME :: "workspaces_map";

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
    file: File;
    file_name: string;
    data: AST_File_Header;
  }
}

Workspace_Map_Header :: struct {
  file_size: u64;
  block_exp: u8;
  
  map: Table(string, u64); // Document URI -> Workspace Index
  
  string_table: [..] u8;
}

AST_File_Header :: struct {
  file_size: u64;
  block_exp: u8;
  
  documents: Table(string, [] Code_Node); // Document URI -> Nodes
  
  node_table: [..] u8;
  string_table: [..] u8;
}

ast_file_name :: inline (index: u64) -> string {
  return tprint("workspace_%", index);
}

initialize_ast_database_state :: () -> AST_State {
  state: AST_State;
  state.lock_file_name = tprint("%/%", DATABASE_FOLDER, LOCK_FILE_NAME);
  state.workspace_map_file_name = tprint("%/%", DATABASE_FOLDER, WORKSPACE_MAP_FILE_NAME);
  state.initialized = true;
  return state;
}

initialize_ast_database :: (using state: *AST_State, workspace_map_block_exp: u8 = 10) {
  assert_initialized(state);
  
  Map_Entry :: Workspace_Map_Header.map.Entry;
  block_size := cast(s64) 1 << workspace_map_block_exp;
  assert(workspace_map_block_exp <= 63, "Blocks cannot be larger than a 2**63 bytes, but you tried 2**%!", workspace_map_block_exp);
  assert(block_size >= size_of(Map_Entry), "Blocks must be at least the size of a workspace map entry, which is % bytes, but you tried %", size_of(Map_Entry), block_size);
  assert(block_size / size_of(Map_Entry) * size_of(Map_Entry) == block_size, "Map entry must be a power of 2, but it's %", size_of(Map_Entry));
  
  make_directory_if_it_does_not_exist(DATABASE_FOLDER);
  
  lock_file=, success := file_open(lock_file_name, true);
  assert(success, "Could not open the lockfile '%' to initialize the AST database", lock_file_name);
  defer file_close(*lock_file);
  
  if !file_exists(workspace_map_file_name) {
    workspace_map_file, success = file_open(workspace_map_file_name, true);
    assert(success, "Could not open the workspace map '%' to initialize the AST database", workspace_map_file_name);
    defer file_close(*workspace_map_file);
    
    workspace_map: *Workspace_Map_Header = alloc(block_size);
    defer free(workspace_map);
    
    allocated := block_size / size_of(Map_Entry);
    workspace_map.file_size = xx (3 * block_size); // header + workspace_map + string_table
    workspace_map.block_exp = workspace_map_block_exp;
    workspace_map.map.count = 0;
    workspace_map.map.allocated = xx allocated;
    workspace_map.map.slots_filled = 0;
    workspace_map.map.allocator = .{};
    workspace_map.map.entries.count = xx allocated;
    workspace_map.map.entries.data = xx (1 * block_size); // header
    workspace_map.string_table.count = 0;
    workspace_map.string_table.data = xx (2 * block_size); // header + workspace_map
    workspace_map.string_table.allocated = block_size;
    workspace_map.string_table.allocator = .{};
    
    block := alloc(block_size);
    memset(block, 0, block_size);
    defer free(block);
    
    file_write(*workspace_map_file, workspace_map, block_size);
    file_write(*workspace_map_file, block, block_size);
    file_write(*workspace_map_file, block, block_size);
  }
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
  
  workspace_map_file=, success := file_open(workspace_map_file_name, for_writing, true);
  if !success {
    file_close(*lock_file);
    return false;
  }
  
  success=, bytes_read := file_read(workspace_map_file, *workspace_map, size_of(Workspace_Map_Header));
  if !success || bytes_read != size_of(Workspace_Map_Header) {
    file_close(*workspace_map_file);
    file_close(*lock_file);
    return false;
  }
  
  map_block_offset := get_block_offset(workspace_map.block_exp, size_of(Workspace_Map_Header));
  success = file_set_position(workspace_map_file, xx map_block_offset);
  if !success {
    file_close(*workspace_map_file);
    file_close(*lock_file);
    return false;
  }
  workspace_map_size := workspace_map.map.allocated * size_of(Workspace_Map_Header.map.Entry);
  workspace_map.map.allocator = context.allocator;
  workspace_map.map.entries.data = alloc(workspace_map_size);
  success, bytes_read = file_read(workspace_map_file, workspace_map.map.entries.data, workspace_map_size);
  if !success || bytes_read != workspace_map_size {
    free(workspace_map.map.entries.data);
    file_close(*workspace_map_file);
    file_close(*lock_file);
    return false;
  }
  
  table_block_offset := get_block_offset(workspace_map.block_exp, map_block_offset + xx workspace_map_size);
  success = file_set_position(workspace_map_file, xx table_block_offset);
  if !success {
    free(workspace_map.map.entries.data);
    file_close(*workspace_map_file);
    file_close(*lock_file);
    return false;
  }
  string_table_size := workspace_map.string_table.allocated;
  workspace_map.string_table.allocator = context.allocator;
  workspace_map.string_table.data = alloc(string_table_size);
  success, bytes_read = file_read(workspace_map_file, workspace_map.string_table.data, string_table_size);
  if !success || bytes_read != string_table_size {
    free(workspace_map.map.entries.data);
    free(workspace_map.string_table.data);
    file_close(*workspace_map_file);
    file_close(*lock_file);
    return false;
  }
  
  return true;
}

close_and_unlock_record_file :: (using state: *AST_State) {
  file_close(*workspace_map_file);
  file_close(*lock_file);
}

get_node_from_location :: (state: *AST_State, uri: string, line: u64, char: u64) -> *Code_Node {

}


#scope_module

assert_initialized :: (using state: *AST_State) #expand {
  assert(initialized, "AST Database must be initialized");
}

get_block_offset :: (block_exp: u8, base_offset: u64) -> u64 {
  block_mask := (cast(u64) 1 << block_exp) - 1;
  return (base_offset + block_mask) & ~block_mask;
}

#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "Hash_Table";
#import "Process";

#import "Binary_Search";