#module_parameters (SHOULD_LOG := false) ();

// Cast json to type T. The result is placed in out and returned. Notes allow you to specify the following properties, and blacklist is a list of notes to ignore.
//NOTE: The note "$Null" on an Any will place 'null' into it if the json is JSON_Null.
//NOTE: The note "$Table" on a Table will interpret a JSON_Object as a Hash_Table.Table.
//NOTE: The note "$Ignore" on any value will leave it unchanged.
//NOTE: The note "?" on any value will be defaulted if json is null, so take care with valid default values.
//NOTE: For Any values, you can note the names of types (visible to scope) to attempt to cast to. If nothing is specified, a JSON_Element will be stored instead.
//NOTE: For structs, members named '_' will be treated as being labelled as 'using', so that you can union
// multiple types in an Any without needing an outer object. Note that if the member is resolved to anything
// other than a struct, all other members will be ignored during serialization.
cast_json :: inline (json: *JSON_Element, $T: Type, $notes: [] string = .[], $blacklist: [] string = BLACKLIST, $should_assert := true, log: (f: string, a: ..Any, t := false) -> s64 = cast_json_log_none, $scope := #caller_code) -> T, success: bool {
  value: T;
  success := cast_json(json, *value, notes, blacklist, should_assert, log, scope);
  return value, success;
}

// Cast value to json, with similar uses for notes.
cast_json :: (value: Any, notes: [] string = .[], log: (f: string, a: ..Any, t := false) -> s64 = cast_json_log_none) -> json: *JSON_Element #expand {
  return cast_json(value.value_pointer, value.type, notes, log);
}

// Copy value and output the result. This will copy the values according to what is
// allocated by cast_json, and will ignore values marked as $Ignore.
copy_casted_json :: (value: $T, log: (f: string, a: ..Any, t := false) -> s64 = cast_json_log_none) -> T #expand {
  out: T;
  copy_casted_json(*value, type_info(T), *out, .[], log);
  return out;
}

// Free value and reset it to default values. This will free according to what is
// allocated by cast_json, and will igonre values marked as $Ignore.
free_casted_json :: (value: *$T, log: (f: string, a: ..Any, t := false) -> s64 = cast_json_log_none) #expand {
  free_casted_json(xx value, type_info(T), log);
}

is_any_null :: inline (any: Any) -> bool {
  return any.type == type_info(void) && any.value_pointer == null;
}

is_any_undef :: inline (any: Any) -> bool {
  return any.type == null && any.value_pointer == null;
}

is_any_of_type :: (any: Any, T: Type) -> bool #expand {
  return get_any_type(any) == type_info(T);
}

get_any_type :: (any: $A) -> *Type_Info #modify {
  return A == Any;
} #expand {
  type := any.type;
  while type && type.type == .VARIANT
    type = (cast(*Type_Info_Variant) type).variant_of;
  return type;
}

cast_any :: (any: $A, $T: Type) -> *T #modify {
  return A == Any;
} #expand {
  return cast(*T) any.value_pointer;
}

are_any_equal :: inline (a: Any, b: Any) -> bool {
  return a.type == b.type && memcmp(a.value_pointer, b.value_pointer, a.type.runtime_size) == 0;
}

alloc_any :: inline (value: Any) -> Any {
  result := Any.{value.type, alloc(value.type.runtime_size)};
  memcpy(result.value_pointer, value.value_pointer, value.type.runtime_size);
  return result;
}

make_null_any :: inline () -> Any {
  return Any.{type_info(void), null};
}

make_undef_any :: inline () -> Any {
  return Any.{};
}

cast_json :: (json: *JSON_Element, out: *$T, $notes: [] string = .[], $blacklist: [] string = BLACKLIST, $should_assert := true, log: (f: string, a: ..Any, t := false) -> s64 = cast_json_log_none, $scope := #caller_code) -> success: bool {
  assert_cast_json :: (arg: bool, message := "", args: .. Any, loc := #caller_location) #no_debug #expand {
    #if `should_assert assert(arg, message, ..args, loc = loc);
    if !arg {
      #if SHOULD_LOG `log(message, ..args);
      `return false;
    }
  }
  
  //TODO: Name casing/format mapper?
  construct_cast_json :: (type: *Type_Info, notes: [] string, blacklist: [] string) -> string {
    builder: String_Builder;
    init_string_builder(*builder,, temp);
    
    type_name := get_type_name(type);
    print_to_builder(*builder, "// For '%' with notes: %\n", type_name, notes);
    print_to_builder(*builder, "_cast_json :: (json: *JSON_Element, out: *$T, $should_assert := true, log: (f: string, a: ..Any, t := false) -> s64 = cast_json_log_none, $scope: Code) -> success: bool {\n");
    print_to_builder(*builder, "  if array_find(notes, \"$Ignore\") return true;\n");
    print_to_builder(*builder, "  assert_cast_json(xx out, \"Attempted to cast %%, but out was null\", print_json(json,, temp));\n");
    print_to_builder(*builder, "  assert_cast_json(json || array_find(notes, \"?\"), \"json was null, but '%' was not marked as optional ('@?')\");\n", get_type_name(type,, temp));
    #if SHOULD_LOG print_to_builder(*builder, "  log(\"Casting %% to %\", print_json(json,, temp));\n", type_name);
    print_to_builder(*builder, "  value: T;\n");
    print_to_builder(*builder, "  if !json {\n");
    print_to_builder(*builder, "    out.* = value;\n");
    print_to_builder(*builder, "    return true;\n");
    print_to_builder(*builder, "  }\n");
    
    if #complete type.type == {
      case .INTEGER; #through;
      case .FLOAT;
        print_to_builder(*builder, "  assert_cast_json(json.kind == .NUMBER, \"Expected a number, but got %%\", print_json(json,, temp));\n");
        print_to_builder(*builder, "  value = xx as_number(json).value;\n");
      
      case .BOOL;
        print_to_builder(*builder, "  assert_cast_json(json.kind == .BOOLEAN, \"Expected a boolean, but got %%\", print_json(json,, temp));\n");
        print_to_builder(*builder, "  value = xx as_boolean(json).value;\n");
      
      case .STRING;
        print_to_builder(*builder, "  assert_cast_json(json.kind == .STRING, \"Expected a string, but got %%\", print_json(json,, temp));\n");
        print_to_builder(*builder, "  value = copy_string(as_string(json).value);\n");
      
      case .POINTER;
        t: *Type_Info_Pointer = xx type;
        print_to_builder(*builder, "  value = alloc(%);\n", t.pointer_to.runtime_size);
        print_to_builder(*builder, "  cast_json(json, value, .%, .%, should_assert, log, scope);\n", notes, blacklist);
      
      case .VOID;
      
      case .STRUCT;
        t: *Type_Info_Struct = xx type;
        print_to_builder(*builder, "  success: bool;\n");
        assert(!(t.textual_flags & .UNION), "Cannot cast JSON into the union '%', or any union\n", type_name);
        if array_find(notes, "$Table") {
          //TODO: Round-trip the key parsing
          print_to_builder(*builder, "  assert_cast_json(json.kind == .OBJECT, \"Expected an object for $Table, but got %%\", print_json(json,, temp));\n");
          print_to_builder(*builder, "  for as_object(json).value {\n");
          print_to_builder(*builder, "    key_string := JSON_String.{value = it_index};\n");
          print_to_builder(*builder, "    member_key: out.Key_Type;\n");
          print_to_builder(*builder, "    success = cast_json(*key_string, *member_key, .[], .%, should_assert, log, scope);\n", blacklist);
          print_to_builder(*builder, "    assert_cast_json(success, \"Could not cast %% to the key '%%'\", print_json(*key_string,, temp), out.Key_Type);\n");
          print_to_builder(*builder, "    member_value := find_or_add(*value, member_key);\n");
          print_to_builder(*builder, "    success = cast_json(it, member_value, .[], .%, should_assert, log, scope);\n", blacklist);
          print_to_builder(*builder, "    assert_cast_json(success, \"Could not cast %% to the value '%%'\", print_json(it,, temp), out.Value_Type);\n");
          print_to_builder(*builder, "  }\n");
        } else {
          for t.members {
            if it.flags & .CONSTANT continue;
            if array_find(it.notes, "$Ignore") continue; // Ignore it here to not trigger the assert after the '_' case
            if it.flags & .USING || it.name == "_" {
              print_to_builder(*builder, "  success = cast_json(json, *value.%, .%, .%, should_assert, log, scope);\n", it.name, it.notes, blacklist);
            } else {
              print_to_builder(*builder, "  assert_cast_json(json.kind == .OBJECT || json.kind == .ARRAY, \"Expected an array or object because '%' is a struct, but got %%\", print_json(json,, temp));\n", type_name);
              print_to_builder(*builder, "  if json.kind == .OBJECT {\n");
              print_to_builder(*builder, "    success = cast_json(get_element(as_object(json), \"%\"), *value.%, .%, .%, should_assert, log, scope);\n", it.name, it.name, it.notes, blacklist);
              print_to_builder(*builder, "  } else {\n");
              print_to_builder(*builder, "    success = cast_json(get_element(as_array(json), %), *value.%, .%, .%, should_assert, log, scope);\n", it_index, it.name, it.notes, blacklist);
              print_to_builder(*builder, "  }\n");
            }
            print_to_builder(*builder, "  assert_cast_json(success, \"Could not cast %% to the struct '%' because casting the member '%' (%) failed\", print_json(json,, temp));\n", type_name, it.name, get_type_name(it.type));
          }
        }
      
      case .ARRAY;
        t: *Type_Info_Array = xx type;
        print_to_builder(*builder, "  assert_cast_json(json.kind == .ARRAY, \"Expected an array for '%', but got %%\", print_json(json,, temp));\n", type_name);
        print_to_builder(*builder, "  array := as_array(json).value;\n");
        element_name := get_type_name(t.element_type);
        if t.array_type == .VIEW {
          print_to_builder(*builder, "  V :: #insert,scope(scope) \"#type %;\";\n", element_name);
          print_to_builder(*builder, "  value = .{array.count, alloc(array.count * size_of(V))};\n");
        }
        print_to_builder(*builder, "  for array\n");
        if t.array_type == {
          case .FIXED; #through;
          case .VIEW;
            print_to_builder(*builder, "    cast_json(it, *value[it_index], .%, .%, should_assert, log, scope);\n", notes, blacklist);
          case .RESIZABLE;
            print_to_builder(*builder, "    cast_json(it, array_add(*value), .%, .%, should_assert, log, scope);\n", notes, blacklist);
        }
      
      case .ANY;
        print_to_builder(*builder, "  success := false;\n");
        has_unblacklisted_notes := false;
        for notes {
          if array_find(blacklist, it) continue;
          has_unblacklisted_notes = true;
          if it == {
            case "$Null";
              print_to_builder(*builder, "  if !success && json.kind == .NULL {\n");
              print_to_builder(*builder, "    success = true;\n");
              print_to_builder(*builder, "    value = Any.{type_info(void), null};\n");
              print_to_builder(*builder, "  }\n");
            case;
              print_to_builder(*builder, "  if !success {\n");
              print_to_builder(*builder, "    V :: #insert,scope(scope) \"#type %;\";\n", it);
              print_to_builder(*builder, "    test: V;\n");
              print_to_builder(*builder, "    success = cast_json(json, *test, .[], .%, false, log, scope);\n", blacklist);
              print_to_builder(*builder, "    if success {\n");
              print_to_builder(*builder, "      value = Any.{type_info(V), alloc(size_of(V))};\n");
              print_to_builder(*builder, "      memcpy(value.value_pointer, *test, size_of(V));\n");
              print_to_builder(*builder, "    }\n");
              print_to_builder(*builder, "  }\n");
          }
        }
        if has_unblacklisted_notes {
          print_to_builder(*builder, "  assert_cast_json(success, \"Could not cast %% to any of the following: [");
          for notes {
            if !array_find(blacklist, it)
            if it_index append(*builder, ", ");
            append(*builder, it);
          }
          print_to_builder(*builder, "  ]\", print_json(json,, temp));\n");
        } else {
          print_to_builder(*builder, "  value = Any.{type_info(JSON_Element), copy_json(json)};\n");
          // print_to_builder(*builder, "  if json.kind == {\n");
          // print_to_builder(*builder, "    case .NULL;\n");
          // print_to_builder(*builder, "      value = Any.{type_info(void), null};\n");
          // print_to_builder(*builder, "    case .BOOLEAN;\n");
          // print_to_builder(*builder, "      value = Any.{type_info(bool), alloc(size_of(bool))};\n");
          // print_to_builder(*builder, "      (cast(*bool) value.value_pointer).* = as_boolean(json).value;\n");
          // print_to_builder(*builder, "    case .NUMBER;\n");
          // print_to_builder(*builder, "      value = Any.{type_info(float64), alloc(size_of(float64))};\n");
          // print_to_builder(*builder, "      (cast(*float64) value.value_pointer).* = as_number(json).value;\n");
          // print_to_builder(*builder, "    case .STRING;\n");
          // print_to_builder(*builder, "      value = Any.{type_info(string), alloc(size_of(string))};\n");
          // print_to_builder(*builder, "      (cast(*string) value.value_pointer).* = copy_string(as_string(json).value);\n");
          // print_to_builder(*builder, "    case .ARRAY;\n");
          // print_to_builder(*builder, "      array: *[] Any = alloc(size_of([] Any));\n");
          // print_to_builder(*builder, "      value = Any.{type_info([] Any), array};\n");
          // print_to_builder(*builder, "      json_array := as_array(json).value;\n");
          // print_to_builder(*builder, "      array.count = json_array.count;\n");
          // print_to_builder(*builder, "      array.data = alloc(size_of(Any) * array.count);\n");
          // print_to_builder(*builder, "      for json_array\n");
          // print_to_builder(*builder, "        cast_json(it, *(array.*[it_index]), .%, .%, should_assert, log, scope);\n", notes, blacklist);
          // print_to_builder(*builder, "    case .OBJECT;\n");
          // print_to_builder(*builder, "      object: *Table(string, Any) = alloc(size_of(Table(string, Any)));\n");
          // print_to_builder(*builder, "      value = Any.{type_info(Table(string, Any)), object};\n");
          // print_to_builder(*builder, "      json_object := as_object(json).value;\n");
          // print_to_builder(*builder, "      for json_object\n");
          // print_to_builder(*builder, "        cast_json(it, find_or_add(object, copy_string(it_index)), .%, .%, should_assert, log, scope);\n", notes, blacklist);
          // print_to_builder(*builder, "  }\n");
        }
      
      case .ENUM;
        build_switch_case :: (builder: *String_Builder, t: *Type_Info_Enum, type_name: string, value: string, wrapper: string, operation: string, indentation: string) {
          print_to_builder(builder, "%check := %;\n", indentation, value);
          print_to_builder(builder, "%if check == {\n", indentation);
          for t.names print_to_builder(builder, "%  case %; value % .%;\n", indentation, tprint(wrapper, it), operation, it);
          print_to_builder(builder, "%  case; assert_cast_json(false, \"The provided value '%%' didn't match any of the options in '%'\", check);\n", indentation, type_name);
          print_to_builder(builder, "%}\n", indentation);
        }
        t: *Type_Info_Enum = xx type;
        VALIDATE_ENUMS :: false;
        #if VALIDATE_ENUMS {
          if t.enum_type_flags & .FLAGS {
            print_to_builder(*builder, "  if json.kind == .NUMBER {\n");
            // This isn't a perfect check, since it allows single bits when they're part of a multi-bit flag.
            // However, if would be way to expensive to fully check it, so we'll just trust that the enums
            // are somewhat reasonable.
            print_to_builder(*builder, "    value = cast(T) as_number(json).value;\n");
            print_to_builder(*builder, "    check := value;\n");
            for t.names print_to_builder(*builder, "    check &= ~.%;\n", it);
            print_to_builder(*builder, "    assert_cast_json(!check, \"The provided enum_flags value '%%' didn't match any of the options in '%'\", value);\n",  type_name);
            print_to_builder(*builder, "  } else if json.kind == .ARRAY {\n");
            print_to_builder(*builder, "    array := as_array(json).value;\n");
            print_to_builder(*builder, "    for array {\n");
            print_to_builder(*builder, "      if json.kind == .STRING {\n");
            build_switch_case(*builder, t, type_name, "as_string(json).value", "\"%\"", "|=", "        ");
            print_to_builder(*builder, "      } else if json.kind == .NUMBER {\n");
            build_switch_case(*builder, t, type_name, tprint("cast(T) as_number(json).value"), ".%", "|=", "        ");
            print_to_builder(*builder, "      } else assert_cast_json(false, \"Expected only strings and numbers within the array because '%' is an enum, but got %%\", print_json(json,, temp));\n", type_name);
            print_to_builder(*builder, "    }\n");
            print_to_builder(*builder, "  } else assert_cast_json(false, \"Expected an array or number because '%' is an enum_flags, but got %%\", print_json(json,, temp));\n", type_name);
          } else {
            print_to_builder(*builder, "  if json.kind == .STRING {\n");
            build_switch_case(*builder, t, type_name, "as_string(json).value", "\"%\"", "=", "    ");
            print_to_builder(*builder, "  } else if json.kind == .NUMBER {\n");
            build_switch_case(*builder, t, type_name, tprint("cast(T) as_number(json).value"), ".%", "=", "    ");
            print_to_builder(*builder, "  } else assert_cast_json(false, \"Expected a string or number because '%' is an enum, but got %%\", print_json(json,, temp));\n", type_name);
          }
        } else {
          if t.enum_type_flags & .FLAGS {
            print_to_builder(*builder, "  if json.kind == .NUMBER {\n");
            print_to_builder(*builder, "    value = xx as_number(json).value;\n");
            print_to_builder(*builder, "  } else if json.kind == .ARRAY {\n");
            print_to_builder(*builder, "    array := as_array(json).value;\n");
            print_to_builder(*builder, "    for array {\n");
            print_to_builder(*builder, "      if json.kind == .STRING {\n");
            //TODO: Store the string in a map and return it on round trip
            build_switch_case(*builder, t, type_name, "as_string(json).value", "\"%\"", "|=", "        ");
            print_to_builder(*builder, "      } else if json.kind == .NUMBER {\n");
            print_to_builder(*builder, "        value |= xx as_number(json).value;\n");
            print_to_builder(*builder, "      } else assert_cast_json(false, \"Expected only strings and numbers within the array because '%' is an enum, but got %%\", print_json(json,, temp));\n", type_name);
            print_to_builder(*builder, "    }\n");
            print_to_builder(*builder, "  } else assert_cast_json(false, \"Expected an array or number because '%' is an enum_flags, but got %%\", print_json(json,, temp));\n", type_name);
          } else {
            print_to_builder(*builder, "  if json.kind == .STRING {\n");
            //TODO: Store the string in a map and return it on round trip
            build_switch_case(*builder, t, type_name, "as_string(json).value", "\"%\"", "=", "    ");
            print_to_builder(*builder, "  } else if json.kind == .NUMBER {\n");
            print_to_builder(*builder, "    value = xx as_number(json).value;\n");
            print_to_builder(*builder, "  } else assert_cast_json(false, \"Expected a string or number because '%' is an enum, but got %%\", print_json(json,, temp));\n", type_name);
          }
        }
      
      case .VARIANT;
        t: *Type_Info_Variant = xx type;
        variant_name := get_type_name(t.variant_of);
        print_to_builder(*builder, "  V :: #insert,scope(scope) \"#type %;\";\n", variant_name);
        print_to_builder(*builder, "  success := cast_json(json, cast(*V) *value, .%, .%, should_assert, log, scope);\n", notes, blacklist);
        print_to_builder(*builder, "  assert_cast_json(success, \"Could not cast '%%' to the variant % of '%'\", print_json(json,, temp));\n", type_name, variant_name);
      
      // No good way to parse these, so we'll just ignore them
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
  
  #insert #run construct_cast_json(type_info(T), notes, blacklist);
  return _cast_json(json, out, should_assert, log, scope);
}

cast_json :: (value: *void, type: *Type_Info, notes: [] string = .[], log: (f: string, a: ..Any, t := false) -> s64 = cast_json_log_none) -> json: *JSON_Element {
  assert(xx value, "Cannot cast a null value (of type % with notes %)", type, notes);
  
  cast_value :: ($T: Type) -> T #expand {
    return (cast(*T) `value).*;
  }
  
  if array_find(notes, "$Ignore") return null;
  optional := array_find(notes, "?");
  if !value return null;
  
  #if SHOULD_LOG log("Casting % with notes %: %", get_type_name(type,, temp), notes, Any.{type = type, value_pointer = value});
  if #complete type.type == {
    case .INTEGER;
      //TODO Serialize as integer instead of float
      t: *Type_Info_Integer = xx type;
      if t.signed {
        if t.runtime_size == {
          case size_of(s8);
            _value := cast_value(s8);
            if optional && _value == 0 return null;
            return make_number(xx _value);
          case size_of(s16);
            _value := cast_value(s16);
            if optional && _value == 0 return null;
            return make_number(xx _value);
          case size_of(s32);
            _value := cast_value(s32);
            if optional && _value == 0 return null;
            return make_number(xx _value);
          case size_of(s64);
            _value := cast_value(s64);
            if optional && _value == 0 return null;
            return make_number(xx _value);
        }
      } else {
        if t.runtime_size == {
          case size_of(u8);
            _value := cast_value(u8);
            if optional && _value == 0 return null;
            return make_number(xx _value);
          case size_of(u16);
            _value := cast_value(u16);
            if optional && _value == 0 return null;
            return make_number(xx _value);
          case size_of(u32);
            _value := cast_value(u32);
            if optional && _value == 0 return null;
            return make_number(xx _value);
          case size_of(u64);
            _value := cast_value(u64);
            if optional && _value == 0 return null;
            return make_number(xx _value);
        }
      }
      return null;
      
    case .FLOAT;
      if type.runtime_size == {
        case size_of(float32);
          _value := cast_value(float32);
          if optional && _value == 0 return null;
          return make_number(_value);
        case size_of(float64);
          _value := cast_value(float64);
          if optional && _value == 0 return null;
          return make_number(_value);
      }
      return null;
    
    case .BOOL;
      _value := cast_value(bool);
      if optional && _value == false return null;
      return make_boolean(_value);
    
    case .STRING;
      _value := cast_value(string);
      if optional && _value == "" return null;
      return make_string(copy_string(_value));
    
    case .POINTER;
      t: *Type_Info_Pointer = xx type;
      _value := cast_value(*void);
      if optional && _value == null return null;
      if !_value return make_null();
      return cast_json(_value, t.pointer_to, .[], log);
    
    case .VOID;
      return null;
    
    case .STRUCT;
      t: *Type_Info_Struct = xx type;
      assert(!(t.textual_flags & .UNION), "Encountered '%', but cannot serialize unions to JSON", get_type_name(type,, temp));
      if (array_find(notes, "$Table")) {
        _value := cast_value(Table(void, void));
        assert(t.specified_parameters.count >= 2 && t.specified_parameters[0].name == "Key_Type" && t.specified_parameters[1].name == "Value_Type", "Expected a Hash_Table.Table because of '$Table', but got '%'", get_type_name(t,, temp));
        if optional && _value.allocated == 0 return null;
        key_type := t.specified_parameters[0].type;
        value_type := t.specified_parameters[1].type;
        key_is_string := get_type(key_type).type == .STRING;
        hash_size := size_of(_value.Entry);
        entry_size := hash_size + key_type.runtime_size + value_type.runtime_size;
        object := make_object();
        for 0 .. _value.entries.count - 1 {
          entry_data := _value.entries.data + it * entry_size;
          hash := (cast(*_value.Entry) entry_data).hash;
          if hash < FIRST_VALID_HASH continue;
          key_data := entry_data + hash_size;
          value_data := key_data + key_type.runtime_size;
          key := ifx key_is_string
            then copy_string((cast(*string) key_data).*)
            else print_json(cast_json(key_data, key_type, .[], log));
          value := cast_json(value_data, value_type, .[], log);
          set_element(object, key, value);
        }
        return object;
      } else {
        object := make_object();
        data: *void = xx value;
        for t.members {
          member_data := data + it.offset_in_bytes;
          notes := it.notes;
          if optional && !array_find(notes, "?") {
            notes = .{it.notes.count + 1, alloc((it.notes.count + 1) * size_of(string))};
            memcpy(notes.data, it.notes.data, it.notes.count * size_of(string));
            notes[it.notes.count] = "?";
          }
          member := cast_json(member_data, it.type, notes, log);
          if notes.count != it.notes.count
            array_free(notes);
          if ((it.flags & .USING) || it.name == "_") && member.kind == .OBJECT {
            for as_object(member).value
              set_element(object, copy_string(it_index), it);
          } else if it.name == "_" {
            free_json(object);
            return member;
          } else {
            set_element(object, copy_string(it.name), member);
          }
        }
        if optional && object.value.count == 0 {
          free_json(object);
          return null;
        }
        return object;
      }
    
    case .ARRAY;
      t: *Type_Info_Array = xx type;
      _value := cast_value([] void);
      if optional && _value.count == 0 && _value.data == null return null;
      array := make_array();
      for < _value.count - 1 .. 0 {
        member := _value.data + it * t.element_type.runtime_size;
        set_element(array, it, cast_json(member, t.element_type, .[], log));
      }
      return array;
    
    case .ANY;
      _value := cast_value(Any);
      if optional && _value.type == null && _value.value_pointer == null return null;
      if _value.type != null && _value.value_pointer == null return make_null();
      if _value.type == type_info(JSON_Element) return cast_any(_value, JSON_Element);
      return cast_json(_value.value_pointer, _value.type, .[], log);
    
    case .ENUM;
      t: *Type_Info_Enum = xx type;
      return cast_json(value, t.internal_type, notes, log);
    
    case .VARIANT;
      t: *Type_Info_Variant = xx type;
      return cast_json(value, t.variant_of, notes, log);
    
    case .PROCEDURE; #through;
    case .OVERLOAD_SET; #through;
    case .POLYMORPHIC_VARIABLE; #through;
    case .TYPE; #through;
    case .CODE; #through;
    case;
      return null;
  }
}

copy_casted_json :: (value: *void, type: *Type_Info, out: *void, notes: [] string = .[], log: (f: string, a: ..Any, t := false) -> s64 = cast_json_log_none) {
  if !value return;
  assert(xx type, "Cannot copy casted json with a null type");
  assert(xx out, "Cannot copy casted json to a null output");
  
  cast_value :: ($T: Type) -> T #expand {
    return (cast(*T) `value).*;
  }
  
  set_out :: (value: $T) #expand {
    (cast(*T) `out).* = value;
  }
  
  json_log("Copying % to %: %", get_type_name(type,, temp), out, Any.{type, value});
  
  if #complete type.type == {
    case .INTEGER; #through;
    case .FLOAT; #through;
    case .BOOL;
      memcpy(out, value, type.runtime_size);
    
    case .STRING;
      set_out(copy_string(cast_value(string)));
    
    case .POINTER;
      t: *Type_Info_Pointer = xx type;
      _value := cast_value(*void);
      if !_value set_out(_value);
      else {
        _out := alloc(t.pointer_to.runtime_size);
        copy_casted_json(_value, t.pointer_to, _out, notes, log);
        set_out(_out);
      }
    
    case .VOID;
    
    case .STRUCT;
      t: *Type_Info_Struct = xx type;
      if t.textual_flags & .UNION return;
      if (array_find(notes, "$Table")) {
        assert(t.specified_parameters.count >= 2 && t.specified_parameters[0].name == "Key_Type" && t.specified_parameters[1].name == "Value_Type", "Expected a Hash_Table.Table because of '$Table', but got '%'", get_type_name(t,, temp));
        _value := cast_value(Table(void, void));
        _out := _value;
        key_type := t.specified_parameters[0].type;
        value_type := t.specified_parameters[1].type;
        key_is_string := get_type(key_type).type == .STRING;
        hash_size := size_of(_value.Entry);
        entry_size := hash_size + key_type.runtime_size + value_type.runtime_size;
        _out.entries.data = alloc(_out.allocated * entry_size);
        for 0 .. _out.entries.count - 1 {
          value_entry := _value.entries.data + it * entry_size;
          out_entry := _out.entries.data + it * entry_size;
          hash := (cast(*_value.Entry) value_entry).hash;
          memcpy(out_entry, *hash, entry_size);
          if hash < FIRST_VALID_HASH continue;
          key_offset := hash_size;
          value_offset := key_offset + key_type.runtime_size;
          copy_casted_json(value_entry + key_offset, key_type, out_entry + key_offset, .[], log);
          copy_casted_json(value_entry + value_offset, value_type, out_entry + value_offset, .[], log);
        }
      } else {
        if t.initializer t.initializer(out);
        for t.members {
          if it.flags & .CONSTANT continue;
          if array_find(it.notes, "$Ignore") continue;
          copy_casted_json(xx (cast(*u8) value + it.offset_in_bytes), it.type, xx (cast(*u8) out + it.offset_in_bytes), it.notes, log);
        }
      }
    
    case .ARRAY;
      t: *Type_Info_Array = xx type;
      assert(t.array_type != .FIXED, "Cannot copy fixed arrays yet");
      element_size := t.element_type.runtime_size;
      if t.array_type == .RESIZABLE {
        _value := cast_value([..] void);
        _out := _value;
        _out.data = alloc(_value.allocated * element_size);
        for 0.._value.count-1
          copy_casted_json(_value.data + it * element_size, t.element_type, _out.data + it * element_size, .[], log);
        set_out(_out);
      } else {
        _value := cast_value([] void);
        _out := _value;
        _out.data = alloc(_value.count * element_size);
        for 0.._value.count-1
          copy_casted_json(_value.data + it * element_size, t.element_type, _out.data + it * element_size, .[], log);
        set_out(_out);
      }
    
    case .ANY;
      _value := cast_value(Any);
      if !_value.value_pointer set_out(_value);
      else if _value.type == type_info(JSON_Element) set_out(Any.{_value.type, copy_json(cast_any(_value, JSON_Element))});
      else {
        _out := Any.{_value.type, alloc(_value.type.runtime_size)};
        copy_casted_json(_value.value_pointer, _value.type, _out.value_pointer, .[], log);
        set_out(_out);
      }
    
    case .ENUM;
      t: *Type_Info_Enum = xx type;
      copy_casted_json(value, t.internal_type, out, notes, log);
    
    case .VARIANT;
      t: *Type_Info_Variant = xx type;
      copy_casted_json(value, t.variant_of, out, notes, log);
    
    case .PROCEDURE;
    case .OVERLOAD_SET;
    case .POLYMORPHIC_VARIABLE;
    case .TYPE;
    case .CODE;
    case;
  }
}

free_casted_json :: (value: *void, type: *Type_Info, log: (f: string, a: ..Any, t := false) -> s64 = cast_json_log_none) {
  if !value || !type return;
  
  cast_value :: ($T: Type) -> *T #expand {
    return cast(*T) `value;
  }
  
  json_log("Freeing %: %", get_type_name(type,, temp), Any.{type, value});
  
  if #complete type.type == {
    case .INTEGER;
    case .FLOAT;
    case .BOOL;
    
    case .STRING;
      str := cast_value(string);
      free(str.*);
      str.* = "";
    
    case .POINTER;
      t: *Type_Info_Pointer = xx type;
      ptr := cast_value(*void);
      free_casted_json(ptr.*, t.pointer_to, log);
      free(ptr.*);
      ptr.* = null;
    
    case .VOID;
    
    case .STRUCT;
      t: *Type_Info_Struct = xx type;
      if array_find(t.notes, "$Table") {
        table := cast_value(Table(void, void));
        assert(t.specified_parameters.count >= 2 && t.specified_parameters[0].name == "Key_Type" && t.specified_parameters[1].name == "Value_Type", "Expected a Hash_Table.Table because of '$Table', but got '%'", get_type_name(t,, temp));
        key_type := t.specified_parameters[0].type;
        value_type := t.specified_parameters[1].type;
        key_is_string := get_type(key_type).type == .STRING;
        hash_size := size_of(table.Entry);
        entry_size := hash_size + key_type.runtime_size + value_type.runtime_size;
        for 0 .. table.entries.count - 1 {
          entry_data := table.entries.data + it * entry_size;
          hash := (cast(*table.Entry) entry_data).hash;
          if hash < FIRST_VALID_HASH continue;
          key_data := entry_data + hash_size;
          value_data := key_data + key_type.runtime_size;
          free_casted_json(key_data, key_type, log);
          free_casted_json(value_data, value_type, log);
        }
        deinit(table);
        table.count = 0;
        table.allocated = 0;
        table.slots_filled = 0;
        array_reset(*table.entries);
      } else {
        for t.members {
          if it.flags & .CONSTANT continue;
          if array_find(it.notes, "$Ignore") continue;
          free_casted_json(xx (cast(*u8) value + it.offset_in_bytes), it.type, log);
        }
      }
    
    case .ARRAY;
      t: *Type_Info_Array = xx type;
      array := cast_value([] void);
      for 0 .. array.count - 1
        free_casted_json(array.data + it * t.element_type.runtime_size, t.element_type, log);
      if t.array_type == .RESIZABLE
        array_reset(cast_value([..] void));
      else if t.array_type == .VIEW
        array_reset(array);
    
    case .ANY;
      any := cast_value(Any);
      if any.type == type_info(JSON_Element) free_json(cast_any(any.*, JSON_Element));
      else {
        free_casted_json(any.value_pointer, any.type, log);
        free(any.value_pointer);
      }
      any.* = Any.{};
    
    case .ENUM;
    
    case .VARIANT;
      t: *Type_Info_Variant = xx type;
      free_casted_json(value, t.variant_of, log);
    
    case .PROCEDURE;
    case .OVERLOAD_SET;
    case .POLYMORPHIC_VARIABLE;
    case .TYPE;
    case .CODE;
    case;
  }
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
      append_struct_member_value :: (builder: *String_Builder, parent: *Type_Info_Struct, member: Type_Info_Struct_Member) {
        data: *u8 = parent.constant_storage.data + member.offset_into_constant_storage;
        if member.type.type == .TYPE {
          append(builder, get_type_name((cast(**Type_Info) data).*));
          } else if member.type.type == .PROCEDURE {
          print_to_builder(builder, "0x%", (cast(**void) data).*);
        } else {
          value: Any;
          value.type = member.type;
          value.value_pointer = data;
          print_to_builder(builder, "%", value);
        }
      }
      append_struct_member :: (builder: *String_Builder, parent: *Type_Info_Struct, member: Type_Info_Struct_Member, is_polymorph_variable: bool, print_delimiter: bool) {
        assert(!(member.flags & .IMPORTED), "Not yet implemented");
        if member.flags & .AS append(builder, "#as ");
        if member.flags & .USING append(builder, "using ");
        print_to_builder(builder, "% : %", member.name, get_type_name(member.type));
        if member.offset_into_constant_storage > -1 {
          append(builder, ifx is_polymorph_variable || !(member.flags & .CONSTANT) then " = " else " : ");
          append_struct_member_value(builder, parent, member);
        }
        if print_delimiter
          append(builder, ifx is_polymorph_variable then "," else ";");
        for member.notes
          print_to_builder(builder, " @%", it);
        if print_delimiter append(builder, " ");
      }
      
      t: *Type_Info_Struct = xx type;
      builder: String_Builder;
      init_string_builder(*builder,, temp);
      if t.name {
        append(*builder, t.name);
        if t.polymorph_source_struct {
          append(*builder, "(");
          for t.specified_parameters {
            assert(!(it.flags & .IMPORTED), "Not yet implemented");
            if it_index append(*builder, ", ");
            if it.offset_into_constant_storage > -1 {
              append(*builder, it.name);
              append(*builder, " = ");
              append_struct_member_value(*builder, t, it);
            }
          }
          append(*builder, ")");
        }
      } else {
        append(*builder, ifx t.textual_flags & .UNION then "union" else "struct");
        if t.textual_flags & .TYPE_INFO_NONE append(*builder, " #type_info_none");
        if t.textual_flags & .TYPE_INFO_NO_SIZE_COMPLAINT append(*builder, " #type_info_no_size_complaint");
        if t.textual_flags & .TYPE_INFO_PROCEDURES_ARE_VOID_POINTERS append(*builder, " #type_info_procedures_are_void_pointers");
        if t.polymorph_source_struct {
          append(*builder, " (");
          for t.specified_parameters
            append_struct_member(*builder, t, it, true, it_index < t.specified_parameters.count - 1);
          append(*builder, ")");
        }
        for t.notes
          print_to_builder(*builder, " @%", it);
        append(*builder, " { ");
        for t.members
          append_struct_member(*builder, t, it, false, true);
        append(*builder, "}");
        if t.textual_flags & .FOREIGN append(*builder, " #foreign");
        if t.textual_flags & .NO_PADDING append(*builder, " #no_padding");
      }
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
      return tprint("$T_%", cast(*void) type);
    
    case .VARIANT;
      t: *Type_Info_Variant = xx type;
      if t.name return t.name;
      return tprint("#type%0% %",
        ifx t.variant_flags & .DISTINCT then ",distinct" else "",
        ifx t.variant_flags & .ISA then ",isa" else "",
        get_type_name(t.variant_of)); 
  }
}

#scope_file

get_type :: (type: *Type_Info) -> *Type_Info #expand {
  while type.type == .VARIANT
    type = (cast(*Type_Info_Variant) type).variant_of;
  return type;
}

BLACKLIST :: string.["?"];

cast_json_log_none :: (f: string, a: .. Any, t := false) -> s64 {
  return 0;
}

json_log :: (format: string, args: ..Any) -> s64 #expand {
  #if SHOULD_LOG return `log(format, ..args);
  else return 0;
}

#import "Json";
#import "Basic";
#import "Hash_Table";