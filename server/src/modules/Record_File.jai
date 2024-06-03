#module_parameters (RECORD_FILE_FOLDER := "database", RECORD_FILE_NAME := "index", LOCK_NAME := "index.lock") ();

Record_File :: struct {
  file_size: u64;
  block_count: u64;
  block_size_exponent: u8;
  // 7-byte hole
  
  document_count: u64;
  document_table_block_count: u64;
  document_table_block_index: u64;
  
  result_set_count: u64;
  result_set_table_block_count: u64;
  result_set_table_block_index: u64;
  
  definition_count: u64;
  definition_table_block_count: u64;
  definition_table_block_index: u64;
  
  declaration_count: u64;
  declaration_table_block_count: u64;
  declaration_table_block_index: u64;
  
  item_count: u64;
  item_table_block_count: u64;
  item_table_block_index: u64;
  
  item_range_count: u64;
  item_range_table_block_count: u64;
  item_range_table_block_index: u64;
  
  string_table_size: u64;
  string_table_block_count: u64;
  string_table_block_index: u64;
  
  hash_entry_count: u64;
  hash_entry_table_block_count: u64;
  hash_entry_table_block_index: u64;
  
  hash_table: Table(string, Record_File_Hash_Entry_Value);
  lockfile: File;
  file: File;
}

Record_File_Document :: struct {
  uri: LSP_DocumentUri;
  range_count: u64;
  range_table_block_count: u64;
  range_table_block_index: u64;
}

Record_File_Range :: struct {
  range: LSP_Range;
  result_set_index: u64;
}

Record_File_Result_set :: struct {
  declaration_index: u64;
  definition_index: u64;
}

Record_File_Item_Set :: struct {
  range_count: u64;
  item_count: u64;
  first_item_index: u64;
}

Record_File_Item :: struct {
  document_index: u64;
  item_range_count: u64;
  first_item_range_index: u64;
}

Record_File_Item_Range :: struct {
  range_index: u64;
}

Record_File_Hash_Entry_Value :: struct {
  document_index: u64;
  range_index: u64;
}

make_hash_table_key :: inline (uri: LSP_DocumentUri, position: LSP_Position) -> string {
  return sprint("%;%:%", uri, position.line, position.character);
}

initialize_record_file :: () {
  make_directory_if_it_does_not_exist(RECORD_FILE_FOLDER);
  file_close(*file_open(tprint("%/%", RECORD_FILE_FOLDER, LOCK_NAME), true));
  file_close(*file_open(tprint("%/%", RECORD_FILE_FOLDER, RECORD_FILE_NAME), true, true));
}

lock_record_file :: (for_writing: bool) -> lockfile: File {
  lockfile_name := tprint("%/%", RECORD_FILE_FOLDER, LOCK_NAME);
  lockfile, success := file_open(lockfile_name, for_writing);
  while !success {
    sleep_milliseconds(10);
    lockfile, success = file_open(lockfile_name, for_writing);
  }
  return lockfile;
}

lock_and_open_record_file :: (terminate: *Process, for_writing: bool) -> header: Record_File, success: bool {
  lockfile := lock_record_file(for_writing);
  
  if terminate {
    kill_process(terminate);
  }
  
  record_file_name := tprint("%/%", RECORD_FILE_FOLDER, RECORD_FILE_NAME);
  file, success := file_open(record_file_name, for_writing, true);
  if !success {
    file_close(*lockfile);
    return .{}, false;
  }
  
  header: Record_File;
  success=, bytes_read := file_read(file, *header, size_of(Record_File));
  
  if !success || bytes_read != size_of(Record_File) {
    file_close(*file);
    file, success = file_open(record_file_name, true);
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
    file, success = file_open(record_file_name, for_writing, true);
    if !success {
      file_close(*lockfile);
      return .{}, false;
    }
  }
  
  header.hash_table.allocator = context.allocator;
  header.hash_table.entries = .[];
  header.lockfile = lockfile;
  header.file = file;
  
  return header, true;
}

close_and_unlock_record_file :: (header: *Record_File) {
  file_close(*header.file);
  file_close(*header.lockfile);
  header.* = .{};
}

read_records :: (using header: *Record_File, block_index: u64, record_index: u64, record_count: u64, records: *[]$T) -> success: bool {
  if !records return false;
  
  if !file_set_position(file, xx ((block_index << block_size_exponent) + (record_index * size_of(T))))
    return false;
  
  bytes_to_read := record_count * size_of(T);
  records.count = xx record_count;
  records.data = alloc(xx bytes_to_read);
  
  if !file_read(file, records.data, xx bytes_to_read) {
    free(records.data);
    return false;
  }
  
  return true;
}

read_record :: (using header: *Record_File, block_index: u64, record_index: u64, record: *$T) -> success: bool {
  if !record return false;
  
  if !file_set_position(file, xx ((block_index << block_size_exponent) + (record_index * size_of(T))))
    return false;
  
  if !file_read(file, record, size_of(T))
    return false;
  
  return true;
}

read_from_hash_table :: (using header: *Record_File, key: string) -> value: Record_File_Hash_Entry_Value, found: bool {
  hash_entry_table: [] hash_table.Entry;
  if !read_records(header, hash_entry_table_block_index, 0, hash_entry_count, *hash_entry_table)
    return .{}, false;
  defer free(hash_entry_table.data);
  
  hash_table.allocator = context.allocator;
  hash_table.entries = hash_entry_table;
  value, found := table_find(*hash_table, key);
  return value, found;
}

find_result_set :: (using header: *Record_File, uri: LSP_DocumentUri, position: LSP_Position, document: *Record_File_Document, range: *Record_File_Range, result_set: *Record_File_Result_set) -> found: bool {
  value, found := read_from_hash_table(header, make_hash_table_key(uri, position,, temp));
  if !found return false;
  
  if !read_record(header, document_table_block_index, value.document_index, document)
    return false;
  if !read_record(header, document.range_table_block_index, value.range_index, range)
    return false;
  if !read_record(header, result_set_table_block_index, range.result_set_index, result_set)
    return false;
  
  return true;
}

create_location_links_from_item_set :: (using header: *Record_File, range: LSP_Range, item_set: Record_File_Item_Set) -> links: [] LSP_LocationLink, success: bool {
  items: [] Record_File_Item;
  if !read_records(header, item_table_block_index, item_set.first_item_index, item_set.item_count, *items)
    return .[], false;
  defer free(items.data);
  
  locations: [] LSP_LocationLink;
  locations.count = xx item_set.range_count;
  locations.data = alloc(locations.count * size_of(LSP_LocationLink));
  
  index := 0;
  for item: items {
    item_document: Record_File_Document;
    if !read_record(header, document_table_block_index, item.document_index, *item_document)
      continue;
    
    item_ranges: [] Record_File_Item_Range;
    if !read_records(header, item_range_table_block_index, item.first_item_range_index, item.item_range_count, *item_ranges)
      continue;
    defer free(item_ranges.data);
    
    for item_range_pointer: item_ranges {
      item_range: Record_File_Range;
      if !read_record(header, item_document.range_table_block_index, item_range_pointer.range_index, *item_range)
        continue;
      
      // TODO: Figure out what targetSelectionRange does
      locations[index] = .{
        originSelectionRange = range,
        targetUri = item_document.uri,
        targetRange = item_range.range,
        targetSelectionRange = item_range.range
      };
      
      index += 1;
    }
  }
  locations.count = index;
  
  return locations, true;
}

find_declaration_links :: (using header: *Record_File, uri: LSP_DocumentUri, position: LSP_Position) -> links: [] LSP_LocationLink, found: bool {
  document: Record_File_Document;
  range: Record_File_Range;
  result_set: Record_File_Result_set;
  if !find_result_set(header, uri, position, *document, *range, *result_set)
    return .[], false;
  if result_set.declaration_index == cast,no_check(u64) -1
    return .[], true;
  
  declaration: Record_File_Item_Set;
  if !read_record(header, declaration_table_block_index, result_set.declaration_index, *declaration)
    return .[], false;
  
  links, success := create_location_links_from_item_set(header, range.range, declaration);
  return links, success;
}

find_definition_links :: (using header: *Record_File, uri: LSP_DocumentUri, position: LSP_Position) -> links: [] LSP_LocationLink, found: bool {
  document: Record_File_Document;
  range: Record_File_Range;
  result_set: Record_File_Result_set;
  if !find_result_set(header, uri, position, *document, *range, *result_set)
    return .[], false;
  if result_set.definition_index == cast,no_check(u64) -1
    return .[], true;
  
  definition: Record_File_Item_Set;
  if !read_record(header, definition_table_block_index, result_set.definition_index, *definition)
    return .[], false;
  
  links, success := create_location_links_from_item_set(header, range.range, definition);
  return links, success;
}

#scope_module

#import "Basic";
#import "File";
#import "Hash_Table";
#import "Process";

#import "Lsp_Types";