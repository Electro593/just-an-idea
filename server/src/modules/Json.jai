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
	json: JSON;
	json.text.data = text.data;
	json.text.count = text.count;
	json.reallocated = false;

	elem := parse_json(*json);
	if json.reallocated array_free(json.text);
	return elem;
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

get :: inline (object: *JSON_Object, name: string, default := null) -> *JSON_Element {
	assert(xx object, "Attempted to get \"%\" from an object, but the object was null", name);
	success, value := table_find(*object.value, name);
	if !success then value = default;
	return value;
}

get :: inline (array: *JSON_Array, index: int, default := null) -> *JSON_Element {
	assert(xx array, "Attempted to get index % from an array, but the array was null", index);
	assert(index >= 0, "Attempted to get index % from an array, but the index is less than 0", index);
	if index >= array.value.count then return default;
	return array.value[index];
}

get_int :: inline (object: *JSON_Object, name: string, default := 0) -> int {
	elem := get(object, name);
	return ifx elem && elem.kind == .NUMBER then xx as_number(elem).value else default;
}

get_string :: inline (object: *JSON_Object, name: string, default := "") -> string {
	elem := get(object, name);
	return ifx elem && elem.kind == .STRING then as_string(elem).value else default;
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

append :: (array: *JSON_Array, element: *JSON_Element) {
	set_element(array, array.value.count, element);
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
	text: [..] u8;
	index: int;

	error: bool;
	reallocated: bool;

	utf8_buffer: [4] u8;
}

validate_utf_8 :: (json: *JSON) {
	validate_continuation :: (json: *JSON, byte: u32, base: int, index: int, count: int) -> bool {
		return assert_syntax(base + index < count, json, "Expected continuation byte % of a UTF-8 character, but got EOF", index)
			|| assert_syntax((byte & 0xC0) == 0x80, json, "Expected continuation byte % of a UTF-8 character, but got %", index, byte);
	}

	assert_continuation :: (condition: bool, json: *JSON, codepoint: u32) -> bool {
		return assert_syntax(condition, json, "Encountered the invalid UTF-8 codepoint %, which is continuation byte", codepoint);
	}

	assert_overlong :: (condition: bool, json: *JSON, codepoint: u32) -> bool {
		return assert_syntax(condition, json, "Encountered the invalid UTF-8 codepoint %, which is overlong", codepoint);
	}

	assert_undefined :: (condition: bool, json: *JSON, codepoint: u32) -> bool {
		return assert_syntax(condition, json, "Encountered the invalid UTF-8 codepoint %, which is undefined", codepoint);
	}

	assert_surrogate :: (condition: bool, json: *JSON, codepoint: u32) -> bool {
		return assert_syntax(condition, json, "Encountered the invalid UTF-8 codepoint %, which is a UTF-16 surrogate half", codepoint);
	}

	error := json.error;
	json.error = false;

	it := 0;
	while it < json.text.count {
		codepoint: u32;
		len := 1;

		c0: u32 = ifx it+0 < json.text.count then json.text.data[it+0];
		c1: u32 = ifx it+1 < json.text.count then json.text.data[it+1];
		c2: u32 = ifx it+2 < json.text.count then json.text.data[it+2];
		c3: u32 = ifx it+3 < json.text.count then json.text.data[it+3];

		if c0 < 0x80 {
			codepoint = c0;
		} else if c0 < 0xC0 {
			assert_continuation(false, json, c0);
		} else if c0 < 0xE0 {
			if validate_continuation(json, c1, it, 1, json.text.count) len += 1;
			codepoint = ((c0 & 0x1F) << 6) | (c1 & 0x3F);
			if !assert_overlong(0x80 <= codepoint, json, codepoint) len = 1;
		} else if c0 < 0xF0 {
			if validate_continuation(json, c1, it, 1, json.text.count) len += 1;
			if !json.error && validate_continuation(json, c2, it, 2, json.text.count) len += 1;
			codepoint = ((c0 & 0x0F) << 12) | ((c1 & 0x3F) << 6) | (c2 & 0x3F);
			if !assert_overlong(0x800 <= codepoint, json, codepoint) len = 1;
			if !assert_surrogate(codepoint < 0xD800 || codepoint > 0xDFFF, json, codepoint) len = 1;
		} else {
			if validate_continuation(json, c1, it, 1, json.text.count) len += 1;
			if !json.error && validate_continuation(json, c2, it, 2, json.text.count) len += 1;
			if !json.error && validate_continuation(json, c3, it, 3, json.text.count) len += 1;
			codepoint = ((c0 & 0x07) << 18) | ((c1 & 0x3F) << 12) | ((c2 & 0x3F) << 6) | (c3 & 0x3F);
			if !assert_undefined(codepoint <= 0x10FFFF, json, codepoint) len = 1;
			if !assert_overlong(0x10000 <= codepoint, json, codepoint) len = 1;
		}

		if json.error {
			src_offset := it + len;
			dst_offset := it + 3;
			if src_offset != dst_offset {
				if !json.reallocated {
					old_array := json.text;
					json.text.allocated = max(8, json.text.count) * 2;
					json.text.data = alloc(json.text.allocated * size_of(u8));
					remember_allocators(*json.text);
					memcpy(json.text.data, old_array.data, it);
					memcpy(json.text.data + dst_offset, old_array.data + src_offset, old_array.count - src_offset);
					json.reallocated = true;
					json.text.count += 3 - len;
				} else {
					json.text.count += 3 - len;
					maybe_grow(xx *json.text, size_of(u8));
					memcpy(json.text.data + dst_offset, json.text.data + src_offset, json.text.count - src_offset);
				}
			}

			// Insert 0xFFFD, the error character
			json.text.data[it] = 0xEF;
			json.text.data[it+1] = 0xBF;
			json.text.data[it+2] = 0xBD;
			len = 3;
		}

		json.error = false;
		it += len;
	}

	json.error = error;
}

encode_utf_8 :: (codepoint: u32, out: *string) {
	if codepoint >= 0xD800 && codepoint <= 0xDFFF || codepoint > 0x10FFFF
		codepoint = 0xFFFD;

	if codepoint <= 0x7F {
		out.data[out.count+0] = xx 0x7F & codepoint;
		out.count += 1;
	} else if codepoint <= 0x7FF {
		out.data[out.count+0] = xx 0xC0 | ((codepoint >> 6) & 0x1F);
		out.data[out.count+1] = xx 0x80 | (codepoint & 0x3F);
		out.count += 2;
	} else if codepoint <= 0xFFFF {
		out.data[out.count+0] = xx 0xE0 | ((codepoint >> 12) & 0x0F);
		out.data[out.count+1] = xx 0x80 | ((codepoint >> 6) & 0x3F);
		out.data[out.count+2] = xx 0x80 | (codepoint & 0x3F);
		out.count += 3;
	} else {
		out.data[out.count+1] = xx 0x80 | ((codepoint >> 12) & 0x3F);
		out.data[out.count+0] = xx 0xF0 | ((codepoint >> 18) & 0x07);
		out.data[out.count+2] = xx 0x80 | ((codepoint >> 6) & 0x3F);
		out.data[out.count+3] = xx 0x80 | (codepoint & 0x3F);
		out.count += 4;
	}
}

//TODO: Make iterative
parse_json :: (json: *JSON) -> *JSON_Element {
	assert_syntax(xx json.text.count, json, "Expected a json stream, but got EOF");

	validate_utf_8(json);

	// Skip a BOM, if present
	if json.text.count >= 2 && peek(json, 2) == "\uFEFF" || peek(json, 2) == "\uFFFE"
		skip(json, 2);

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
				assert_syntax(false, json, "Expected 'null', 'true', 'false', '\"...\"', [...], {...}, or a number, but got %", peek(json, json.text.count - json.index));
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
	result: string;
	result.data = xx json.utf8_buffer.data;

	if c == "u" {
		error := json.error;
		json.error = false;

		skip(json);
		codepoint: u64 = 0;
		for 1..4 codepoint = (codepoint << 4) | parse_hex(json);

		if 0xD800 <= codepoint && codepoint <= 0xDFFF {
			high := codepoint;
			assert_syntax(high < 0xDC00, json, "Encountered a UTF-16 low surrogate half without a preceeding high half");
			assert_syntax(peek(json, 2) == "\\u", json, "Encountered a UTF-16 high surrogate half but the following codepoint was not a low half");
			skip(json, 2);

			low: u64;
			for 1..4 low = (low << 4) | parse_hex(json);
			assert_syntax(0xDC00 <= low && low <= 0xDFFF, json, "Encountered a UTF-16 high surrogate but the following codepoint was not a low half");

			high &= 0x3FF;
			low &= 0x3FF;
			codepoint = 0x10000 + ((high << 10) | low);
		}

		// If we encountered an invalid surrogate half or hex digit, replace with the invalid char
		if json.error then codepoint = 0xFFFD;
		json.error = error;

		encode_utf_8(xx codepoint, *result);
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
			codepoint = 0xFFFD;
			encode_utf_8(xx codepoint, *result);
			return result;
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

	number := string.{json.index - index, json.text.data + index};

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
	_, codepoint := peek(json);

	if d0 && is_digit(codepoint)
		parse_digits(json);
}

parse_digits :: (json: *JSON) {
	parse_digit(json);
	_, codepoint := peek(json);
	while is_digit(codepoint) {
		parse_digit(json);
		_, codepoint = peek(json);
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

assert_syntax :: inline (arg: bool, json: *JSON, message: string, args: .. Any, loc := #caller_location) -> bool {
	if !arg {
		assert_message := sprint("Invalid JSON syntax at column %: %", json.index, message);
		assert(arg, assert_message, ..args, loc = loc);
		free(assert_message);
		json.error = true;
	}
	return arg;
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
	if !has_next(json, count) count = json.text.count - json.index;
	return string.{count, json.text.data + json.index};
}

peek :: (json: *JSON) -> string, u32 {
	c := string.{json.text.count - json.index, json.text.data + json.index};
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
	return json.text.count >= json.index + count;
}

#import "Basic";
#import "Hash_Table";
#import "Bit_Operations";
