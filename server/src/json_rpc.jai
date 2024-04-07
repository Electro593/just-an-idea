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

JSON_RPC_Error :: struct {
  code: JSON_RPC_Error_Code;
  message: string;
  data: *JSON_Element;
}

JSON_RPC_Method :: #type (params: *JSON_Element) -> (result: *JSON_Element, error: JSON_RPC_Error, has_error: bool);

handle_rpc_request :: (methods: Table(string, JSON_RPC_Method), message: *JSON_Element) -> *JSON_Element {
  if message.kind == .ARRAY {
    requests := as_array(message);
    _responses: [..]*JSON_Element;
    responses := make_array(_responses);
    for < requests.value
      set_element(responses, it_index, handle_rpc_request(methods, as_object(it)));
    return responses;
  } else {
    return handle_rpc_request(methods, as_object(message));
  }
}

#scope_file

handle_rpc_request :: (methods: Table(string, JSON_RPC_Method), message: *JSON_Object) -> *JSON_Object {
  jsonrpc := as_string(get_element(message, "jsonrpc"));
  method := as_string(get_element(message, "method")).value;
  params := get_element(message, "params");
  id := get_element(message, "id");
  
  method_pointer, success := table_find(*methods, method);
  if !success return make_response(jsonrpc, id, null, .{.METHOD_NOT_FOUND, tprint("Could not find the method %", method), null}, true);
  
  result, error, has_error := method_pointer(params);
  return make_response(jsonrpc, id, result, error, has_error);
}

make_response :: (jsonrpc: *JSON_String, id: *JSON_Element, result: *JSON_Element, error: JSON_RPC_Error, has_error: bool) -> *JSON_Object {
  json_error: *JSON_Object = null;
  if has_error {
    json_error = make_object(.{});
    set_element(json_error, "code", make_number(xx error.code));
    set_element(json_error, "message", make_string(error.message));
    set_element(json_error, "data", error.data);
  }
  
  if jsonrpc && jsonrpc.value == "2.0" {
    if !id return null;
    response := make_object(.{});
    set_element(response, "jsonrpc", jsonrpc);
    set_element(response, "id", id);
    set_element(response, "result", result);
    set_element(response, "error", json_error);
    return response;
  } else {
    if id.kind == .NULL return null;
    response := make_object(.{});
    set_element(response, "id", id);
    set_element(response, "result", ifx cast(*JSON_Element) result else xx make_null());
    set_element(response, "error", ifx cast(*JSON_Element) json_error else xx make_null());
    return response;
  }
}