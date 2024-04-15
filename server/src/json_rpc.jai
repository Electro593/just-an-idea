/* TODO:
 - Validate memory is freed on assert
 - (Test)
 
 - Try to merge casters
 - Add server->client requests
 - (Test)
*/

//TODO: Some of these are defined externally, maybe add a way to custom-define them
JSON_RPC_Error_Code :: enum {
  UNKNOWN            :: -32001;
  NOT_INITIALIZED    :: -32002;
  INVALID_REQUEST    :: -32600;
  METHOD_NOT_FOUND   :: -32601;
  INVALID_PARAMETERS :: -32602;
  INTERNAL_ERROR     :: -32603;
  INVALID_RESPONSE   :: -32604;
  PARSE_ERROR        :: -32700;
  REQUEST_CANCELLED  :: -32800;
  CONTENT_MODIFED    :: -32801;
  SERVER_CANCELLED   :: -32802;
  REQUEST_FAILED     :: -32803;
}

JSON_RPC_Send_Message :: #type (data: *void, message: string);
JSON_RPC_Read_Message :: #type (data: *void) -> message: string;
JSON_RPC_Debug_Log :: #type (data: *void, message: string, to_standard_error := false) -> bytes_printed: s64;

initialize_rpc :: (data: *void, read_message: JSON_RPC_Read_Message, send_message: JSON_RPC_Send_Message, debug_log: JSON_RPC_Debug_Log = dummy_debug_log) {
  state := *_state;
  context.json_rpc.state = state;
  
  assert(!state.is_initialized, "Attempted to initialize, but JSON-RPC is already initialized");
  init(*state.mutex);
  
  state.data = data;
  state.read_message = read_message;
  state.send_message = send_message;
  state.debug_log = debug_log;
  
  set_error(.INTERNAL_ERROR);
  state.is_initialized = true;
  
  rpc_debug_log("JSON-RPC Initialized");
}

start_rpc :: () {
  state := context.json_rpc.state;
  
  worker_thread_count :: 1;
  for state.threads array_add(*state.threads, .{});
  
  while state.is_initialized {
    for * state.threads
      if !it.index
        start_rpc_thread(ifx it_index then threaded_rpc_worker_loop else threaded_rpc_main_loop, it);
    sleep_milliseconds(500);
  }
  
  for * state.threads thread_is_done(it, -1);
  for * state.threads thread_deinit(it);
  array_free(state.threads);
  
  for * state.requests_to_handle free_casted_json(it);
  for * state.responses_to_handle free_casted_json(it);
  for * state.responses_to_send free_casted_json(it);
  array_free(state.requests_to_handle);
  array_free(state.responses_to_handle);
  deinit(*state.responses_to_send);
  
  deinit(*state.methods);
}

add_rpc_request_handler :: (name: string, method: (data: *$D, params: $P) -> $R) {
  caster :: (proc: (data: *D, params: P) -> R, params: Any) -> Any {
    result := proc(xx context.json_rpc.state.data, cast_any(params, P).*);
    any := Any.{type_info(R), alloc(size_of(R))};
    memcpy(any.value_pointer, *result, size_of(R));
    return any;
  }
  add_rpc_method(name, xx caster, xx method);
}

add_rpc_request_handler :: (name: string, method: (data: *$D, params: $P)) {
  caster :: (proc: (data: *D, params: P), params: Any) -> Any {
    proc(xx context.json_rpc.state.data, cast_any(params, P).*);
    return Any.{type_info(void), null};
  }
  add_rpc_method(name, xx caster, xx method);
}

add_rpc_request_handler :: (name: string, method: (data: *$D) -> $R) {
  caster :: (proc: (data: *D) -> R, params: Any) -> Any {
    result := proc(xx context.json_rpc.state.data);
    any := Any.{type_info(R), alloc(size_of(R))};
    memcpy(any.value_pointer, *result, size_of(R));
    return any;
  }
  add_rpc_method(name, xx caster, xx method);
}

add_rpc_request_handler :: (name: string, method: (data: *$D)) {
  caster :: (proc: (data: *D), params: Any) -> Any {
    proc(xx context.json_rpc.state.data);
    return Any.{type_info(void), null};
  }
  add_rpc_method(name, xx caster, xx method);
}

deinitialize_rpc :: () {
  state := context.json_rpc.state;
  assert(state.is_initialized, "Attempted to deinitialize, but JSON-RPC is already uninitialized");
  state.is_initialized = false;
}

set_error :: (code: JSON_RPC_Error_Code) {
  context.json_rpc.assertion_code = code;
}

set_error_data :: (data: Any = Any.{}) {
  context.json_rpc.assertion_data = data;
}

push_error :: (code: JSON_RPC_Error_Code) #expand {
  old_code := context.json_rpc.assertion_code;
  context.json_rpc.assertion_code = code;
  `defer context.json_rpc.assertion_code = old_code;
}

// add_request_to_batch(method: string, params: Any = .{}, is_notification := true, version := DEFAULT_JSON_RPC_VERSION) {
//   state := context.json_rpc.state;
//   
//   message: JSON_RPC_Message;
//   if is_notification
//     message = JSON_RPC_Notification.{jsonrpc, version, method, params};
//   else
//     message = JSON_RPC_Request.{jsonrpc, version, method, params, get_next_id()};
//   
//   json_message := cast_json(message,, temp);
//   lock(*state.mutex);
//   array_add(*state.requests_to_send, json_notification);
//   unlock(*state.mutex);
// }

rpc_debug_log :: (format_string: string, args: ..Any, to_standard_error := false) -> bytes_printed: s64 {
  state := context.json_rpc.state;
  lock(*state.mutex);
  defer unlock(*state.mutex);
  return state.debug_log(state.data, tprint("[Thread %] %\n", context.thread_index, tprint(format_string, ..args)));
}

// #scope_file

DEFAULT_JSON_RPC_VERSION :: "2.0";

JSON_RPC_Message :: struct {
  jsonrpc: string; @?
}

JSON_RPC_Requests :: [..] *JSON_RPC_Request;
JSON_RPC_Request :: struct {
  #as using _: JSON_RPC_Message;
  method: string;
  params: Any; @?
  id: Any; @s32 @string @$Null @?
  
  batch_id: s32; @$Ignore
  is_notification: bool; @$Ignore
}
JSON_RPC_Batch_Request :: struct {
  _: Any; @JSON_RPC_Requests @JSON_RPC_Request
  count_remaining: int; @$Ignore
}

JSON_RPC_Responses :: [..] *JSON_RPC_Response;
JSON_RPC_Response :: struct {
  #as using _: JSON_RPC_Message;
  result: Any; @?
  error: Any; @? @JSON_RPC_Error @$Null
  id: Any; @$Null @s32 @string
}
JSON_RPC_Batch_Response :: struct {
  _: Any; @JSON_RPC_Responses @JSON_RPC_Response
  count_remaining: int; @$Ignore
}

JSON_RPC_Error :: struct {
  code: JSON_RPC_Error_Code;
  message: string;
  data: Any; @?
}

JSON_RPC_Caster :: #type (proc: *void, params: Any) -> Any;
JSON_RPC_Method_Data :: struct {
  caster: JSON_RPC_Caster;
  proc: *void;
}

JSON_RPC :: struct {
  mutex: Mutex;
  
  requests_to_handle: [..] JSON_RPC_Batch_Request;
  responses_to_handle: [..] JSON_RPC_Batch_Response;
  
  responses_to_send: Table(int, JSON_RPC_Batch_Response);
  
  next_id: s32;
  next_batch_id: s32;
  is_initialized: bool;
  
  threads: [..] Thread;
  
  data: *void;
  methods: Table(string, JSON_RPC_Method_Data);
  read_message: JSON_RPC_Read_Message;
  send_message: JSON_RPC_Send_Message;
  debug_log: JSON_RPC_Debug_Log;
}

JSON_RPC_Thread :: struct {
  thread: *Thread;
  state: *JSON_RPC;
  
  batch_id: s32;
  result: Any;
  request: *JSON_RPC_Request;
  // response: *JSON_RPC_Response;
  
  assertion_code: JSON_RPC_Error_Code;
  assertion_data: Any;
}

_state: JSON_RPC;
#add_context json_rpc: JSON_RPC_Thread;

dummy_debug_log : JSON_RPC_Debug_Log : (data: *void, message: string, to_standard_error := false) -> bytes_printed: s64 {
  return 0;
}

get_next_id :: () -> s32 {
  state := context.json_rpc.state;
  lock(*state.mutex);
  id := state.next_id;
  state.next_id += 1;
  unlock(*state.mutex);
  return id;
}

get_next_batch_id :: () -> s32 {
  state := context.json_rpc.state;
  lock(*state.mutex);
  id := state.next_batch_id;
  state.next_batch_id += 1;
  unlock(*state.mutex);
  return id;
}

add_rpc_method :: (name: string, caster: JSON_RPC_Caster, method: *void) {
  state := context.json_rpc.state;
  lock(*state.mutex);
  table_set(*state.methods, name, .{xx caster, xx method});
  unlock(*state.mutex);
  rpc_debug_log("Added '%'", name);
}

start_rpc_thread :: (proc: Thread_Proc, thread: *Thread = null) {
  state := context.json_rpc.state;
  
  if !thread {
    lock(*state.mutex);
    thread = array_add(*state.threads);
    unlock(*state.mutex);
  }
  
  thread.starting_context = context;
  thread.starting_context.assertion_failed = assert_rpc;
  thread.starting_context.json_rpc.thread = thread;
  thread.starting_context.json_rpc.assertion_data = Any.{};
  thread.starting_context.json_rpc.assertion_code = .INTERNAL_ERROR;
  
  thread_init(thread, proc);
  rpc_debug_log("Launching thread %", thread.index);
  thread_start(thread);
}

threaded_rpc_main_loop : Thread_Proc : (thread: *Thread) -> s64 {
  state := context.json_rpc.state;
  set_error(.INTERNAL_ERROR);
  rpc_debug_log("Starting the JSON-RPC main loop");
  
  parse_message :: () -> *JSON_Element {
    push_error(.PARSE_ERROR);
    state := context.json_rpc.state;
    content := state.read_message(state.data,, temp);
    message := parse_json(content,, temp);
    rpc_debug_log("Parsed message content:\n%", print_json(message,, temp));
    return message;
  }
  
  validate_and_add_requests :: (message: *JSON_Element) {
    push_error(.INVALID_REQUEST);
    thread_state := *context.json_rpc;
    state := thread_state.state;
    
    validate_request :: (builder: *String_Builder, using request: *JSON_RPC_Request) {
      assert(!jsonrpc || jsonrpc == "2.0", "jsonrpc must be either missing for version 1.0, or '2.0' for version 2.0, but it was %", jsonrpc);
      assert(jsonrpc || !is_undef(id), "id must be present for JSON-RPC 1.0");
      is_notification = (jsonrpc && is_undef(id)) || (!jsonrpc && get_type(id).type == .VOID);
      batch_id = context.json_rpc.batch_id;
      print_to_builder(builder, "\n%", request);
    }
    
    thread_state.batch_id = get_next_batch_id();
    
    builder: String_Builder;
    init_string_builder(*builder,, temp);
    append(*builder, "Casted the message into:");
    
    lock(*state.mutex);
    batch := array_add(*state.requests_to_handle);
    responses := find_or_add(*state.responses_to_send, thread_state.batch_id);
    unlock(*state.mutex);
    cast_json(message, batch);
    
    count: int;
    if get_type(batch._) == type_info(JSON_RPC_Requests) {
      requests := cast_any(batch._, JSON_RPC_Requests);
      count = requests.count;
      for requests.* {
        thread_state.request = it;
        assert(xx it.jsonrpc, "Batch requests are only defined for json-rpc 2.0 and up");
        validate_request(*builder, it);
      }
      
      _responses: JSON_RPC_Responses;
      responses._ = Any.{type_info(JSON_RPC_Responses), alloc(size_of(JSON_RPC_Responses))};
      cast_any(responses._, JSON_RPC_Responses).* = _responses;
    } else {
      thread_state.request = cast_any(batch._, JSON_RPC_Request);
      count = 1;
      validate_request(*builder, thread_state.request);
    }
    
    lock(*state.mutex);
    batch.count_remaining = count;
    responses.count_remaining = count;
    unlock(*state.mutex);
    
    rpc_debug_log(builder_to_string(*builder));
  }
  
  // validate_and_add_responses :: (message: *JSON_Element) {
  //   push_error(.INVALID_RESPONSE);
  //   state := context.json_rpc.state;
  //   
  //   builder: String_Builder;
  //   init_string_builder(*builder,, temp);
  //   append(*builder, "Casted the message into:");
  //   
  //   lock(*state.mutex);
  //   batch := array_add(*state.responses_to_handle);
  //   unlock(*state.mutex);
  //   cast_json(message, batch);
  //   
  //   count: int;
  //   if get_type(batch) == type_info(JSON_RPC_Responses) {
  //     responses := cast_any(batch._, JSON_RPC_Responses);
  //     count = responses.count;
  //     for responses.* {
  //       thread_state.response = it;
  //       assert(it.jsonrpc, "Batch responses are only defined for json-rpc 2.0 and up");
  //       print_to_builder(*builder, "\n%", it);
  //     }
  //   } else {
  //     thread_state.response = cast_any(batch._, JSON_RPC_Response);
  //     count = 1;
  //     print_to_builder(*builder, "\n%", response);
  //   }
  //   
  //   lock(*state.mutex);
  //   batch.count_remaining = count;
  //   unlock(*state.mutex);
  //   
  //   rpc_debug_log(builder_to_string(*builder));
  // }
  
  send_ready_responses :: () {
    push_error(.INTERNAL_ERROR);
    state := context.json_rpc.state;
    
    builder: String_Builder;
    init_string_builder(*builder,, temp);
    append(*builder, "Sending the responses:");
    
    lock(*state.mutex);
    for * state.responses_to_send {
      if it.count_remaining > 0 continue;
      json := cast_json(it.*,, temp);
      free_casted_json(it);
      remove it;
      printed_json := print_json(json,, temp);
      print_to_builder(*builder, "\n%", printed_json);
      state.send_message(state.data, printed_json);
    }
    unlock(*state.mutex);
    
    rpc_debug_log(builder_to_string(*builder));
  }
  
  while state.is_initialized {
    message := parse_message();
    
    // if get_element(message, "method")
      validate_and_add_requests(message);
    // else
    //   validate_and_add_responses(message);
    
    send_ready_responses();
    
    reset_temporary_storage();
  }
  
  return 0;
}

threaded_rpc_worker_loop : Thread_Proc : (thread: *Thread) -> s64 {
  thread_state := *context.json_rpc;
  state := thread_state.state;
  set_error(.INTERNAL_ERROR);
  rpc_debug_log("Starting a JSON-RPC worker loop");
  
  retrieve_task :: (index: int) {
    thread_state := *context.json_rpc;
    state := thread_state.state;
    push_error(.INTERNAL_ERROR);
    lock(*state.mutex);
    while !state.responses_to_handle.count && !state.requests_to_handle.count {
      unlock(*state.mutex);
      sleep_milliseconds(100);
      lock(*state.mutex);
    }
    // is_response := ((i % 2) || !state.requests_to_handle.count) && state.responses_to_handle.count;
    // if is_response {
    //   for * state.responses_to_handle {
    //     if !it.count_remaining continue;
    //     if get_type(it._) == type_info(JSON_RPC_Responses) {
    //       responses := cast_any(it._, JSON_RPC_Responses);
    //       thread_state.response = responses.*[0];
    //       array_unordered_remove_by_index(responses, 0);
    //     } else {
    //       thread_state.repsonse = cast_any(it._, JSON_RPC_Response);
    //       it._ = .{};
    //     }
    //     it.count_remaining -= 1;
    //     if !it.count_remaining {
    //       free_casted_json(it);
    //       remove it;
    //     }
    //     break;
    //   }
    //   unlock(*state.mutex);
    //   thread_state.batch_id = thread_state.response.batch_id;
    //   assert(xx thread_state.response, "Awoke to obtain a response, but there were none");
    //   rpc_debug_log("Obtained response:\n%", thread_state.response.*);
    // } else {
      for * state.requests_to_handle {
        if !it.count_remaining continue;
        if get_type(it._) == type_info(JSON_RPC_Requests) {
          requests := cast_any(it._, JSON_RPC_Requests);
          thread_state.request = requests.*[0];
          array_unordered_remove_by_index(requests, 0);
        } else {
          thread_state.request = cast_any(it._, JSON_RPC_Request);
          it._ = Any.{};
        }
        it.count_remaining -= 1;
        if !it.count_remaining {
          free_casted_json(it);
          remove it;
        }
        break;
      }
      unlock(*state.mutex);
      thread_state.batch_id = thread_state.request.batch_id;
      assert(xx thread_state.request, "Awoke to obtain a request, but there were none");
      rpc_debug_log("Obtained request:\n%", thread_state.request.*);
    // }
  }
  
  retrieve_method :: () -> name: string, method: JSON_RPC_Method_Data {
    thread_state := *context.json_rpc;
    state := thread_state.state;
    push_error(.METHOD_NOT_FOUND);
    name: string;
    method: JSON_RPC_Method_Data;
    // if thread_state.request {
      name = thread_state.request.method;
      method=, success := table_find(*state.methods, name);
      assert(success);
      rpc_debug_log("Found %", name);
      return name, method;
    // } else {
    //   assert(false);
    //   return "", .{};
    // }
  }
  
  call_method :: (name: string, method: JSON_RPC_Method_Data) {
    thread_state := *context.json_rpc;
    state := thread_state.state;
    push_error(.INTERNAL_ERROR);
    // if thread_state.request {
      params := thread_state.request.params;
      if !is_undef(params)
        rpc_debug_log("Calling '%' with params:\n%", name, params);
      else
        rpc_debug_log("Calling '%' with no params", name);
      set_error_data();
      thread_state.result = method.caster(method.proc, params);
      set_error(.REQUEST_FAILED);
      assert(!is_undef(thread_state.result), "JSON-RPC methods must return a result, but % did not", name);
      rpc_debug_log("Completed '%' with result:\n%", name, thread_state.result);
    // } else {
    //   assert(false);
    //   return .{};
    // }
  }
  
  i := 0;
  while state.is_initialized {
    defer i += 1;
    
    retrieve_task(i);
    name, method := retrieve_method();
    call_method(name, method);
    
    add_response(thread_state.result, Any.{});
    thread_state.result = Any.{};
    
    free_casted_json(*thread_state.request);
    // free_casted_json(*thread_state.response);
    
    reset_temporary_storage();
  }
  
  return 0;
}

add_response :: (result: Any, error: Any) {
  thread_state := *context.json_rpc;
  state := thread_state.state;
  push_error(.INTERNAL_ERROR);
  if thread_state.request.is_notification return;
  lock(*state.mutex);
  batch, new := find_or_add(*state.responses_to_send, thread_state.batch_id);
  unlock(*state.mutex);
  response: *JSON_RPC_Response;
  if get_type(batch) == type_info(JSON_RPC_Responses) {
    responses := cast_any(batch._, JSON_RPC_Responses);
    response_ptr := array_add(responses);
    response_ptr.* = alloc(size_of(JSON_RPC_Response));
    response = response_ptr.*;
  } else {
    if new batch.* = .{Any.{type_info(JSON_RPC_Response), alloc(size_of(JSON_RPC_Response))}, 1};
    response = cast_any(batch._, JSON_RPC_Response);
  }
  response.jsonrpc = copy_casted_json(thread_state.request.jsonrpc);
  response.id = copy_casted_json(thread_state.request.id);
  response.result = ifx !is_undef(result) then result else ifx response.jsonrpc then Any.{} else Any.{type_info(void), null};
  response.error  = ifx !is_undef(error)  then error  else ifx response.jsonrpc then Any.{} else Any.{type_info(void), null};
  batch.count_remaining -= 1;
}

assert_rpc :: (loc: Source_Code_Location, message: string) -> bool {
  thread_state := *context.json_rpc;
  state := thread_state.state;
  
  // if thread_state.response {
  //   exit(2);
  //   free_casted_json(*thread_state.response);
  // } else {
    error: *JSON_RPC_Error = alloc(size_of(JSON_RPC_Error));
    error.code = thread_state.assertion_code;
    error.data = thread_state.assertion_data;
    
    description: string;
    if #complete thread_state.assertion_code == {
      case .NOT_INITIALIZED;    description = "The server is not yet initialized";
      case .INVALID_REQUEST;    description = "The provided request is not valid";
      case .METHOD_NOT_FOUND;   description = tprint("Could not find the requested method '%'", thread_state.request.method);
      case .INVALID_PARAMETERS; description = "The provided parameters are invalid";
      case .INTERNAL_ERROR;     description = "Encountered an internal JSON-RPC error";
      case .INVALID_RESPONSE;   description = "The provided response is not valid";
      case .PARSE_ERROR;        description = "Encountered an error while parsing the request";
      case .REQUEST_CANCELLED;  description = "Detected that the client cancelled the request";
      case .CONTENT_MODIFED;    description = "The content of the document was modified outside normal conditions";
      case .SERVER_CANCELLED;   description = "The server cancelled the request";
      case .REQUEST_FAILED;     description = "The request failed";
      case .UNKNOWN; #through;
      case; error.message = "Unknown error occurred";
    }
    error.message = tprint("%0%0%", description, ifx message then ": " else ".", message);
    
    builder: String_Builder;
    init_string_builder(*builder,, temp);
    print_to_builder(*builder, "%:%,%: Assertion failed: [%] %\n",
      loc.fully_pathed_filename,
      loc.line_number,
      loc.character_number,
      error.code,
      error.message);
    if !is_undef(error.data) print_to_builder(*builder, "Error data: %\n", error.data);
    if context.stack_trace {
      append(*builder, "Stack trace:");
      node := context.stack_trace;
      while node {
        if node.info {
          print_to_builder(*builder, "\n%:%: %",
            node.info.location.fully_pathed_filename,
            node.line_number,
            ifx node.info.name else "(anonymous procedure)");
        }
        node = node.next;
      }
    }
    __runtime_support_disable_stack_trace = true;
    rpc_debug_log(builder_to_string(*builder));
    
    if !thread_state.request || !thread_state.request.is_notification
      add_response(Any.{}, Any.{type_info(JSON_RPC_Error), xx error});
    
    free_casted_json(*thread_state.result);
    free_casted_json(*thread_state.request);
  // }
  
  rpc_debug_log("Exiting");
  thread_deinit(thread_state.thread);
  return true;
}

#import "Thread";