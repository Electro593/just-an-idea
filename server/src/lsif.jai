INDEX_FOLDER :: "database";
INDEX_NAME :: "index";
LSIF_NAME :: "index.lsif";
LOCK_NAME :: "index.lock";

LSIF_Record_Type :: string;
LSIF_Record_Type_Vertex :: "vertex";
LSIF_Record_Type_Edge :: "edge";

LSIF_Record :: struct {
  id: int;
  type: LSIF_Record_Type;
  label: string;
}

LSIF_Edge :: struct {
  #as using _: LSIF_Record;
  type = LSIF_Record_Type_Edge;
  
  outV: u64;
  inV: u64;
}

LSIF_Contains :: struct {
  #as using _: LSIF_Record;
  type = LSIF_Record_Type_Edge;
  label = "contains";
  
  outV: u64;
  inVs: [] u64;
}

LSIF_Project :: struct {
  #as using _: LSIF_Record;
  type = LSIF_Record_Type_Vertex;
  label = "project";
  
  resource: string;
  kind: string;
  contents: string; @?
}

LSIF_Document :: struct {
  #as using _: LSIF_Record;
  type = LSIF_Record_Type_Vertex;
  label = "document";
  
  uri: LSP_DocumentUri;
  languageId: LSP_LanguageId;
  contents: string; @?
}

LSIF_Range :: struct {
  #as using _: LSIF_Record;
  type = LSIF_Record_Type_Vertex;
  label = "range";
  
  using range: LSP_Range;
}

LSIF_ResultSet :: struct {
  #as using _: LSIF_Record;
  type = LSIF_Record_Type_Vertex;
  label = "resultSet";
}

LSIF_Item :: struct {
  #as using _: LSIF_Record;
  type = LSIF_Record_Type_Edge;
  label = "item";
  
  outV: u64;
  inVs: [] u64;
  shard: u64; // document or project id
}


// file format

RecordFile :: struct {
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
  
  hash_table: Table(string, RecordFile_HashEntryValue);
  lockfile: File;
  file: File;
}

RecordFile_Document :: struct {
  uri: LSP_DocumentUri;
  range_count: u64;
  range_table_block_count: u64;
  range_table_block_index: u64;
}

RecordFile_Range :: struct {
  range: LSP_Range;
  result_set_index: u64;
}

RecordFile_ResultSet :: struct {
  declaration_index: u64;
  definition_index: u64;
}

RecordFile_ItemSet :: struct {
  range_count: u64;
  item_count: u64;
  first_item_index: u64;
}

RecordFile_Item :: struct {
  document_index: u64;
  item_range_count: u64;
  first_item_range_index: u64;
}

RecordFile_ItemRange :: struct {
  range_index: u64;
}

RecordFile_HashEntryValue :: struct {
  document_index: u64;
  range_index: u64;
}

make_hash_table_key :: inline (uri: LSP_DocumentUri, position: LSP_Position) -> string {
  return sprint("%;%:%", uri, position.line, position.character);
}

lock_index :: (for_writing: bool) -> lockfile: File {
  lockfile_name := tprint("%/%", INDEX_FOLDER, LOCK_NAME);
  lockfile, success := file_open(lockfile_name, for_writing);
  while !success {
    sleep_milliseconds(10);
    lockfile, success = file_open(lockfile_name, for_writing);
  }
  return lockfile;
}

lock_and_open_index :: (for_writing: bool) -> header: RecordFile, success: bool {
  lockfile := lock_index(for_writing);
  
  file, success := file_open(tprint("%/%", INDEX_FOLDER, INDEX_NAME), for_writing, true);
  if !success {
    file_close(*lockfile);
    return .{}, false;
  }
  
  header: RecordFile;
  success=, bytes_read := file_read(file, *header, size_of(RecordFile));
  if !success || bytes_read != size_of(RecordFile) {
    file_close(*file);
    file_close(*lockfile);
    return .{}, false;
  }
  
  header.hash_table.allocator = context.allocator;
  header.hash_table.entries = .[];
  header.lockfile = lockfile;
  header.file = file;
  
  return header, true;
}

close_and_unlock_index :: (header: *RecordFile) {
  file_close(*header.file);
  file_close(*header.lockfile);
  header.* = .{};
}

read_records :: (using header: *RecordFile, block_index: u64, record_index: u64, record_count: u64, records: *[]$T) -> success: bool {
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

read_record :: (using header: *RecordFile, block_index: u64, record_index: u64, record: *$T) -> success: bool {
  if !record return false;
  
  if !file_set_position(file, xx ((block_index << block_size_exponent) + (record_index * size_of(T))))
    return false;
  
  if !file_read(file, record, size_of(T))
    return false;
  
  return true;
}

find_result_set :: (using header: *RecordFile, uri: LSP_DocumentUri, position: LSP_Position, document: *RecordFile_Document, range: *RecordFile_Range, result_set: *RecordFile_ResultSet) -> found: bool {
  hash_entry_table: [] hash_table.Entry;
  if !read_records(header, hash_entry_table_block_index, 0, hash_entry_count, *hash_entry_table)
    return false;
  defer free(hash_entry_table.data);
  
  hash_table.allocator = context.allocator;
  hash_table.entries = hash_entry_table;
  key := make_hash_table_key(uri, position,, temp);
  value, found := table_find(*hash_table, key);
  if !found return false;
  
  if !read_record(header, document_table_block_index, value.document_index, document)
    return false;
  if !read_record(header, document.range_table_block_index, value.range_index, range)
    return false;
  if !read_record(header, result_set_table_block_index, range.result_set_index, result_set)
    return false;
  
  return true;
}

create_location_links_from_item_set :: (using header: *RecordFile, range: LSP_Range, item_set: RecordFile_ItemSet) -> links: [] LSP_LocationLink, success: bool {
  items: [] RecordFile_Item;
  if !read_records(header, item_table_block_index, item_set.first_item_index, item_set.item_count, *items)
    return .[], false;
  defer free(items.data);
  
  locations: [] LSP_LocationLink;
  locations.count = xx item_set.range_count;
  locations.data = alloc(locations.count * size_of(LSP_LocationLink));
  
  index := 0;
  for item: items {
    item_document: RecordFile_Document;
    if !read_record(header, document_table_block_index, item.document_index, *item_document)
      continue;
    
    item_ranges: [] RecordFile_ItemRange;
    if !read_records(header, item_range_table_block_index, item.first_item_range_index, item.item_range_count, *item_ranges)
      continue;
    defer free(item_ranges.data);
    
    for item_range_pointer: item_ranges {
      item_range: RecordFile_Range;
      if !read_record(header, item_document.range_table_block_index, item_range_pointer.range_index, *item_range)
        continue;
      
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

find_declaration_links :: (using header: *RecordFile, uri: LSP_DocumentUri, position: LSP_Position) -> links: [] LSP_LocationLink, found: bool {
  document: RecordFile_Document;
  range: RecordFile_Range;
  result_set: RecordFile_ResultSet;
  if !find_result_set(header, uri, position, *document, *range, *result_set)
    return .[], false;
  if result_set.declaration_index == cast,no_check(u64) -1
    return .[], true;
  
  declaration: RecordFile_ItemSet;
  if !read_record(header, declaration_table_block_index, result_set.declaration_index, *declaration)
    return .[], false;
  
  links, success := create_location_links_from_item_set(header, range.range, declaration);
  return links, success;
}

find_definition_links :: (using header: *RecordFile, uri: LSP_DocumentUri, position: LSP_Position) -> links: [] LSP_LocationLink, found: bool {
  document: RecordFile_Document;
  range: RecordFile_Range;
  result_set: RecordFile_ResultSet;
  if !find_result_set(header, uri, position, *document, *range, *result_set)
    return .[], false;
  if result_set.definition_index == cast,no_check(u64) -1
    return .[], true;
  
  definition: RecordFile_ItemSet;
  if !read_record(header, definition_table_block_index, result_set.definition_index, *definition)
    return .[], false;
  
  links, success := create_location_links_from_item_set(header, range.range, definition);
  return links, success;
}