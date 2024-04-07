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

get_element :: (object: *JSON_Object, name: string, default := null) -> *JSON_Element {
  value, success := table_find(*object.value, name);
  if !success then value = default;
  return value;
}

get_element :: (array: *JSON_Array, index: int, default := null) -> *JSON_Element {
  if index >= array.value.count then return default;
  return array.value[index];
}

as_null :: (element: *JSON_Element) -> *JSON_String {
  assert(element && element.kind == .NULL, "Attempted to interpret a % json object as a null", element.kind);
  return xx element;
}

as_boolean :: (element: *JSON_Element) -> *JSON_Boolean {
  assert(element && element.kind == .BOOLEAN, "Attempted to interpret a % json object as a boolean", element.kind);
  return xx element;
}

as_number :: (element: *JSON_Element) -> *JSON_Number {
  assert(element && element.kind == .NUMBER, "Attempted to interpret a % json object as a number", element.kind);
  return xx element;
}

as_string :: (element: *JSON_Element) -> *JSON_String {
  assert(element && element.kind == .STRING, "Attempted to interpret a % json object as a string", element.kind);
  return xx element;
}

as_array :: (element: *JSON_Element) -> *JSON_Array {
  assert(element && element.kind == .ARRAY, "Attempted to interpret a % json object as an array", element.kind);
  return xx element;
}

as_object :: (element: *JSON_Element) -> *JSON_Object {
  assert(element && element.kind == .OBJECT, "Attempted to interpret a % json object as an object", element.kind);
  return xx element;
}

make_null :: () -> *JSON_Null {
  elem: *JSON_Null = talloc(size_of(JSON_Null));
  elem.* = .{};
  return elem;
}

make_boolean :: (value: bool) -> *JSON_Boolean {
  elem: *JSON_Boolean = talloc(size_of(JSON_Boolean));
  elem.* = .{value = value};
  return elem;
}

make_number :: (value: float64) -> *JSON_Number {
  elem: *JSON_Number = talloc(size_of(JSON_Number));
  elem.* = .{value = value};
  return elem;
}

make_string :: (value: string) -> *JSON_String {
  elem: *JSON_String = talloc(size_of(JSON_String));
  elem.* = .{value = value};
  return elem;
}

make_array :: (value: [..]*JSON_Element) -> *JSON_Array {
  elem: *JSON_Array = talloc(size_of(JSON_Array));
  elem.* = .{value = value};
  return elem;
}

make_object :: (value: Table(string, *JSON_Element)) -> *JSON_Object {
  elem: *JSON_Object = talloc(size_of(JSON_Object));
  elem.* = .{value = value};
  return elem;
}

set_element :: (object: *JSON_Object, name: string, element: *JSON_Element) {
  if element then table_set(*object.value, name, element);
}

set_element :: (array: *JSON_Array, index: int, element: *JSON_Element) {
  if element {
    if (index >= array.value.count)
      array_resize(*array.value, index + 1, true);
    array.value[index] = element;
  }
}

print_element :: (element: *JSON_Element) -> string {
  builder: String_Builder;
  init_string_builder(*builder);
  
  append_element :: (builder: *String_Builder, element: *JSON_Element) {
    if element.kind == {
      case .NULL;
        append(builder, "null");
        
      case .BOOLEAN;
        append(builder, ifx as_boolean(element).value then "true" else "false");
      
      case .NUMBER;
        stb_print_float(builder, .{value = as_number(element).value});
      
      case .STRING;
        //TODO: Re-escape this
        append(builder, "\"");
        append(builder, as_string(element).value);
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
  data: *u8;
  index: int;
  count: int;
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

encode_utf_8 :: (json: *JSON, codepoint: u32, name: string) {
  if codepoint <= 0x7F {
    json.data[json.count+0] = xx 0x7F & codepoint;
    json.count += 1;
  } else if codepoint <= 0x7FF {
    json.data[json.count+0] = xx 0xC0 | ((codepoint >> 6) & 0x1F);
    json.data[json.count+1] = xx 0x80 | (codepoint & 0x3F);
    json.count += 2;
  } else if codepoint <= 0xFFFF {
    assert_syntax(codepoint < 0xD800 || codepoint > 0xDFFF, json, "Encountered an invalid UTF-16 surrogate % while transcoding from % to UTF-8", codepoint, name);
    json.data[json.count+0] = xx 0xE0 | ((codepoint >> 12) & 0x0F);
    json.data[json.count+1] = xx 0x80 | ((codepoint >> 6) & 0x3F);
    json.data[json.count+2] = xx 0x80 | (codepoint & 0x3F);
    json.count += 3;
  } else {
    assert_syntax(codepoint <= 0x10FFFF, json, "Encountered an undefined encoding % while transcoding from % to UTF-8", codepoint, name);
    json.data[json.count+0] = xx 0xF0 | ((codepoint >> 18) & 0x07);
    json.data[json.count+1] = xx 0x80 | ((codepoint >> 12) & 0x3F);
    json.data[json.count+2] = xx 0x80 | ((codepoint >> 6) & 0x3F);
    json.data[json.count+3] = xx 0x80 | (codepoint & 0x3F);
    json.count += 4;
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
    
    encode_utf_8(json, codepoint, "UTF-16");
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
    
    encode_utf_8(json, codepoint, "UTF-32");
  }
}

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
    case "\""; element = make_string(parse_string(json));
    
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
  key := parse_string(json);
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
  characters := peek(json, 0);
  while peek(json) != "\""
    characters.count += parse_character(json).count;
  
  return characters;
}

parse_character :: (json: *JSON) -> string {
  c, codepoint := peek(json);
  result := string.{json.index, json.data + json.index};
  
  if c == "\\" {
    skip(json);
    parse_escape(json);
    result.count = json.index - result.count;
  } else {
    assert_syntax(c != "\"" && codepoint >= 0x0020 && codepoint <= 0x10FFFF,
      json, "Expected a character [ -!#-[]-\\u{10FFFF}], but got %", c);
    result.count = c.count;
    skip(json);
  }
  
  return result;
}

parse_escape :: (json: *JSON) {
  //TODO Store an additional string that replaces escapes with their respective codepoints
  
  c, codepoint := peek(json);
  if c == {
    case "\""; #through;
    case "\\"; #through;
    case  "/"; #through;
    case  "b"; #through;
    case  "f"; #through;
    case  "n"; #through;
    case  "r"; #through;
    case  "t"; skip(json);
    
    case  "u";
      skip(json);
      for 1..4 parse_hex(json);
    
    case;
      assert_syntax(xx codepoint, json, "Expected an escape character [\"\\/bfnrt]|u[0-9A-Fa-f]{4}, but got EOF");
      assert_syntax(false, json, "Expected an escape character [\"\\/bfnrt]|u[0-9A-Fa-f]{4}, but got %", c);
  }
}

parse_hex :: (json: *JSON) {
  hex, codepoint := peek(json);
  assert_syntax(xx codepoint, json, "Expected a hex character [0-9A-Fa-f], but got EOF");
  assert_syntax(#char "0" <= codepoint && codepoint <= #char "9"
    || #char "A" <= codepoint && codepoint <= #char "F"
    || #char "a" <= codepoint && codepoint <= #char "f",
    json, "Expected a hex character [0-9A-Fa-f], but got %", hex);
  skip(json);
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
  assert(arg, tprint("Invalid JSON syntax at column %: %", json.index, message), ..args, loc = loc);
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
  codepoint: u32;
  
  c0: u32 = ifx has_next(json, 1) then c[0];
  c1: u32 = ifx has_next(json, 2) then c[1];
  c2: u32 = ifx has_next(json, 3) then c[2];
  c3: u32 = ifx has_next(json, 4) then c[3];
  
  if c0 <= 0x7F {
    c.count = 1;
    codepoint = c0;
  } else if c0 <= 0xDF {
    c.count = 2;
    codepoint = ((c0 & 0x1F) << 6) | (c1 & 0x3F);
  } else if c0 <= 0xEF {
    c.count = 3;
    codepoint = ((c0 & 0x0F) << 12) | ((c1 & 0x3F) << 6) | (c2 & 0x3F);
  } else {
    c.count = 4;
    codepoint = ((c0 & 0x07) << 18) | ((c1 & 0x3F) << 12) | ((c2 & 0x3F) << 6) | (c3 & 0x3F);
  }
  
  return c, codepoint;
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