JSON_RPC_Error_Code :: enum {
  UNKNOWN            :: -32001;
  NOT_INITIALIZED    :: -32002;
  INVALID_REQUEST    :: -32600;
  METHOD_NOT_FOUND   :: -32601;
  INVALID_PARAMETERS :: -32602;
  INTERNAL_ERROR     :: -32603;
  PARSE_ERROR        :: -32700;
  REQUEST_CANCELLED  :: -32800;
  CONTENT_MODIFED    :: -32801;
  SERVER_CANCELLED   :: -32802;
  REQUEST_FAILED     :: -32803;
}

JSON_RPC_Send_Response :: #type (data: *void, response: string);
JSON_RPC_Read_Request :: #type (data: *void) -> request: string;
JSON_RPC_Debug_Log :: #type (data: *void, message: string);
JSON_RPC_Method :: #type (data: *void, params: *JSON_Element) -> result: *JSON_Element;

initialize_rpc :: (data: *void, methods: Table(string, JSON_RPC_Method), read_request: JSON_RPC_Read_Request, send_response: JSON_RPC_Send_Response, debug_log: JSON_RPC_Debug_Log = dummy_debug_log) {
  init(*_state.mutex);
  _state.data = data;
  _state.methods = methods;
  _state.read_request = read_request;
  _state.send_response = send_response;
  _state.debug_log = debug_log;
  context.json_rpc.assertion_code = .INTERNAL_ERROR;
  context.json_rpc.state = *_state;
  
  rpc_debug_log("JSON-RPC Initialized");
}

deinitialize_rpc :: () {
  destroy(*_state.mutex);
  array_free(_state.threads);
  array_free(_state.requests);
  array_free(_state.responses);
}

rpc_read_and_respond :: () {
  // We're using threads here so that they can exit without terminating the program
  
  new_context := context;
  new_context.assertion_failed = assert_rpc;
  push_context new_context {
    state := context.json_rpc.state;
    state.is_batch = false;
    
    rpc_debug_log("Launching parse thread");
    thread: Thread;
    thread.starting_context = context;
    thread_init(*thread, parse_threaded_rpc_request);
    thread_start(*thread);
    thread_is_done(*thread, -1);
    thread_deinit(*thread);
    
    count := state.requests.count;
    for 1..count
      start_rpc_request_thread();
    for * state.threads
      thread_is_done(it, -1);
    for * state.threads
      thread_deinit(it);
    state.threads.count = 0;
    rpc_debug_log("All handling threads complete");
    
    send_response();
  }
}

rpc_debug_log :: (message: string, args: ..Any) {
  state := context.json_rpc.state;
  lock(*state.mutex);
  state.debug_log(state.data, tprint("[Thread %] %\n", context.thread_index, tprint(message, ..args)));
  unlock(*state.mutex);
}

#scope_file

JSON_RPC_Error :: struct {
  code: JSON_RPC_Error_Code;
  message: string;
  data: *JSON_Element;
}

JSON_RPC :: struct {
  mutex: Mutex;
  requests: [..] *JSON_Element;
  responses: [..] *JSON_Element;
  is_batch: bool;
  
  // Not mutexed
  data: *void;
  threads: [..] Thread;
  methods: Table(string, JSON_RPC_Method);
  read_request: JSON_RPC_Read_Request;
  send_response: JSON_RPC_Send_Response;
  debug_log: JSON_RPC_Debug_Log;
}

JSON_RPC_Thread :: struct {
  state: *JSON_RPC;
  
  send_on_exit: bool = true;
  request: *JSON_Object;
  assertion_code: JSON_RPC_Error_Code;
}

_state: JSON_RPC;
#add_context json_rpc: JSON_RPC_Thread;

dummy_debug_log : JSON_RPC_Debug_Log : (data: *void, message: string) { }

send_response :: () {
  state := context.json_rpc.state;
  
  assert(!state.requests.count, "% requests were not handled before sending the response", state.requests.count);
  
  response: *JSON_Element = null;
  if state.responses.count {
    if state.is_batch {
      response = make_array(state.responses);
    } else if state.responses.count > 1 {
      // It'll loop around and report a single error
      state.responses.count = 0;
      context.json_rpc.assertion_code = .INTERNAL_ERROR;
      assert(false, "Attempted to send multiple responses, but the request was not a batch");
    } else {
      response = state.responses[0];
    }
    
    // We sent them, so clear them out
    state.responses.count = 0;
  }
  
  rpc_debug_log("Response content:\n%", print_json(response,, temp));
  state.send_response(state.data, print_json(response,, temp));
  
  free_json(response);
}

start_rpc_request_thread :: () {
  rpc_debug_log("Launching handling thread");
  
  thread_state := *context.json_rpc;
  state := thread_state.state;
  
  thread := array_add(*state.threads);
  thread.starting_context = context;
  thread.starting_context.json_rpc.send_on_exit = false;
  
  thread_init(thread, handle_threaded_rpc_request);
  thread_start(thread);
}

assert_rpc :: (loc: Source_Code_Location, message: string) -> bool {
  thread_state := *context.json_rpc;
  state := thread_state.state;
  
  jsonrpc, method, id : *JSON_Element = null;
  request := thread_state.request;
  if request {
    jsonrpc = as_string(get_element(request, "jsonrpc"));
    method = get_element(request, "method");
    id = get_element(request, "id");
  } else {
    // Default to 2.0
    jsonrpc = make_string("2.0",,temp);
    id = make_null(,,temp);
  }
  
  error: JSON_RPC_Error;
  error.code = thread_state.assertion_code;
  error.data = ifx message then make_string(message,,temp) else null;
  
  if #complete thread_state.assertion_code == {
    case .NOT_INITIALIZED; error.message = "The server is not yet initialized.";
    case .INVALID_REQUEST; error.message = "The provided request is not valid.";
    case .METHOD_NOT_FOUND; error.message = tprint("Could not find the method '%'.", print_json(method,,temp));
    case .INVALID_PARAMETERS; error.message = "The provided parameters are invalid.";
    case .INTERNAL_ERROR; error.message = "Encountered an internal JSON-RPC error.";
    case .PARSE_ERROR; error.message = "Encountered an error while parsing the request.";
    case .REQUEST_CANCELLED; error.message = "Detected that the client cancelled the request.";
    case .CONTENT_MODIFED; error.message = "The content of the document was modified outside normal conditions.";
    case .SERVER_CANCELLED; error.message = "The server cancelled the request.";
    case .REQUEST_FAILED; error.message = "The request failed.";
    case .UNKNOWN; #through;
    case; error.message = "Unknown error occurred.";
  }
  
  builder: String_Builder;
  init_string_builder(*builder,, temp);
  print_to_builder(*builder, "%:%,%: Assertion failed: [%] %\n",
    loc.fully_pathed_filename,
    loc.line_number,
    loc.character_number,
    error.code,
    error.message);
  if message print_to_builder(*builder, "Cause: %\n", message);
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
  
  set_response(xx jsonrpc, id, null, error, true);
  
  if thread_state.send_on_exit {
    lock(*state.mutex);
    send_response();
    unlock(*state.mutex);
  }
  
  if request free_json(request);
  
  rpc_debug_log("Exiting");
  return true;
}

parse_threaded_rpc_request : Thread_Proc : (thread: *Thread) -> s64 {
  rpc_debug_log("Starting '%'", #procedure_name());
  
  thread_state := *context.json_rpc;
  state := thread_state.state;
  
  thread_state.assertion_code = .PARSE_ERROR;
  content := state.read_request(state.data);
  request := parse_json(content);
  free(content);
  rpc_debug_log("Request content:\n%", print_json(request,, temp));
  
  thread_state.assertion_code = .INVALID_REQUEST;
  if request.kind == .ARRAY {
    for as_array(request).value {
      assert(it.kind == .OBJECT, "A json-rpc request must be an object, but got %", print_json(it,, temp));
      jsonrpc := get_element(as_object(it), "jsonrpc");
      assert(xx jsonrpc, "Batch requests are not defined for json-rpc 1.0");
    }
    
    // Make sure we don't add anything until after validating everything
    for as_array(request).value
      array_add(*state.requests, it);
    
    state.is_batch = true;
  } else {
    assert(request.kind == .OBJECT, "A json-rpc request must be an object or array, but got %", print_json(request,, temp));
    array_add(*state.requests, request);
  }
  rpc_debug_log("Requests are valid");
  
  rpc_debug_log("Exiting");
  return 0;
}

handle_threaded_rpc_request : Thread_Proc : (thread: *Thread) -> s64 {
  rpc_debug_log("Starting '%'", #procedure_name());
  
  thread_state := *context.json_rpc;
  state := thread_state.state;
  thread_state.assertion_code = .INTERNAL_ERROR;
  
  lock(*state.mutex);
  request := as_object(state.requests[state.requests.count - 1]);
  state.requests.count -= 1;
  thread_state.request = request;
  unlock(*state.mutex);
  rpc_debug_log("Obtained request:\n%", print_json(request,, temp));
  
  thread_state.assertion_code = .INVALID_REQUEST;
  
  jsonrpc := as_string(get_element(request, "jsonrpc"));
  method := as_string(get_element(request, "method"));
  params := get_element(request, "params");
  id := get_element(request, "id");
  
  assert(!jsonrpc || jsonrpc.kind == .STRING && jsonrpc.value == "2.0", "jsonrpc must not exist for version 1, or equal \"2.0\" for version 2, but it was %", print_json(jsonrpc,, temp));
  assert(method && method.kind == .STRING, "method must be a String, but was %", print_json(method,, temp));
  if !jsonrpc {
    assert(!params || params.kind == .ARRAY, "params must be an Array, but was %", print_json(params,, temp));
    assert(xx id, "id must exist, but was not found");
  } else if jsonrpc.value == "2.0" {
    assert(!params || params.kind == .ARRAY || params.kind == .OBJECT, "params must be an Array or Object, but was %", print_json(params,, temp));
    assert(!id || id.kind == .NULL || id.kind == .NUMBER || id.kind == .STRING, "id must be a Null, Number, or String, but was %", print_json(id,, temp));
  }
  rpc_debug_log("Request validated");
  
  thread_state.assertion_code = .METHOD_NOT_FOUND;
  func, success := table_find(*state.methods, method.value);
  assert(success);
  rpc_debug_log("Found %", method.value);
  
  if params 
    rpc_debug_log("Calling '%' with params:\n%", method.value, print_json(params,, temp));
  else
    rpc_debug_log("Calling '%' with no params", method.value);
  thread_state.assertion_code = .INTERNAL_ERROR;
  result := func(state.data, params);
  thread_state.assertion_code = .REQUEST_FAILED;
  assert(xx result, "JSON-RPC methods must return a result, but % returned null", method.value);
  rpc_debug_log("Completed '%' with result:\n%", method.value, print_json(result,, temp));
  
  set_response(jsonrpc, id, result, .{}, false);
  free_json(request);
  
  rpc_debug_log("Exiting");
  return 0;
}

set_response :: (jsonrpc: *JSON_String, id: *JSON_Element, result: *JSON_Element, error: JSON_RPC_Error, has_error: bool) {
  state := context.json_rpc.state;
  
  json_error: *JSON_Object = null;
  if has_error {
    json_error = make_object();
    set_element(json_error, "code", make_number(xx error.code));
    set_element(json_error, "message", make_string(error.message));
    set_element(json_error, "data", error.data);
  }
  
  if (!jsonrpc && id.kind == .NULL)
  || jsonrpc.value == "2.0" && !id
    return;
  
  lock(*state.mutex);
  response: **JSON_Object = xx array_add(*context.json_rpc.state.responses);
  unlock(*state.mutex);
  
  response.* = make_object();
  set_element(response.*, "id", copy_json(id));
  if !jsonrpc {
    set_element(response.*, "result", ifx cast(*JSON_Element) result else xx make_null());
    set_element(response.*, "error", ifx cast(*JSON_Element) json_error else xx make_null());
  } else if jsonrpc.value == "2.0" {
    set_element(response.*, "jsonrpc", copy_json(jsonrpc));
    set_element(response.*, "result", result);
    set_element(response.*, "error", json_error);
  }
}

#import "Thread";