#module_parameters (FILE_FOLDER := "database") ();

LOCK_FILE_NAME :: "lock";
WORKSPACE_MAP_FILE_NAME :: "workspaces_map";

AST_State :: struct {
  lock_file: File;
  lock_file_name: string;
  locked: bool;
  
  workspace_map_file: File;
  workspace_map_file_name: string;
  workspace_map: Workspace_File_Header;
  
  ast_file_states: [..] AST_File_State;
  
  AST_File_State :: struct {
    file: File;
    file_name: string;
    data: AST_File_Header;
  }
}

Workspace_File_Header :: struct {
  map: Table(string, u64); // Document URI -> Workspace Index
  
  entry_table: [] map.Entry;
  string_table: [] u8;
}

AST_File_Header :: struct {
  AST_Document :: [] Code_Node;
  
  documents: Table(string, AST_Document); // Document URI -> Nodes
  
  entry_table: [] documents.Entry;
  node_table: [] u8;
  string_table: [] u8;
}

ast_file_name :: inline (index: u64) -> string {
  return tprint("workspace_%", index);
}

initialize_state :: () -> AST_State {
  using state: AST_State;
  lock_file_name = tprint("%/%", RECORD_FILE_FOLDER, LOCK_FILE_NAME);
  workspace_map_file_name = tprint("%/%", RECORD_FILE_FOLDER, WORKSPACE_MAP_FILE_NAME);
  return state;
}

initialize_record_file :: (using state: *AST_State) {
  make_directory_if_it_does_not_exist(RECORD_FILE_FOLDER);
  file_close(*file_open(lock_file_name, true));
  file_close(*file_open(workspace_map_file_name, true));
}

lock_record_file :: (using state: *AST_State, for_writing: bool) {
  if state.locked return;
  
  lockfile_name := tprint("%/%", RECORD_FILE_FOLDER, LOCK_NAME);
  lockfile, success := file_open(lockfile_name, for_writing);
  while !success {
    sleep_milliseconds(10);
    lockfile, success = file_open(lockfile_name, for_writing);
  }
  
  state.lockfile = lockfile;
  state.locked = true;
}

lock_and_open_record_file :: (using state: *AST_State, terminate: *Process, for_writing: bool) -> success: bool {
  lockfile := lock_record_file(state, for_writing);
  
  if terminate {
    kill_process(terminate);
    deinit(terminate);
  }
  
  workspace_map_file_name := tprint("%/%", RECORD_FILE_FOLDER, WORKSPACE_MAP_FILE_NAME);
  file, success := file_open(workspace_map_file_name, for_writing, true);
  if !success {
    file_close(*lockfile);
    return .{}, false;
  }
  
  header: Record_File;
  success=, bytes_read := file_read(file, *header, size_of(Record_File));
  
  if !success || bytes_read != size_of(Record_File) {
    file_close(*file);
    file, success = file_open(workspace_map_file_name, true);
    if !success {
      file_close(*lockfile);
      return .{}, false;
    }
    
    value := 0;
    header = .{};
    header.block_size_exponent = 12; // 4096-byte (page-sized) blocks
    header.block_count = 1;
    header.file_size = header.block_count << header.block_size_exponent;
    if !file_write(*file, *header, size_of(Record_File))
      || !file_seek(file, xx header.file_size - 1, .START)
      || !file_write(*file, *value, 1) {
      file_close(*file);
      file_close(*lockfile);
      return .{}, false;
    }
    
    file_close(*file);
    file, success = file_open(workspace_map_file_name, for_writing, true);
    if !success {
      file_close(*lockfile);
      return .{}, false;
    }
  }
  
  header.lockfile = lockfile;
  header.file = file;
  
  return header, true;
}

close_and_unlock_record_file :: (header: *Record_File) {
  file_close(*header.file);
  file_close(*header.lockfile);
  header.* = .{};
}

get_node_from_location :: (header: *Record_File, uri: LSP_DocumentUri, pos: LSP_Position) -> *Code_Node {
}

free_allocated_nodes :: (node: *Code_Node) {
  
}

#scope_module

#import "Basic";
#import "File";
#import "Hash_Table";
#import "Process";

#import "Binary_Search";
#import "Lsp_Types";