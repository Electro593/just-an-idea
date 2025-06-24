JSON_Element :: struct {
  kind: enum {
    NULL;
    BOOLEAN;
    NUMBER;
    STRING;
    ARRAY;
    OBJECT;
  }
}

JSON_Null :: struct {
  #as using _: JSON_Element;
  kind = .NULL;
}

JSON_Boolean :: struct {
  #as using _: JSON_Element;
  kind = .BOOLEAN;
  value: bool;
}

JSON_Number :: struct {
  #as using _: JSON_Element;
  kind = .NUMBER;
  value: float64;
}

JSON_String :: struct {
  #as using _: JSON_Element;
  kind = .STRING;
  value: string;
}

JSON_Array :: struct {
  #as using _: JSON_Element;
  kind = .ARRAY;
  value: [..] *JSON_Element;
}

JSON_Object :: struct {
  #as using _: JSON_Element;
  kind = .OBJECT;
  value: Table(string, *JSON_Element);
}

parse_json :: (text: string) -> *JSON_Element {
  json: JSON = .{
    data = text.data,
    index = 0,
    count = text.count
  };
  
  return parse_json(*json);
}

copy_json :: (element: *JSON_Element) -> *JSON_Element {
  if !element return null;
  
  if #complete element.kind == {
    case .NULL; return make_null();
    case .BOOLEAN; return make_boolean(as_boolean(element).value);
    case .NUMBER; return make_number(as_number(element).value);
    case .STRING; return make_string(copy_string(as_string(element).value));
    
    case .ARRAY;
      array := make_array();
      for as_array(element).value
        array_add(*array.value, copy_json(it));
      return array;
      
    case .OBJECT;
      object := make_object();
      for as_object(element).value
        table_add(*object.value, copy_string(it_index), copy_json(it));
      return object;
  }
}

free_json :: (element: *JSON_Element) {
  if !element return;
  
  if #complete element.kind == {
    case .NULL;
    case .BOOLEAN;
    case .NUMBER;
    
    case .STRING;
      elem := as_string(element);
      free(elem.value);
    
    case .ARRAY;
      elem := as_array(element);
      for elem.value free_json(it);
      array_free(elem.value);
      
    case .OBJECT;
      elem := as_object(element);
      for elem.value {
        free_json(it);
        free(it_index);
      }
      deinit(*elem.value);
  }
  free(element);
}

get_element :: inline (object: *JSON_Object, name: string, default := null) -> *JSON_Element {
  assert(xx object, "Attempted to get \"%\" from an object, but the object was null", name);
  success, value := table_find_new(*object.value, name);
  if !success then value = default;
  return value;
}

get_element :: inline (array: *JSON_Array, index: int, default := null) -> *JSON_Element {
  assert(xx array, "Attempted to get index % from an array, but the array was null", index);
  assert(index >= 0, "Attempted to get index % from an array, but the index is less than 0", index);
  if index >= array.value.count then return default;
  return array.value[index];
}

as_null :: inline (element: *JSON_Element) -> *JSON_String {
  if element assert(element.kind == .NULL, "Attempted to interpret a % as a null", element.kind);
  return xx element;
}

as_boolean :: inline (element: *JSON_Element) -> *JSON_Boolean {
  if element assert(element.kind == .BOOLEAN, "Attempted to interpret a % as a boolean", element.kind);
  return xx element;
}

as_number :: inline (element: *JSON_Element) -> *JSON_Number {
  if element assert(element.kind == .NUMBER, "Attempted to interpret a % as a number", element.kind);
  return xx element;
}

as_string :: inline (element: *JSON_Element) -> *JSON_String {
  if element assert(element.kind == .STRING, "Attempted to interpret a % as a string", element.kind);
  return xx element;
}

as_array :: inline (element: *JSON_Element) -> *JSON_Array {
  if element assert(element.kind == .ARRAY, "Attempted to interpret a % as an array", element.kind);
  return xx element;
}

as_object :: inline (element: *JSON_Element) -> *JSON_Object {
  if element assert(element.kind == .OBJECT, "Attempted to interpret a % as an object", element.kind);
  return xx element;
}

make_null :: inline () -> *JSON_Null {
  elem: *JSON_Null = alloc(size_of(JSON_Null));
  elem.* = .{};
  return elem;
}

make_boolean :: inline (value: bool = false) -> *JSON_Boolean {
  elem: *JSON_Boolean = alloc(size_of(JSON_Boolean));
  elem.* = .{value = value};
  return elem;
}

make_number :: inline (value: float64 = 0) -> *JSON_Number {
  elem: *JSON_Number = alloc(size_of(JSON_Number));
  elem.* = .{value = value};
  return elem;
}

make_string :: inline (value: string = "") -> *JSON_String {
  elem: *JSON_String = alloc(size_of(JSON_String));
  elem.* = .{value = value};
  return elem;
}

make_array :: inline (value: [..]*JSON_Element) -> *JSON_Array {
  elem: *JSON_Array = alloc(size_of(JSON_Array));
  elem.* = .{value = value};
  return elem;
}

make_array :: inline () -> *JSON_Array {
  elem: *JSON_Array = alloc(size_of(JSON_Array));
  elem.* = .{};
  return elem;
}

make_object :: inline (value: Table(string, *JSON_Element) = .{}) -> *JSON_Object {
  elem: *JSON_Object = alloc(size_of(JSON_Object));
  elem.* = .{value = value};
  return elem;
}

set_element :: (object: *JSON_Object, name: string, element: *JSON_Element) {
  assert(xx object, "Attempting to set \"%\" to element, but the object is null", name, print_json(element,,temp));
  if element then table_set(*object.value, name, element);
}

set_element :: (array: *JSON_Array, index: int, element: *JSON_Element) {
  assert(xx array, "Attempting to set index % to %, but the array is null", index, print_json(element,,temp));
  if element {
    assert(index >= 0, "Attempting to set % at index % of %", print_json(element,,temp), index, print_json(array,,temp));
    if (index >= array.value.count)
      array_resize(*array.value, index + 1, true);
    array.value[index] = element;
  }
}

print_json :: (element: *JSON_Element) -> string {
  if !element return "";
  
  builder: String_Builder;
  init_string_builder(*builder);
  
  append_element :: (builder: *String_Builder, element: *JSON_Element) {
    if #complete element.kind == {
      case .NULL;
        append(builder, "null");
        
      case .BOOLEAN;
        append(builder, ifx as_boolean(element).value then "true" else "false");
      
      case .NUMBER;
        stb_print_float(builder, .{value = as_number(element).value});
      
      case .STRING;
        append(builder, "\"");
        str := as_string(element).value;
        i := 0;
        while i < str.count {
          defer i += 1;
          it := str.data[i];
          if it == {
            case #char "\""; append(builder, "\\\"");
            case #char "\\"; append(builder, "\\\\");
            case       0x08; append(builder, "\\b");
            case       0x0C; append(builder, "\\f");
            case #char "\n"; append(builder, "\\n");
            case #char "\r"; append(builder, "\\r");
            case #char "\t"; append(builder, "\\t");
            case;
              if it >= 0x20 && it <= 0x7F append(builder, string.{1, *it});
              else {
                codepoint := get_codepoint(string.{str.count-i, str.data+i});
                mapper :: "0123456789ABCDEF";
                if codepoint >= 0x10000 {
                  codepoint -= 0x10000;
                  high := 0xD800 | ((codepoint >> 10) & 0x3FF);
                  low  := 0xDC00 | ((codepoint >>  0) & 0x3FF);
                  print_to_builder(builder, "\\u%0%0%0%",
                    string.{1, mapper.data + ((high >> 12) & 0x0F)},
                    string.{1, mapper.data + ((high >>  8) & 0x0F)},
                    string.{1, mapper.data + ((high >>  4) & 0x0F)},
                    string.{1, mapper.data + ((high >>  0) & 0x0F)});
                  print_to_builder(builder, "\\u%0%0%0%",
                    string.{1, mapper.data + ((low >> 12) & 0x0F)},
                    string.{1, mapper.data + ((low >>  8) & 0x0F)},
                    string.{1, mapper.data + ((low >>  4) & 0x0F)},
                    string.{1, mapper.data + ((low >>  0) & 0x0F)});
                } else {
                  print_to_builder(builder, "\\u%0%0%0%",
                    string.{1, mapper.data + ((codepoint >> 12) & 0x0F)},
                    string.{1, mapper.data + ((codepoint >>  8) & 0x0F)},
                    string.{1, mapper.data + ((codepoint >>  4) & 0x0F)},
                    string.{1, mapper.data + ((codepoint >>  0) & 0x0F)});
                }
              }
          }
        }
        append(builder, "\"");
      
      case .ARRAY;
        append(builder, "[");
        array := as_array(element).value;
        for array {
          append_element(builder, it);
          if it_index < array.count - 1
            append(builder, ",");
        }
        append(builder, "]");
      
      case .OBJECT;
        append(builder, "{");
        object := as_object(element).value;
        i := 0;
        for object {
          append(builder, "\"");
          append(builder, it_index);
          append(builder, "\":");
          append_element(builder, it);
          if i < object.count - 1
            append(builder, ",");
          i += 1;
        }
        append(builder, "}");
    }
  }
  
  append_element(*builder, element);
  
  return builder_to_string(*builder);
}

#scope_file

JSON :: struct {
  count: s64;
  data: *u8;
  index: int;
}

Text_Encoding :: enum {
  INVALID;
  
  UTF_8;
  UTF_16_LE;
  UTF_16_BE;
  UTF_32_LE;
  UTF_32_BE;
}

validate_utf_8 :: (json: *JSON) {
  validate_continuation_byte :: (json: *JSON, byte: u32, base: int, index: int, count: int) {
    assert_syntax(base + index < count, json, "Expected continuation byte % of a UTF-8 character, but got EOF", index);
    assert_syntax((byte & 0xC0) == 0x80, json, "Expected continuation byte % of a UTF-8 character, but got %", index, byte);
  }
  
  assert_overlong :: (condition: bool, json: *JSON, codepoint: u32) {
    assert_syntax(condition, json, "Encountered an overlong UTF-8 character %", codepoint);
  }
  
  for 0 .. json.count - 1 {
    codepoint: u32;
    
    c0: u32 = ifx it+0 < json.count then json.data[it+0];
    c1: u32 = ifx it+1 < json.count then json.data[it+1];
    c2: u32 = ifx it+2 < json.count then json.data[it+2];
    c3: u32 = ifx it+3 < json.count then json.data[it+3];
    
    if c0 <= 0x7F {
      codepoint = c0;
    } else if c0 <= 0xDF {
      assert_syntax(c0 >= 0xC0, json, "Encountered a UTF-8 continuation byte in place of a character");
      validate_continuation_byte(json, c1, it, 1, json.count);
      codepoint = ((c0 & 0x1F) << 6) | (c1 & 0x3F);
      assert_overlong(codepoint < 0x80, json, codepoint);
    } else if c0 <= 0xEF {
      validate_continuation_byte(json, c1, it, 1, json.count);
      validate_continuation_byte(json, c2, it, 2, json.count);
      codepoint = ((c0 & 0x0F) << 12) | ((c1 & 0x3F) << 6) | (c2 & 0x3F);
      assert_overlong(codepoint < 0x800, json, codepoint);
    } else {
      assert_syntax(c0 <= 0xFD, json, "Encountered the UTF-8 encoding %, which is undefined", c0);
      validate_continuation_byte(json, c1, it, 1, json.count);
      validate_continuation_byte(json, c2, it, 2, json.count);
      validate_continuation_byte(json, c3, it, 3, json.count);
      codepoint = ((c0 & 0x07) << 18) | ((c1 & 0x3F) << 12) | ((c2 & 0x3F) << 6) | (c3 & 0x3F);
      assert_overlong(codepoint < 0x10000, json, codepoint);
      assert_syntax(codepoint <= 0x10FFFF, json, "Encountered the UTF-8 character %, which is too large", codepoint);
    }
    
    assert_syntax(codepoint < 0xD800 || codepoint > 0xDFFF, json, "Encountered the UTF-8 character %, which is a UTF-16 surrogate", codepoint);
  }
}

encode_utf_8 :: (codepoint: u32, out: *string, $should_assert: bool = true) {
  if codepoint <= 0x7F {
    out.data[out.count+0] = xx 0x7F & codepoint;
    out.count += 1;
  } else if codepoint <= 0x7FF {
    out.data[out.count+0] = xx 0xC0 | ((codepoint >> 6) & 0x1F);
    out.data[out.count+1] = xx 0x80 | (codepoint & 0x3F);
    out.count += 2;
  } else if codepoint <= 0xFFFF {
    #if should_assert assert(codepoint < 0xD800 || codepoint > 0xDFFF, "Encountered an invalid UTF-16 surrogate % while transcoding to UTF-8", codepoint);
    out.data[out.count+0] = xx 0xE0 | ((codepoint >> 12) & 0x0F);
    out.data[out.count+1] = xx 0x80 | ((codepoint >> 6) & 0x3F);
    out.data[out.count+2] = xx 0x80 | (codepoint & 0x3F);
    out.count += 3;
  } else {
    #if should_assert assert(codepoint <= 0x10FFFF, "Encountered an undefined encoding % while transcoding to UTF-8", codepoint);
    out.data[out.count+1] = xx 0x80 | ((codepoint >> 12) & 0x3F);
    out.data[out.count+0] = xx 0xF0 | ((codepoint >> 18) & 0x07);
    out.data[out.count+2] = xx 0x80 | ((codepoint >> 6) & 0x3F);
    out.data[out.count+3] = xx 0x80 | (codepoint & 0x3F);
    out.count += 4;
  }
}

process_utf_16 :: (json: *JSON, big_endian: bool) {
  assert_syntax(json.count % 2 == 0, json, "Determined the json stream's encoding to be UTF-16, but the number of bytes (%) was not a multiple of 2", json.count);
  
  // Make a copy since UTF-16 can be smaller than UTF-8 in some edge cases
  data16 := array_copy([]u16.{json.count / 2, xx json.data});
  defer array_free(data16);
  
  json.count = 0;
  
  //TODO: Assuming little-endian
  
  for 0 .. data16.count - 1 {
    codepoint: u32;
    
    c0: u32 = ifx it+0 < data16.count then data16[it+0];
    c1: u32 = ifx it+1 < data16.count then data16[it+1];
    
    if big_endian {
      c0 = byte_swap(cast(u16) c0);
      c1 = byte_swap(cast(u16) c1);
    }
    
    if c0 < 0xD800 || c0 > 0xE000 {
      codepoint = c0;
    } else {
      assert_syntax(0xD800 <= c0 && c0 <= 0xDBFF, json, "Expected the high surrogate of a UTF-16 pair, but got %", c0);
      assert_syntax(0xDC00 <= c0 && c0 <= 0xDFFF, json, "Expected the low surrogate of a UTF-16 pair, but got %", c1);
      codepoint = 0x10000 + (((c0 & 0x3FF) << 10) | (c1 & 0x3FF));
    }
    
    encode_utf_8(codepoint, xx json);
  }
}

process_utf_32 :: (json: *JSON, big_endian: bool) {
  assert_syntax(json.count % 4 == 0, json, "Determined the json stream's encoding to be UTF-32, but the number of bytes (%) was not a multiple of 4", json.count);
  
  data32 := []u32.{json.count / 4, xx json.data};
  json.count = 0;
  
  //TODO: Assuming little-endian
  
  for 0 .. data32.count - 1 {
    codepoint := data32[it];
    if big_endian then codepoint = byte_swap(codepoint);
    
    encode_utf_8(codepoint, xx json);
  }
}

//TODO: Make iterative
parse_json :: (json: *JSON) -> *JSON_Element {
  assert_syntax(xx json.count, json, "Expected a json stream, but got EOF");
  
  encoding := Text_Encoding.INVALID;
  
  if json.count == {
    case 1; encoding = .UTF_8;
    
    case 2;
      if       json.data[0] &&  json.data[1] then encoding = .UTF_8;
      else if  json.data[0] && !json.data[1] then encoding = .UTF_16_LE;
      else if !json.data[0] &&  json.data[1] then encoding = .UTF_16_BE;
    
    case 3;
      if json.data[0] && json.data[1] && json.data[2] then encoding = .UTF_8;
    
    case;
      if       json.data[0] &&  json.data[1] &&  json.data[2] &&  json.data[3] then encoding = .UTF_8;
      else if  json.data[0] && !json.data[1] &&  json.data[2] && !json.data[3] then encoding = .UTF_16_LE;
      else if !json.data[0] &&  json.data[1] && !json.data[2] &&  json.data[3] then encoding = .UTF_16_BE;
      else if  json.data[0] && !json.data[1] && !json.data[2] && !json.data[3] then encoding = .UTF_32_LE;
      else if !json.data[0] && !json.data[1] && !json.data[2] &&  json.data[3] then encoding = .UTF_32_BE;
  }
  
  assert_syntax(encoding != .INVALID, json, "Could not determine the encoding of the json stream");
  
  if (encoding == .UTF_8) {
    validate_utf_8(json);
  } else if (encoding == .UTF_16_LE || encoding == .UTF_16_BE) {
    process_utf_16(json, encoding == .UTF_16_BE);
  } else if (encoding == .UTF_32_LE || encoding == .UTF_32_BE) {
    process_utf_32(json, encoding == .UTF_32_BE);
  }
  
  return parse_element(json);
}

parse_value :: (json: *JSON) -> *JSON_Element {
  element: *JSON_Element;
  token := peek_token(json);
  if token == {
    case "{"; element = make_object(parse_object(json));
    case "["; element = make_array(parse_array(json));
    case "\""; element = make_string(copy_string(parse_string(json)));
    
    case "true";
      skip(json, token.count);
      element = make_boolean(true);
    
    case "false";
      skip(json, token.count);
      element = make_boolean(false);
    
    case "null";
      skip(json, token.count);
      element = make_null();
    
    case;
      if is_digit(token[0]) || token[0] == #char "-" {
        element = make_number(parse_number(json));
      } else {
        assert_syntax(false, json, "Expected 'null', 'true', 'false', '\"...\"', [...], {...}, or a number, but got %", peek(json, json.count - json.index));
      }
  }
  
  return element;
}

parse_object :: (json: *JSON) -> Table(string, *JSON_Element) {
  consume(json, "{");
  parse_whitespace(json);
  object: Table(string, *JSON_Element);
  if peek(json) != "}" {
    object = parse_members(json);
  }
  consume(json, "}");
  return object;
}

parse_members :: (json: *JSON) -> Table(string, *JSON_Element) {
  object: Table(string, *JSON_Element);
  key, value := parse_member(json);
  table_add(*object, key, value);
  while peek(json) == "," {
    skip(json);
    key, value = parse_member(json);
    table_add(*object, key, value);
  }
  return object;
}

parse_member :: (json: *JSON) -> string, *JSON_Element {
  parse_whitespace(json);
  key := copy_string(parse_string(json));
  parse_whitespace(json);
  consume(json, ":");
  value := parse_element(json);
  return key, value;
}

parse_array :: (json: *JSON) -> [..] *JSON_Element {
  consume(json, "[");
  parse_whitespace(json);
  result: [..] *JSON_Element;
  if peek(json) != "]" {
    result = parse_elements(json);
  }
  consume(json, "]");
  return result;
}

parse_elements :: (json: *JSON) -> [..] *JSON_Element {
  array: [..] *JSON_Element;
  array_add(*array, parse_element(json));
  while peek(json) == "," {
    skip(json);
    array_add(*array, parse_element(json));
  }
  return array;
}

parse_element :: (json: *JSON) -> *JSON_Element {
  parse_whitespace(json);
  result := parse_value(json);
  parse_whitespace(json);
  return result;
}

parse_string :: (json: *JSON) -> string {
  consume(json, "\"");
  result := parse_characters(json);
  consume(json, "\"");
  return result;
}

parse_characters :: (json: *JSON) -> string {
  result: string;
  index := json.index;
  count := 0;
  while peek(json) != "\""
    result.count += parse_character(json).count;
  result = string.{0, alloc(result.count)};
  json.index = index;
  while peek(json) != "\"" {
    char := parse_character(json);
    memcpy(result.data + result.count, char.data, char.count);
    result.count += char.count;
  }
  return result;
}

parse_character :: (json: *JSON) -> string {
  c, codepoint := peek(json);
  if c == "\\" {
    skip(json);
    return parse_escape(json);
  }
  assert_syntax(c != "\"" && codepoint >= 0x0020 && codepoint <= 0x10FFFF, json, "Expected a character [ -!#-\\[\\]-\\u{10FFFF}], but got %", c);
  skip(json);
  return c;
}

parse_escape :: (json: *JSON) -> string {
  c, codepoint := peek(json);
  
  if c == "u" {
    skip(json);
    value: u64 = 0;
    result := string.{0, talloc(4)};
    for 1..4 value = (value << 4) | parse_hex(json);
    if 0xD800 <= value && value <= 0xDFFF {
      assert_syntax(peek(json, 2) == "\\u", json, "Encountered a UTF-64 surrogate but it was not a pair");
      skip(json, 2);
      
      high := value;
      low: u64;
      for 1..4 low = (low << 4) | parse_hex(json);
      assert_syntax(0xD800 <= low && low <= 0xDFFF, json, "Encountered a UTF-16 surrogate but the following codepoint was not a surrogate");
      if low < 0xDC00 {
        high = low;
        low = value;
      }
      assert_syntax(high >= 0x8C00, json, "Encountered a UTF-16 surrogate pair, but both were high");
      assert_syntax(low < 0x8C00, json, "Encountered a UTF-16 surrogate pair, but both were low");
      
      value = 0x10000 + ((high << 10) | low);
    }
    encode_utf_8(xx value, *result, false);
    return result;
  }
  
  defer skip(json);
  if c == {
    case "\""; return "\"";
    case "\\"; return "\\";
    case  "/"; return "/";
    case  "b"; return "\u0008";
    case  "f"; return "\u000C";
    case  "n"; return "\n";
    case  "r"; return "\r";
    case  "t"; return "\t";
    case;
      assert_syntax(xx codepoint, json, "Expected an escape character [\"\\/bfnrt]|u[0-9A-Fa-f]{4}, but got EOF");
      assert_syntax(false, json, "Expected an escape character [\"\\/bfnrt]|u[0-9A-Fa-f]{4}, but got %", c);
      return "";
  }
}

parse_hex :: (json: *JSON) -> u64 {
  hex, codepoint := peek(json);
  assert_syntax(xx codepoint, json, "Expected a hex character [0-9A-Fa-f], but got EOF");
  assert_syntax(#char "0" <= codepoint && codepoint <= #char "9"
    || #char "A" <= codepoint && codepoint <= #char "F"
    || #char "a" <= codepoint && codepoint <= #char "f",
    json, "Expected a hex character [0-9A-Fa-f], but got %", hex);
  skip(json);
  if codepoint <= #char "9" return codepoint - #char "0";
  if codepoint <= #char "Z" return codepoint + 10 - #char "A";
  return codepoint + 10 - #char "a";
}

parse_number :: (json: *JSON) -> float64 {
  index := json.index;
  
  parse_integer(json);
  parse_fraction(json);
  parse_exponent(json);
  
  number := string.{json.index - index, json.data + index};
  
  value, success := string_to_float64(number);
  json.index = index;
  assert_syntax(success, json, "Expected a number, but got %", number);
  json.index += number.count;
  
  return value;
}

parse_integer :: (json: *JSON) {
  if peek(json) == "-"
    skip(json);
  
  d0 := parse_digit(json);
  c1, codepoint := peek(json);
  
  if d0 && is_digit(codepoint)
    parse_digits(json);
}

parse_digits :: (json: *JSON) {
  parse_digit(json);
  c, codepoint := peek(json);
  while is_digit(codepoint) {
    parse_digit(json);
    c, codepoint = peek(json);
  }
}

parse_digit :: (json: *JSON) -> int {
  c, codepoint := peek(json);
  assert_syntax(xx codepoint, json, "Expected a digit [0-9], but got EOF");
  assert_syntax(is_digit(codepoint), json, "Expected a digit [0-9], but got %", c);
  skip(json);
  return codepoint - #char "0";
}

parse_fraction :: (json: *JSON) {
  if peek(json) == "." {
    skip(json);
    parse_digits(json);
  }
}

parse_exponent :: (json: *JSON) {
  if peek(json) == {
    case "E"; #through;
    case "e";
      skip(json);
      parse_sign(json);
      parse_digits(json);
  }
}

parse_sign :: (json: *JSON) {
  if peek(json) == {
    case "+"; #through;
    case "-";
      skip(json);
  }
}

parse_whitespace :: (json: *JSON) {
  while true {
    if peek(json) == {
      case  " "; #through;
      case "\n"; #through;
      case "\r"; #through;
      case "\t"; skip(json);
      case; break;
    }
  }
}





is_digit :: (char: u32) -> bool {
  return char >= #char "0" && char <= #char "9";
}

is_delimiter :: (char: u32) -> bool {
  return !char || is_punctuation(char) || is_whitespace(char);
}

is_punctuation :: (char: u32) -> bool {
  if char == {
    case #char  "{"; #through;
    case #char  "}"; #through;
    case #char  "["; #through;
    case #char  "]"; #through;
    case #char  ":"; #through;
    case #char  ","; #through;
    case #char "\""; return true;
  }
  return false;
}

is_whitespace :: (char: u32) -> bool {
  if char == {
    case #char  " "; #through;
    case #char "\n"; #through;
    case #char "\r"; #through;
    case #char "\t"; return true;
  }
  return false;
}





consume :: (json: *JSON, expected: string) {
  assert_syntax(has_next(json, expected.count), json, "Expected %, but got EOF", expected);
  given := next(json, expected.count);
  assert_syntax(given == expected, json, "Expected %, but got %", expected, given);
}

assert_syntax :: inline (arg: bool, json: *JSON, message: string, args: .. Any, loc := #caller_location) {
  assert_message := sprint("Invalid JSON syntax at column %: %", json.index, message);
  assert(arg, assert_message, ..args, loc = loc);
  free(assert_message);
}

peek_token :: (json: *JSON) -> string {
  index := json.index;
  defer json.index = index;
  
  parse_whitespace(json);
  
  token, codepoint := peek(json);
  next := "";
  while !is_delimiter(codepoint) {
    token.count += next.count;
    skip(json);
    next, codepoint = peek(json);
  }
  
  return token;
}

next :: (json: *JSON, count: int) -> string {
  defer skip(json, count);
  return peek(json, count);
}

next :: (json: *JSON) -> string, u32 {
  defer skip(json);
  c, codepoint := peek(json);
  return c, codepoint;
}

peek :: (json: *JSON, count: int) -> string {
  if !has_next(json, count) count = json.count - json.index;
  return string.{count, json.data + json.index};
}

peek :: (json: *JSON) -> string, u32 {
  c := string.{json.count - json.index, json.data + json.index};
  codepoint, count := get_codepoint(c);
  c.count = count;
  return c, codepoint;
}

get_codepoint :: (c: string) -> u32, count: int {
  c0: u32 = ifx c.count >= 1 then c[0];
  c1: u32 = ifx c.count >= 2 then c[1];
  c2: u32 = ifx c.count >= 3 then c[2];
  c3: u32 = ifx c.count >= 4 then c[3];
  
  codepoint: u32;
  count: int;
  if c0 <= 0x7F {
    count = 1;
    codepoint = c0;
  } else if c0 <= 0xDF {
    count = 2;
    codepoint = ((c0 & 0x1F) << 6) | (c1 & 0x3F);
  } else if c0 <= 0xEF {
    count = 3;
    codepoint = ((c0 & 0x0F) << 12) | ((c1 & 0x3F) << 6) | (c2 & 0x3F);
  } else {
    count = 4;
    codepoint = ((c0 & 0x07) << 18) | ((c1 & 0x3F) << 12) | ((c2 & 0x3F) << 6) | (c3 & 0x3F);
  }
  
  return codepoint, count;
}

skip :: (json: *JSON, count: int) {
  json.index += count;
}

skip :: (json: *JSON) {
  skip(json, peek(json).count);
}

has_next :: (json: *JSON, count := 1) -> bool {
  return json.count >= json.index + count;
}

#import "Basic";
#import "Hash_Table";
#import "Bit_Operations";