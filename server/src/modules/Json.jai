#module_parameters (CAST_SCOPE: Code) ();

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
    case .NULL; #through;
    case .BOOLEAN; #through;
    case .NUMBER; #through;
    case .STRING;
      free(element);
    
    case .ARRAY;
      elem := as_array(element);
      for elem.value free_json(it);
      array_free(elem.value);
      free(element);
      
    case .OBJECT;
      elem := as_object(element);
      for elem.value free_json(it);
      deinit(*elem.value);
      free(element);
  }
}

get_element :: inline (object: *JSON_Object, name: string, default := null) -> *JSON_Element {
  assert(xx object, "Attempted to get \"%\" from an object, but it was null", name);
  value, success := table_find(*object.value, name);
  if !success then value = default;
  return value;
}

get_element :: inline (array: *JSON_Array, index: int, default := null) -> *JSON_Element {
  assert(xx object, "Attempted to get index % from an array, but it was null", index);
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

//NOTE: The notes "$Null", "$Boolean", "$Number", "$String", "$Array", and "$Object" will place their
// respective JSON_*.value values into the Any.
NOTES :: string.[];
BLACKLIST :: string.["?"];
cast_json_log_none :: (f: string, a: .. Any, t := false) -> s64 { return 0; }
cast_json :: (json: *JSON_Element, $T: Type, out: *T = null, $notes: [] string = NOTES, $blacklist: [] string = BLACKLIST, $should_assert := true, log: (f: string, a: ..Any, t := false) -> s64 = cast_json_log_none) -> T {
  value: T;
  if !json return value;
  log("Hello from the outer: %, %, %, %, %, %", print_json(json,, temp), T, out, notes, blacklist, should_assert);
  success := cast_json(json, *value, notes, blacklist, should_assert, log = log);
  if !success return value;
  if out out.* = value;
  return value;
}

cast_json :: (json: *JSON_Element, out: *$T, $notes: [] string = NOTES, $blacklist: [] string = BLACKLIST, $should_assert := true, log: (f: string, a: ..Any, t := false) -> s64 = cast_json_log_none) -> success: bool {
  assert_cast_json :: (arg: bool, message := "", args: .. Any, loc := #caller_location) #no_debug #expand {
    #if `should_assert assert(arg, message, ..args, loc = loc);
    if !arg `return false;
  }
  
  construct_json_cast :: (type: *Type_Info, notes: [] string, blacklist: [] string) -> string {
    builder: String_Builder;
    init_string_builder(*builder,, temp);
    
    type_name := get_type_name(type);
    print_to_builder(*builder, "// For '%' with notes: %\n", type_name, notes);
    print_to_builder(*builder, "_cast_json :: (json: *JSON_Element, out: *$T, $should_assert := true, log: (f: string, a: ..Any, t := false) -> s64 = cast_json_log_none) -> success: bool {\n");
    print_to_builder(*builder, "  assert_cast_json(xx out, \"Attempted to cast %%, but out was null\", print_json(json,, temp));\n");
    print_to_builder(*builder, "  assert_cast_json(json || array_find(notes, \"?\"), \"json was null, but it was not marked as optional (@?)\");\n");
    print_to_builder(*builder, "  if !json return true;\n");
    print_to_builder(*builder, "  value: T;\n");
    
    if type.type == {
      case .VOID;
      
      case .BOOL;
        print_to_builder(*builder, "  assert_cast_json(json.kind == .BOOLEAN, \"Expected a boolean, but got %%\", print_json(json,, temp));\n");
        print_to_builder(*builder, "  value = xx as_boolean(json).value;\n");
      
      case .INTEGER; #through;
      case .FLOAT;
        print_to_builder(*builder, "  assert_cast_json(json.kind == .NUMBER, \"Expected a number, but got %%\", print_json(json,, temp));\n");
        print_to_builder(*builder, "  value = xx as_number(json).value;\n");
      
      case .STRING;
        print_to_builder(*builder, "  assert_cast_json(json.kind == .STRING, \"Expected a string, but got %%\", print_json(json,, temp));\n");
        print_to_builder(*builder, "  value = xx as_string(json).value;\n");
      
      case .VARIANT;
        t: *Type_Info_Variant = xx type;
        variant_name := get_type_name(t.variant_of);
        print_to_builder(*builder, "  V :: #insert,scope(CAST_SCOPE) \"#type %;\";\n", variant_name);
        print_to_builder(*builder, "  success := cast_json(json, cast(*V) *value, .%, .%, should_assert, log);\n", notes, blacklist);
        print_to_builder(*builder, "  assert_cast_json(success, \"Could not cast %% to the variant %% of '%'\", print_json(json,, temp), T);\n", variant_name);
      
      case .ANY;
        print_to_builder(*builder, "  success := false;\n");
        has_unblacklisted_notes := false;
        for notes {
          if array_find(blacklist, it) continue;
          has_unblacklisted_notes = true;
          if it == {
            case "$Null";    print_to_builder(*builder, "  if !success && json.kind == .NULL    then success, value = true, null;\n");
            case "$Boolean"; print_to_builder(*builder, "  if !success && json.kind == .BOOLEAN then success, value = true, as_boolean(json).value;\n");
            case "$Number";  print_to_builder(*builder, "  if !success && json.kind == .NUMBER  then success, value = true, as_number(json).value;\n");
            case "$String";  print_to_builder(*builder, "  if !success && json.kind == .STRING  then success, value = true, as_string(json).value;\n");
            case "$Array";   print_to_builder(*builder, "  if !success && json.kind == .ARRAY   then success, value = true, as_array(json).value;\n");
            case "$Object";  print_to_builder(*builder, "  if !success && json.kind == .OBJECT  then success, value = true, as_object(json).value;\n");
            case;
              print_to_builder(*builder, "  if !success {\n");
              print_to_builder(*builder, "    V :: #insert,scope(CAST_SCOPE) \"#type %;\";\n", it);
              print_to_builder(*builder, "    test: V;\n");
              print_to_builder(*builder, "    success = cast_json(json, *test, .[], .%, false, log);\n", blacklist);
              print_to_builder(*builder, "    if success {\n");
              print_to_builder(*builder, "      value.type = type_info(V);\n");
              print_to_builder(*builder, "      value.value_pointer = alloc(size_of(V));\n");
              print_to_builder(*builder, "      memcpy(value.value_pointer, *test, size_of(V));\n");
              print_to_builder(*builder, "    }\n");
              print_to_builder(*builder, "  }\n");
          }
        }
        if has_unblacklisted_notes {
          print_to_builder(*builder, "  assert_cast_json(success, \"Could not cast %% to any of the following: [");
        } else {
          print_to_builder(*builder, "  if #complete json.kind == {\n");
          print_to_builder(*builder, "    case .NULL;    value = null;\n");
          print_to_builder(*builder, "    case .BOOLEAN; value = as_boolean(json).value;\n");
          print_to_builder(*builder, "    case .NUMBER;  value = as_number(json).value;\n");
          print_to_builder(*builder, "    case .STRING;  value = as_string(json).value;\n");
          print_to_builder(*builder, "    case .ARRAY;   value = as_array(json).value;\n");
          print_to_builder(*builder, "    case .OBJECT;  value = as_object(json).value;\n");
          print_to_builder(*builder, "  }\n");
        }
        for notes {
          if !array_find(blacklist, it)
          if it_index append(*builder, ", ");
          append(*builder, it);
        }
        print_to_builder(*builder, "  ]\", print_json(json,, temp));\n");
      
      case .ARRAY;
        t: *Type_Info_Array = xx type;
        print_to_builder(*builder, "  assert_cast_json(json.kind == .ARRAY, \"Expected an array (%%), but got %%\", T, print_json(json,, temp));\n");
        print_to_builder(*builder, "  array := as_array(json).value;\n");
        element_name := get_type_name(t.element_type);
        if t.array_type == .VIEW
          print_to_builder(*builder, "  value = .{array.count, alloc(array.count * size_of(%))};\n", element_name);
        print_to_builder(*builder, "  for array\n");
        if t.array_type == {
          case .FIXED; #through;
          case .VIEW;
            print_to_builder(*builder, "    cast_json(it, *value[it_index], .[], .%, should_assert, log);\n", blacklist);
          case .RESIZABLE;
            print_to_builder(*builder, "    cast_json(it, array_add(*value), .[], .%, should_assert, log);\n", blacklist);
        }
      
      case .STRUCT;
        t: *Type_Info_Struct = xx type;
        // There's no viable way to cast unions (where would we write the differentiator?),
        // so we'll just ignore them.
        if !(t.textual_flags & .UNION) {
          print_to_builder(*builder, "  assert_cast_json(json.kind == .OBJECT, \"Expected an object (%%), but got %%\", T, print_json(json,, temp));\n");
          print_to_builder(*builder, "  object := as_object(json);\n");
          print_to_builder(*builder, "  success: bool;\n");
          for t.members {
            print_to_builder(*builder, "  success = cast_json(get_element(object, \"%\"), *value.%, .%, .%, should_assert);\n", it.name, it.name, it.notes, blacklist);
            print_to_builder(*builder, "  assert_cast_json(success, \"Could not cast %% to a struct (%%) because casting the member % (%) failed\", print_json(json,, temp), T);\n", it.name, get_type_name(it.type));
          }
        }
      
      case .ENUM;
        build_switch_case :: (builder: *String_Builder, t: *Type_Info_Enum, type_name: string, value: string, wrapper: string, operation: string, indentation: string) {
          print_to_builder(builder, "%check := %;\n", indentation, value);
          print_to_builder(builder, "%if check == {\n", indentation);
          for t.names print_to_builder(builder, "%  case %; value % .%;\n", indentation, tprint(wrapper, it), operation, it);
          print_to_builder(builder, "%  case; assert_cast_json(false, \"The provided value '%%' didn't match any of the options in %% (%)\", check, T);\n", indentation, type_name);
          print_to_builder(builder, "%}\n", indentation);
        }
        t: *Type_Info_Enum = xx type;
        if t.enum_type_flags & .FLAGS {
          print_to_builder(*builder, "  if json.kind == .NUMBER {\n");
          // This isn't a perfect check, since it allows single bits when they're part of a multi-bit flag.
          // However, if would be way to expensive to fully check it, so we'll just trust that the enums
          // are somewhat reasonable.
          print_to_builder(*builder, "    value = cast(T) as_number(json).value;\n");
          print_to_builder(*builder, "    check := value;\n");
          for t.names print_to_builder(*builder, "    check &= ~.%;\n", it);
          print_to_builder(*builder, "    assert_cast_json(!check, \"The provided enum_flags value '%%' didn't match any of the options in %% (%)\", value, T);\n",  type_name);
          print_to_builder(*builder, "  } else if json.kind == .ARRAY {\n");
          print_to_builder(*builder, "    array := as_array(json).value;\n");
          print_to_builder(*builder, "    for array {\n");
          print_to_builder(*builder, "      if json.kind == .STRING {\n");
          build_switch_case(*builder, t, type_name, "as_string(json).value", "\"%\"", "|=", "        ");
          print_to_builder(*builder, "      } else if json.kind == .NUMBER {\n");
          build_switch_case(*builder, t, type_name, tprint("cast(T) as_number(json).value"), ".%", "|=", "        ");
          print_to_builder(*builder, "      } else assert_cast_json(false, \"Expected only strings and numbers within the array because %% is an enum (%), but got %%\", T, print_json(json,, temp));\n", type_name);
          print_to_builder(*builder, "    }\n");
          print_to_builder(*builder, "  } else assert_cast_json(false, \"Expected an array or number because %% is an enum_flags (%), but got %%\", T, print_json(json,, temp));\n", type_name);
        } else {
          print_to_builder(*builder, "  if json.kind == .STRING {\n");
          build_switch_case(*builder, t, type_name, "as_string(json).value", "\"%\"", "=", "    ");
          print_to_builder(*builder, "  } else if json.kind == .NUMBER {\n");
          build_switch_case(*builder, t, type_name, tprint("cast(T) as_number(json).value"), ".%", "=", "    ");
          print_to_builder(*builder, "  } else assert_cast_json(false, \"Expected a string or number because %% is an enum (%), but got %%\", T, print_json(json,, temp));\n", type_name);
        }
      
      // No good way to parse these, so we'll just ignore them
      case .POINTER;
      case .PROCEDURE;
      case .OVERLOAD_SET;
      case .POLYMORPHIC_VARIABLE;
      case .TYPE;
      case .CODE;
      case;
    }
    
    print_to_builder(*builder, "  out.* = value;\n");
    print_to_builder(*builder, "  return true;\n");
    print_to_builder(*builder, "}\n");
    
    return builder_to_string(*builder);
  }
  
  #insert #run construct_json_cast(type_info(T), notes, blacklist);
  return _cast_json(json, out, should_assert, log);
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

get_type_name :: (type: *Type_Info) -> string {
  if #complete type.type == {
    case .BOOL; return "bool";
    case .STRING; return "string";
    case .VOID; return "void";
    case .ANY; return "Any";
    case .TYPE; return "Type";
    case .CODE; return "Code";
    
    case .INTEGER;
      if type == type_info(int) return "int";
      t: *Type_Info_Integer = xx type;
      return tprint("%0%", ifx t.signed then "s" else "u", t.runtime_size * 8);
    
    case .FLOAT;
      if type == type_info(float) return "float";
      return tprint("float%", type.runtime_size * 8);
    
    case .POINTER;
      t: *Type_Info_Pointer = xx type;
      return tprint("*%", get_type_name(t.pointer_to));
    
    case .PROCEDURE;
      t: *Type_Info_Procedure = xx type;
      builder: String_Builder;
      init_string_builder(*builder,, temp);
      append(*builder, "(");
      for t.argument_types
        print_to_builder(*builder, "%0%", ifx it_index then ", " else "", get_type_name(it));
      append(*builder, ") -> (");
      for t.return_types
        print_to_builder(*builder, "%0%", ifx it_index then ", " else "", get_type_name(it));
      append(*builder, ")");
      if t.procedure_flags & .IS_ELSEWHERE append(*builder, " #elsewhere");
      if t.procedure_flags & .IS_COMPILE_TIME_ONLY append(*builder, " #compiler");
      if t.procedure_flags & .HAS_NO_CONTEXT append(*builder, " #no_context");
      if t.procedure_flags & .IS_C_CALL append(*builder, " #c_call");
      if t.procedure_flags & .IS_INTRINSIC append(*builder, " #intrinsic");
      if t.procedure_flags & .IS_SYMMETRIC append(*builder, " #symmetric");
      if t.procedure_flags & .IS_CPP_METHOD append(*builder, " #cpp_method");
      if t.procedure_flags & .HAS_CPP_NON_POD_RETURN_TYPE append(*builder, " #cpp_return_type_is_non_pod");
      return builder_to_string(*builder);
    
    case .STRUCT;
      append_struct_member :: (builder: *String_Builder, parent: *Type_Info_Struct, member: Type_Info_Struct_Member, delimiter: string, print_delimiter: bool) {
        if member.flags & .CONSTANT {
          value: Any;
          value.type = member.type;
          value.value_pointer = parent.constant_storage.data + member.offset_into_constant_storage;
          print_to_builder(builder, "% : % : %", member.name, get_type_name(member.type), value);
        } else {
          if member.flags & .AS append(builder, "#as ");
          if member.flags & .USING append(builder, "using ");
          assert(!(member.flags & .IMPORTED), "Not yet implemented");
          print_to_builder(builder, "%: %", member.name, get_type_name(member.type));
        }
        if print_delimiter append(builder, delimiter);
        for member.notes
          print_to_builder(builder, " @%", it);
        if print_delimiter append(builder, " ");
      }
      
      t: *Type_Info_Struct = xx type;
      if t.name return t.name;
      builder: String_Builder;
      init_string_builder(*builder,, temp);
      append(*builder, ifx t.textual_flags & .UNION then "union" else "struct");
      if t.textual_flags & .TYPE_INFO_NONE append(*builder, " #type_info_none");
      if t.textual_flags & .TYPE_INFO_NO_SIZE_COMPLAINT append(*builder, " #type_info_no_size_complaint");
      if t.textual_flags & .TYPE_INFO_PROCEDURES_ARE_VOID_POINTERS append(*builder, " #type_info_procedures_are_void_pointers");
      assert(!t.specified_parameters.count, "Not yet implemented");
      if t.polymorph_source_struct {
        append(*builder, "(");
        for t.specified_parameters
          append_struct_member(*builder, t, it, ",", xx it_index);
        append(*builder, ")");
      }
      for t.notes
        print_to_builder(*builder, " @%", it);
      append(*builder, " { ");
      for t.members
        append_struct_member(*builder, t, it, ";", true);
      append(*builder, "}");
      if t.textual_flags & .FOREIGN append(*builder, " #foreign");
      if t.textual_flags & .NO_PADDING append(*builder, " #no_padding");
      return builder_to_string(*builder);
    
    case .ARRAY;
      t: *Type_Info_Array = xx type;
      element_name := get_type_name(t.element_type);
      if #complete t.array_type == {
        case .FIXED; return tprint("[%] %", t.array_count, element_name);
        case .VIEW; return tprint("[] %", element_name);
        case .RESIZABLE; return tprint("[..] %", element_name);
      }
    
    case .OVERLOAD_SET;
      assert(false, "Could not determine the type name for %", type.*);
      return "";
    
    case .ENUM;
      t: *Type_Info_Enum = xx type;
      if t.name return t.name;
      builder: String_Builder;
      init_string_builder(*builder,, temp);
      append(*builder, "enum");
      if t.enum_type_flags & .FLAGS     append(*builder, "_flags");
      print_to_builder(*builder, " %", get_type_name(t.internal_type));
      if t.enum_type_flags & .COMPLETE  append(*builder, " #complete");
      if t.enum_type_flags & .SPECIFIED append(*builder, " #specified");
      append(*builder, " { ");
      assert(t.names.count == t.values.count, "The enum % has % names but % values", t.*, t.names.count, t.values.count);
      for t.names
        print_to_builder(*builder, "% :: %; ", it, t.values[it_index]);
      append(*builder, "}");
      return builder_to_string(*builder);
    
    case .POLYMORPHIC_VARIABLE;
      assert(false, "Could not determine the type name for %", type.*);
      return "";
    
    case .VARIANT;
      t: *Type_Info_Variant = xx type;
      if t.name return t.name;
      return tprint("#type%0% %",
        ifx t.variant_flags & .DISTINCT then ",distinct" else "",
        ifx t.variant_flags & .ISA then ",isa" else "",
        get_type_name(t.variant_of)); 
  }
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
  characters := peek(json, 0);
  while peek(json) != "\""
    characters.count += parse_character(json).count;
  return copy_string(characters);
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