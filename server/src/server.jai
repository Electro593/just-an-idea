#run {
  make_directory_if_it_does_not_exist("../out");
  
  set_build_options_dc(.{
    output_executable_name = "server",
    output_path = "../out"
  });
}

send_error :: (loc: Source_Code_Location, message: string) -> bool {
  write_to_file(message);
  return true;
}

write_to_file :: (message: string) {
  #if OS == .WINDOWS {
    stdin := File.{GetStdHandle(STD_INPUT_HANDLE)};
  }
  
  file, file_opened := file_open(filename, true, true, false);
  if file_opened {
    file_seek(file, 0, .END);
    file_write(*file, message);
    file_close(*file);
  }
}

read_next :: (buffer: *u8, to_read: s64) -> bytes_read: u32 {
  #if OS == .WINDOWS {
    bytes_read: u32;
    success := ReadFile(GetStdHandle(STD_INPUT_HANDLE), buffer, xx to_read, *bytes_read);
  } else {
    bytes_read := read(STDIN_FILENO, buffer, xx to_read);
    success := bytes_read >= 0;
  }
  
  assert(xx success, "Couldn't read from stdin");
  return bytes_read;
}

read_into :: (buffer: *[..]u8) {
  maybe_grow(buffer);
  buffer.count += read_next(buffer.data + buffer.count, buffer.allocated - buffer.count);
}

read_until :: (buffer: *[..]u8, delimiter: string) -> offset: s64, count: s64 {
  count_start := buffer.count;
  buffer_start := buffer.data;
  output_start := buffer.data + count_start;
  
  output: string;
  output.data = output_start;
  output.count = delimiter.count;
  
  i: s64 = 0;
  while true {
    while output.data + output.count > buffer.data + buffer.count || !output[output.count-1] {
      sleep_milliseconds(10);
      read_into(buffer);
      output_start = buffer.data + count_start;
      if buffer.allocated >= 1024 * 1024 {
        assert(false, "Corrupdated header encountered, terminating.");
        exit(1);
      }
      
      output.data = output_start + i;
    }
    output.data = output_start + i;
    if output == delimiter break;
    i += 1;
  }
  
  return count_start, i;
}

parse_string :: (value: string) -> string {
  assert(value.data[0] == #char "\"" && value.data[value.count-1] == #char "\"", "Expected the value to be a string, but got '%'", value);
  result: string;
  result.count = value.count - 2;
  result.data = talloc(result.count);
  memcpy(result.data, value.data + 1, result.count);
  return result;
}

parse_header :: (buffer: *[..]u8) -> content_length: int, content_type: string {
  content_length := 0;
  content_type := "application/vscode-jsonrpc; charset=utf-8";
  
  header_offset, header_count := read_until(buffer, "{");
  header := string.{header_count, buffer.data + header_offset};
  
  lines := split(header, "\r\n");
  for lines {
    if it == "" continue;
    success, key, value := split_from_left(it, ": ");
    assert(success, "Invalid header line: '%'", it);
    
    if key == {
      case "Content-Length";
        content_length = string_to_int(value);
      
      case "Content-Type";
        content_type = parse_string(value);
      
      case;
        assert(false, "Encountered an unknown header field '%'", key);
    }
  }
  
  assert(content_type == "application/vscode-jsonrpc; charset=utf-8", "Received 'Content-Type: %', but only 'application/vscode-jsonrpc; charset=utf-8' is supported", content_type);
  
  write_to_file(tprint("Parsed:\nContent-Length: %\nContent-Type: %\n\n", content_length, content_type));
  
  buffer.count -= header_offset + header_count;
  memcpy(buffer.data, header.data + header_count, buffer.count);
  
  return content_length, content_type;
}

filename: string;

main :: () {
  delete_directory("jai_lsp_test");
  make_directory_if_it_does_not_exist("jai_lsp_test");
  random_seed(current_time_monotonic().low);
  filename = sprint("jai_lsp_test/%", random_get());
  
  // context.assertion_failed = send_error;
  
  buffer: [..]u8;
  
  methods: Table(string, JSON_RPC_Method);
  
  while true {
    reset_temporary_storage();
    
    size, type := parse_header(*buffer);
    
    content: string;
    content.data = talloc(size);
    content.count = buffer.count;
    memcpy(content.data, buffer.data, buffer.count);
    buffer.count = 0;
    
    while content.count < size {
      if content.count sleep_milliseconds(1);
      content.count += read_next(content.data + content.count, size - content.count);
    }
    
    request := parse_json(content);
    write_to_file(print_element(request));
    write_to_file("\n\n");
    
    response := handle_rpc_request(methods, request);
    write_to_file(print_element(response));
    write_to_file("\n\n");
    print(print_element(response));
  }
}

#scope_file

#import "Basic";
#import "Compiler";
#import "File";
#import "String";
#import "Hash_Table";
#import "Random";

#if OS == .WINDOWS {
  #import "Windows";
} else {
  #import "POSIX";
}

#import "Json";

#load "json_rpc.jai";