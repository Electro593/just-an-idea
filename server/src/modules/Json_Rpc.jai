#module_parameters (SCOPE: Code) ();

/* TODO:
 - Validate memory is freed on assert
 - Add server->client requests
 - More mutexes
 - Change log to use context in Cast_Json
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
  state.next_id = 1;
  state.next_batch_id = 1;

  set_error(.INTERNAL_ERROR);
  state.is_initialized = true;

  rpc_debug_log("JSON-RPC Initialized");
}

start_rpc :: () {
  state := context.json_rpc.state;

  worker_thread_count :: 1;
  for 0..worker_thread_count array_add(*state.threads, .{});

  while state.is_initialized {
    for * state.threads
      if !it.index
        start_rpc_thread(ifx it_index then threaded_rpc_handler_loop else threaded_rpc_parse_loop, it, it_index);
    sleep_milliseconds(100);
  }

  for * state.threads thread_is_done(it, -1);
  for * state.threads thread_deinit(it);
  array_free(state.threads);

  for * state.requests_to_handle  free_casted_json(it);
  for * state.responses_to_handle free_casted_json(it);
  for * state.requests_to_send    free_casted_json(it);
  for * state.responses_to_send   free_casted_json(it);
  array_free(state.requests_to_handle);
  array_free(state.responses_to_handle);
  array_free(state.requests_to_send);
  deinit(*state.responses_to_send);

  deinit(*state.request_methods);
  // deinit(*state.response_methods);
  // deinit(*state.response_names);
}

add_rpc_request_handler :: (name: string, method: (data: *$D, params: *$P) -> $R) #expand {
  caster :: (proc: (data: *D, params: *P) -> R, params: *Any) -> Any {
    json_params := cast_any(params.*, JSON_Element);
    casted_params: *P = alloc(size_of(P));
    params.type = type_info(P);
    params.value_pointer = casted_params;
    cast_json(json_params, casted_params, scope = SCOPE);
    free_json(json_params);

    result := proc(xx context.json_rpc.state.data, casted_params);
    return alloc_any(result);
  }
  add_rpc_method(name, xx caster, xx method);
}

add_rpc_request_handler :: (name: string, method: (data: *$D, params: *$P)) #expand {
  caster :: (proc: (data: *D, params: *P), params: *Any) -> Any {
    json_params := cast_any(params.*, JSON_Element);
    casted_params: *P = alloc(size_of(P));
    params.type = type_info(P);
    params.value_pointer = casted_params;
    cast_json(json_params, casted_params, scope = SCOPE);
    free_json(json_params);

    proc(xx context.json_rpc.state.data, casted_params);
    return make_null_any();
  }
  add_rpc_method(name, xx caster, xx method);
}

add_rpc_request_handler :: (name: string, method: (data: *$D) -> $R) #expand {
  caster :: (proc: (data: *D) -> R, params: *Any) -> Any {
    result := proc(xx context.json_rpc.state.data);
    return alloc_any(result);
  }
  add_rpc_method(name, xx caster, xx method);
}

add_rpc_request_handler :: (name: string, method: (data: *$D)) #expand {
  caster :: (proc: (data: *D), params: *Any) -> Any {
    proc(xx context.json_rpc.state.data);
    return make_null_any();
  }
  add_rpc_method(name, xx caster, xx method);
}

// add_rpc_response_handler :: (name: string, success_proc: (data: *$D, result: $R), error_proc: (data: *D, code: JSON_RPC_Error_Code, message: string, error_data: $E)) {
//   success_caster :: (proc: (data: *D, result: R), result: *Any) {
//     json_params := cast_any(params.*, JSON_Element);
//     casted_params: *P = alloc(size_of(P));
//     params.type = type_info(P);
//     params.value_pointer = casted_params;
//     cast_json(json_params, casted_params, scope = SCOPE);
//     free_json(json_params);
//     rpc_debug_log("Params:\n%", casted_params.*);

//     proc(xx context.json_rpc.state.data);
//   }
//   error_caster :: (proc: (data: *D), params: *Any) -> Any {
//     proc(xx context.json_rpc.state.data);
//     return make_null_any();
//   }
// }

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

add_request_to_batch :: (method: string, params: Any = Any.{}, is_notification := false, version := DEFAULT_JSON_RPC_VERSION) {
  push_error(.INTERNAL_ERROR);
  state := context.json_rpc.state;

  request := JSON_RPC_Request.{
    jsonrpc = copy_string(version),
    method = copy_string(method),
    params = copy_casted_json(params),
    is_notification = is_notification
  };
  if !is_notification request.id = alloc_any(get_next_id());

  lock(*state.mutex);
  array_add(*state.requests_to_send, request);
  unlock(*state.mutex);

  rpc_debug_log("Added '%' (id %) to the batch, with params:\n%", method, request.id, params);
}

send_all_requests :: () {
  push_error(.INTERNAL_ERROR);
  state := context.json_rpc.state;

  if !state.requests_to_send.count return;

  rpc_debug_log("Queueing requests to send");
  batch: JSON_RPC_Batch_Request = .{Any.{type_info(JSON_RPC_Requests), *state.requests_to_send}, 0};
  json := cast_json(batch, log = rpc_debug_log,, temp);
  for * state.requests_to_send {
    free_casted_json(it);
    remove it;
  }
  message := print_json(json,, temp);
  rpc_debug_log("Sending requests:\n%", message);

  lock(*state.mutex);
  state.send_message(*state.data, message);
  unlock(*state.mutex);
}

rpc_debug_log :: (format_string: string, args: ..Any, to_standard_error := false) -> bytes_printed: s64 {
  state := context.json_rpc.state;
  lock(*state.mutex);
  defer unlock(*state.mutex);
  return state.debug_log(state.data, tprint("[Thread %] %\n", context.thread_index, tprint(format_string, ..args)));
}

DEFAULT_JSON_RPC_VERSION :: "2.0";

JSON_RPC_Message :: struct {
  _: Any; @JSON_RPC_Batch_Request @JSON_RPC_Batch_Response
}

JSON_RPC_Message_Header :: struct {
  jsonrpc: string; @?
}

JSON_RPC_Requests :: [..] JSON_RPC_Request;
JSON_RPC_Request :: struct {
  #as using _: JSON_RPC_Message_Header;
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
  #as using _: JSON_RPC_Message_Header;
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

JSON_RPC_Caster :: #type (proc: *void, params: *Any) -> Any;
JSON_RPC_Caster_Data :: struct {
  caster: JSON_RPC_Caster;
  proc: *void;
}
// JSON_RPC_Response_Handling_Data :: struct {
//   JSON_RPC_Caster_Data: success_proc;
//   JSON_RPC_Caster_Data: error_proc;
// }

JSON_RPC :: struct {
  mutex: Mutex;

  requests_to_handle: [..] JSON_RPC_Request;
  responses_to_handle: [..] JSON_RPC_Batch_Response;

  requests_to_send: [..] JSON_RPC_Request;
  responses_to_send: Table(int, JSON_RPC_Batch_Response);

  next_id: s32;
  next_batch_id: s32;
  is_initialized: bool;

  threads: [..] Thread;

  request_methods: Table(string, JSON_RPC_Caster_Data);
  // response_methods: Table(string, JSON_RPC_Response_Handling_Data);
  // response_names: Table(s32, string);

  data: *void;
  read_message: JSON_RPC_Read_Message;
  send_message: JSON_RPC_Send_Message;
  debug_log: JSON_RPC_Debug_Log;
}

JSON_RPC_Thread :: struct {
  state: *JSON_RPC;

  thread: *Thread;
  threads_index: int;

  batch_id: s32;
  result: Any;
  message: JSON_RPC_Message;
  request: JSON_RPC_Request;
  response: JSON_RPC_Response;

  assertion_code: JSON_RPC_Error_Code;
  assertion_data: Any;
}

#scope_file

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
  table_set(*state.request_methods, name, .{xx caster, xx method});
  unlock(*state.mutex);
  rpc_debug_log("Added '%'", name);
}

start_rpc_thread :: (proc: Thread_Proc, thread: *Thread = null, index := 0) {
  state := context.json_rpc.state;

  if !thread {
    lock(*state.mutex);
    index = state.threads.count;
    thread = array_add(*state.threads);
    unlock(*state.mutex);
  }

  thread.starting_context = context;
  // thread.starting_context.print_style.default_format_struct = FormatStruct.{use_long_form_if_more_than_this_many_members = -1, use_newlines_if_long_form = true, indentation_width = 2};
  thread.starting_context.json_rpc.thread = thread;
  thread.starting_context.json_rpc.threads_index = index;
  thread.starting_context.json_rpc.assertion_data = make_undef_any();
  thread.starting_context.json_rpc.assertion_code = .INTERNAL_ERROR;

  thread_init(thread, proc);
  rpc_debug_log("Launching thread %", thread.index);
  thread_start(thread);
}

threaded_rpc_parse_loop : Thread_Proc : (thread: *Thread) -> s64 {
  context.assertion_failed = assert_rpc;

  thread_state := *context.json_rpc;
  state := thread_state.state;
  set_error(.INTERNAL_ERROR);
  rpc_debug_log("Starting the JSON-RPC main loop");

  parse_message :: () {
    push_error(.PARSE_ERROR);
    thread_state := *context.json_rpc;
    state := thread_state.state;
    rpc_debug_log("Looking for a message");
    content := state.read_message(state.data);
    json_message := parse_json(content,, temp);
    rpc_debug_log("Parsed message content:\n%", print_json(json_message,, temp));
    thread_state.message = cast_json(json_message, JSON_RPC_Message);
    rpc_debug_log("Casted the message into:\n%", thread_state.message);
  }

  validate_and_add_requests :: () {
    push_error(.INVALID_REQUEST);
    thread_state := *context.json_rpc;
    state := thread_state.state;

    validate_and_add_request :: (using request: *JSON_RPC_Request) {
      thread_state := *context.json_rpc;
      state := thread_state.state;
      assert(!jsonrpc || jsonrpc == "2.0", "jsonrpc must be either missing for version 1.0, or '2.0' for version 2.0, but it was %", jsonrpc);
      assert(jsonrpc || !is_any_undef(id), "id must be present for JSON-RPC 1.0");
      batch_id = thread_state.batch_id;
      is_notification = (jsonrpc && is_any_undef(id)) || (!jsonrpc && get_any_type(id).type == .VOID);
      thread_state.request = request.*;
      lock(*state.mutex);
      array_add(*state.requests_to_handle, request.*);
      unlock(*state.mutex);
    }

    thread_state.batch_id = get_next_batch_id();
    batch := cast_any(thread_state.message._, JSON_RPC_Batch_Request);

    if is_any_of_type(batch._, JSON_RPC_Requests) {
      requests := cast_any(batch._, JSON_RPC_Requests);
      count := requests.count;
      for requests.* {
        assert(xx it.jsonrpc, "Batch requests are only defined for json-rpc 2.0 and up");
        remove it;
        validate_and_add_request(*it);
      }

      lock(*state.mutex);
      _responses: JSON_RPC_Responses;
      responses := find_or_add(*state.responses_to_send, thread_state.batch_id);
      responses._ = alloc_any(JSON_RPC_Responses.{});
      responses.count_remaining = count;
      cast_any(responses._, JSON_RPC_Responses).* = _responses;
      unlock(*state.mutex);
    } else {
      request := cast_any(batch._, JSON_RPC_Request);
      // Prevent freeing the batch from freeing copied pointers, since an Any of void will only free the value_pointer
      batch._.type = type_info(void);
      validate_and_add_request(request);
    }

    rpc_debug_log("Validated the request");
  }

  validate_and_add_responses :: () {
  //   push_error(.INVALID_RESPONSE);
  //   state := context.json_rpc.state;

  //   builder: String_Builder;
  //   init_string_builder(*builder,, temp);
  //   append(*builder, "Casted the message into:");

  //   lock(*state.mutex);
  //   batch := array_add(*state.responses_to_handle);
  //   unlock(*state.mutex);
  //   cast_json(message, batch);

  //   count: int;
  //   if is_any_of_type(batch._, JSON_RPC_Responses) {
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

  //   lock(*state.mutex);
  //   batch.count_remaining = count;
  //   unlock(*state.mutex);

  //   rpc_debug_log("Validated the response");
  }

  while state.is_initialized {
    thread_state.batch_id = 0;
    parse_message();

    if thread_state.message._.type == type_info(JSON_RPC_Batch_Request)
      validate_and_add_requests();
    else
      validate_and_add_responses();

    free_casted_json(*thread_state.message);

    reset_temporary_storage();
  }

  return 0;
}

threaded_rpc_handler_loop : Thread_Proc : (thread: *Thread) -> s64 {
  context.assertion_failed = assert_rpc;

  thread_state := *context.json_rpc;
  state := thread_state.state;
  set_error(.INTERNAL_ERROR);
  rpc_debug_log("Starting a JSON-RPC worker loop");

  retrieve_task :: (index: int) {
    thread_state := *context.json_rpc;
    state := thread_state.state;
    push_error(.INTERNAL_ERROR);
    rpc_debug_log("Looking for tasks");
    lock(*state.mutex);
    // while !state.responses_to_handle.count && !state.requests_to_handle.count {
    while !state.requests_to_handle.count {
      unlock(*state.mutex);
      sleep_milliseconds(100);
      lock(*state.mutex);
    }
    // is_response := ((i % 2) || !state.requests_to_handle.count) && state.responses_to_handle.count;
    // if is_response {
    //   for * state.responses_to_handle {
    //     if !it.count_remaining continue;
    //     if is_any_of_type(it._, JSON_RPC_Responses) {
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
      thread_state.request = state.requests_to_handle[0];
      array_unordered_remove_by_index(*state.requests_to_handle, 0);
      unlock(*state.mutex);
      thread_state.batch_id = thread_state.request.batch_id;
      rpc_debug_log("Obtained request:\n%", thread_state.request);
    // }
  }

  retrieve_method :: () -> name: string, method: JSON_RPC_Caster_Data {
    rpc_debug_log("Retrieving method...");
    thread_state := *context.json_rpc;
    state := thread_state.state;
    push_error(.METHOD_NOT_FOUND);
    name: string;
    method: JSON_RPC_Caster_Data;
    // if thread_state.request {
      name = thread_state.request.method;
      success, method= := table_find(*state.request_methods, name);
      assert(success);
      rpc_debug_log("Found '%'", name);
      return name, method;
    // } else {
    //   assert(false);
    //   return "", .{};
    // }
  }

  call_method :: (name: string, method: JSON_RPC_Caster_Data) {
    thread_state := *context.json_rpc;
    state := thread_state.state;
    push_error(.INTERNAL_ERROR);
    // if thread_state.request {
      params := *thread_state.request.params;
      rpc_debug_log("Calling '%'", name);
      set_error_data();
      thread_state.result = method.caster(method.proc, params);
      set_error(.REQUEST_FAILED);
      assert(!is_any_undef(thread_state.result), "JSON-RPC methods must return a result, but % did not", name);
      rpc_debug_log("Completed '%' with result:\n%", name, thread_state.result);
    // } else {
    //   assert(false);
    //   return .{};
    // }
  }

  send_ready_responses :: () {
    push_error(.INTERNAL_ERROR);
    state := context.json_rpc.state;

    builder: String_Builder;
    init_string_builder(*builder,, temp);
    append(*builder, "Sending the responses:");
    something_was_sent := false;

    lock(*state.mutex);
    for * state.responses_to_send {
      if it.count_remaining > 0 continue;
      response := it.*;
      json := cast_json(response,, temp);
      free_casted_json(*response);
      remove it;
      printed_json := print_json(json,, temp);
      print_to_builder(*builder, "\n%", printed_json);
      state.send_message(state.data, printed_json);
      something_was_sent = true;
    }
    unlock(*state.mutex);

    if something_was_sent
      rpc_debug_log(builder_to_string(*builder));
  }

  i := 0;
  while state.is_initialized {
    thread_state.batch_id = 0;
    defer i += 1;

    retrieve_task(i);
    name, method := retrieve_method();
    call_method(name, method);

    add_response(thread_state.result, make_undef_any());
    thread_state.result = make_undef_any();

    free_casted_json(*thread_state.request);
    // free_casted_json(*thread_state.response);

    send_ready_responses();
    send_all_requests();

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
  if is_any_of_type(batch._, JSON_RPC_Responses) {
    responses := cast_any(batch._, JSON_RPC_Responses);
    response_ptr := array_add(responses);
    response_ptr.* = alloc(size_of(JSON_RPC_Response));
    response = response_ptr.*;
  } else {
    if new batch.* = .{alloc_any(JSON_RPC_Response.{}), 1};
    response = cast_any(batch._, JSON_RPC_Response);
  }
  response.jsonrpc = copy_casted_json(thread_state.request.jsonrpc);
  response.id = copy_casted_json(thread_state.request.id);
  response.result = ifx !is_any_undef(result) then result else ifx response.jsonrpc then make_undef_any() else make_null_any();
  response.error  = ifx !is_any_undef(error)  then error  else ifx response.jsonrpc then make_undef_any() else make_null_any();
  batch.count_remaining -= 1;
}

assert_rpc :: (loc: Source_Code_Location, message: string) -> bool {
  rpc_debug_log("Asserting!");

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
    if !is_any_undef(error.data) print_to_builder(*builder, "Error data: %\n", error.data);
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

    if !thread_state.batch_id || !thread_state.request.is_notification
      add_response(make_undef_any(), Any.{type_info(JSON_RPC_Error), xx error});

    free_casted_json(*thread_state.result);
    free_casted_json(*thread_state.request);
  // }

  free_casted_json(*thread_state.message);

  rpc_debug_log("Exiting");
  thread_deinit(thread_state.thread);
  #if OS == .WINDOWS {
    kernel32 :: #system_library "kernel32";
    ExitThread :: (exit_code: u32) #foreign kernel32;
    ExitThread(1);
  }
  while true {
    sleep_milliseconds(1000);
    rpc_debug_log("Still alive...");
  }
  return true;
}

#import "Basic";
#import "Cast_Json" (SHOULD_LOG = true);
#import "Hash_Table";
#import "Json";
#import "Thread";
