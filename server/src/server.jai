LOG_FOLDER :: "log";
SERVER_NAME :: "Jai Language Server";
SERVER_VERSION :: "0.0.1";

#run {
  make_directory_if_it_does_not_exist("../out");
  delete_directory(tprint("../../%", LOG_FOLDER));
  
  set_build_options_dc(.{
    output_executable_name = "server",
    output_path = "../out"
  });
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
      if buffer.allocated >= 1024 * 1024
        assert(false, "Corrupdated header encountered");
      output.data = output_start + i;
    }
    if output == delimiter break;
    i += 1;
    output.data = output_start + i;
  }
  
  return count_start, i;
}

parse_string :: (value: string) -> string {
  assert(value.data[0] == #char "\"" && value.data[value.count-1] == #char "\"", "Expected the value to be a string, but got '%'", value);
  result: string;
  result.count = value.count - 2;
  result.data = alloc(result.count);
  memcpy(result.data, value.data + 1, result.count);
  return result;
}

parse_header :: (buffer: *[..]u8) -> content_length: int, content_type: string {
  content_length := 0;
  content_type := "application/vscode-jsonrpc; charset=utf-8";
  
  header_offset, header_count := read_until(buffer, "{");
  header := string.{header_count, buffer.data + header_offset};
  
  lines := split(header, "\r\n",, temp);
  for lines {
    if it == "" continue;
    success, key, value := split_from_left(it, ": ");
    assert(success, "Invalid header line: '%'", it);
    
    if key == {
      case "Content-Length";
        content_length = string_to_int(value);
      
      case "Content-Type";
        content_type = parse_string(value,, temp);
      
      case;
        assert(false, "Encountered an unknown header field '%'", key);
    }
  }
  
  assert(content_type == "application/vscode-jsonrpc; charset=utf-8", "Received 'Content-Type: %', but only 'application/vscode-jsonrpc; charset=utf-8' is supported", content_type);
  
  rpc_debug_log("Header:\nContent-Length: %\r\nContent-Type: \"%\"\r\n\r\n", content_length, content_type);
  
  buffer.count -= header_offset + header_count;
  memcpy(buffer.data, header.data + header_count, buffer.count);
  
  return content_length, content_type;
}

read_message : JSON_RPC_Read_Message : (_data: *void) -> string {
  data: *Data = xx _data;
  
  size, type := parse_header(*data.buffer);
  
  content: string;
  content.data = alloc(size);
  content.count = data.buffer.count;
  memcpy(content.data, data.buffer.data, data.buffer.count);
  data.buffer.count = 0;
  
  while content.count < size {
    if content.count sleep_milliseconds(1);
    content.count += read_next(content.data + content.count, size - content.count);
  }
  
  return content;
}

send_message : JSON_RPC_Send_Message : (data: *void, message: string) {
  print("Content-Length: %\r\n", message.count);
  print("\r\n");
  print(message);
}

debug_log : JSON_RPC_Debug_Log : (_data: *void, message: string, to_standard_error := false) -> bytes_printed: s64 {
  data: *Data = xx _data;
  
  if data.trace == "off" return 0;
  
  #if OS == .WINDOWS {
    stdin := File.{GetStdHandle(STD_INPUT_HANDLE)};
  }
  
  file, file_opened := file_open(data.filename, true, true, false);
  if file_opened {
    file_seek(file, 0, .END);
    file_write(*file, message);
    file_close(*file);
  }
  
  // lsp_logTrace(data, .{message = message});
  
  return message.count;
}

get_type :: (any: Any) -> *Type_Info {
  type := type.type;
  while type.type == .VARIANT
    type = (cast(*Type_Info_Variant) type).variant_of;
  return type;
}

cast_any :: (any: Any, T: Type) -> *T #expand {
  return cast(*T) any.value_pointer;
}

Data :: struct {
  buffer: [..] u8;
  filename: string;
  
  is_initialized: bool;
  is_shutdown: bool;
  trace: LSP_TraceValue;
}

main :: () {
  #if OS == .WINDOWS {
    timeBeginPeriod(1);
  }
  
  data: Data;
  
  make_directory_if_it_does_not_exist(LOG_FOLDER);
  data.filename = sprint("%/%.log", LOG_FOLDER, current_time_monotonic().low);
  
  initialize_rpc(*data, read_message, send_message, xx debug_log);
  
  add_rpc_request_handler("$/setTrace", lsp_setTrace);
  add_rpc_request_handler("initialize", lsp_initialize);
  add_rpc_request_handler("shutdown", lsp_shutdown);
  
  while true {
    reset_temporary_storage();
    rpc_read_and_respond();
  }
}

#scope_file

#import "Basic";
#import "Compiler";
#import "File";
#import "String";
#import "Hash_Table";

#if OS == .WINDOWS {
  #import "Windows";
} else {
  #import "POSIX";
}

#import "Json" (CAST_SCOPE = #code main);

#load "json_rpc.jai";
#load "lsp.jai";