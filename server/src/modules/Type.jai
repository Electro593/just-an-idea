print_type :: (builder: *String_Builder, info: *Type_Info, anonymous := false) {
	FORMAT_BASE_10 :: FormatInt.{ value = 0 };
	FORMAT_BASE_16 :: FormatInt.{ value = 0, base = 16 };

  if #complete info.type == {
  case .INTEGER;
    if info == type_info(int) {
			append(builder, "int");
		} else {
			t: *Type_Info_Integer = xx info;
			append(builder, ifx t.signed then "s" else "u");
			print_u64_base_n(builder, xx (t.runtime_size * 8), FORMAT_BASE_10);
		}

  case .FLOAT;
		append(builder, "float");
    if info != type_info(float)
			print_u64_base_n(builder, xx (info.runtime_size * 8), FORMAT_BASE_10);

  case .BOOL;
		append(builder, "bool");

  case .STRING;
		append(builder, "string");

  case .POINTER;
    t: *Type_Info_Pointer = xx info;
		append(builder, "*");
		print_type(builder, t.pointer_to, anonymous)

  case .PROCEDURE;
    t: *Type_Info_Procedure = xx info;
		append(builder, "#type (");
    for t.argument_types {
			if it_index then append(builder, ", ");
      print_type(builder, it, anonymous);
		}
    append(builder, ")");

		if t.return_types.count > 0 {
			append(builder, " -> ");

			if t.return_types.count == 1 {
				print_type(builder, t.return_types[0], anonymous);
			} else {
				append(builder, "(");
				for t.return_types {
					if it_index then append(builder, ", ");
					print_type(builder, it, anonymous);
				}
				append(builder, ")");
			}
		}

    if t.procedure_flags & .IS_ELSEWHERE
			append(builder, " #elsewhere");
    if t.procedure_flags & .IS_COMPILE_TIME_ONLY
			append(builder, " #compiler");
    if t.procedure_flags & .HAS_NO_CONTEXT
			append(builder, " #no_context");
    if t.procedure_flags & .IS_C_CALL
			append(builder, " #c_call");
    if t.procedure_flags & .IS_INTRINSIC
			append(builder, " #intrinsic");
    if t.procedure_flags & .IS_SYMMETRIC
			append(builder, " #symmetric");
    if t.procedure_flags & .IS_CPP_METHOD
			append(builder, " #cpp_method");
    if t.procedure_flags & .HAS_CPP_NON_POD_RETURN_TYPE
			append(builder, " #cpp_return_type_is_non_pod");

  case .VOID;
		append(builder, "void");

  case .STRUCT;
    print_struct_type(builder, xx info, anonymous);

  case .ARRAY;
    t: *Type_Info_Array = xx info;
		append(builder, "[");
    if #complete t.array_type == {
    case .FIXED; print_u64_base_n(builder, xx t.array_count, FORMAT_BASE_10);
		case .VIEW;
		case .RESIZABLE; append(builder, "..");
		}
		append(builder, "] ");
		print_type(builder, t.element_type, anonymous);

  case .OVERLOAD_SET;
    assert(false, "Cannot print type for overload set %", info.*);

  case .ANY;
		append(builder, "Any");

	case .ENUM;
		print_enum_type(builder, xx info, anonymous);

  case .POLYMORPHIC_VARIABLE;
    assert(false, "Cannot print type for polymorphic variable %", info.*);

  case .TYPE;
		append(builder, "Type");

	case .CODE;
		append(builder, "Code");

  case .VARIANT;
    t: *Type_Info_Variant = xx info;
    if !anonymous && t.name {
			append(builder, t.name);
			return;
		}

		append(builder, "#type");
		if t.variant_flags & .DISTINCT then ",distinct";
		else if t.variant_flags & .ISA then ",isa";

		append(builder, " ");
		print_type(builder, t.variant_of, anonymous);

  case .UNTYPED_LITERAL;
		assert(false, "Cannot print type for untyped literal %", info.*);

  case .UNTYPED_ENUM;
		assert(false, "Cannot print type for untyped enum %", info.*);
  }
}


#scope_file

print_struct_type :: (builder: *String_Builder, info: *Type_Info_Struct, anonymous := false) {
	if !anonymous && info.name {
    append(builder, info.name);

    if info.polymorph_source_struct {
      append(builder, "(");
      for info.specified_parameters {
        assert(!(it.flags & .IMPORTED), "Not yet implemented");
        if it_index then append(builder, ", ");
        if it.offset_into_constant_storage > -1 {
          append(builder, it.name);
          append(builder, " = ");
          append_struct_member_value(builder, info, it);
        }
      }
      append(builder, ")");
    }

		return;
  }

	// TODO: UNION_IS_TAGGED
	// TODO: NON_INSTANTIABLE, ALL_MEMBERS_UNINITIALIZED, POLYMORPHIC
	// TODO: INCOMPLETE, LOCAL
	// TODO: ALIGN, PLACE

	if info.textual_flags & .UNION
		append(builder, "union");
	else
		append(builder, "struct");

  if info.textual_flags & .TYPE_INFO_NONE
		append(builder, " #type_info_none");
  if info.textual_flags & .TYPE_INFO_NO_SIZE_COMPLAINT
		append(builder, " #type_info_no_size_complaint");
  if info.textual_flags & .TYPE_INFO_PROCEDURES_ARE_VOID_POINTERS
		append(*builder, " #type_info_procedures_are_void_pointers");

	if info.polymorph_source_struct {
    append(builder, " (");
    for info.specified_parameters
      print_struct_type_member(builder, info, it, true, it_index < info.specified_parameters.count - 1);
    append(builder, ")");
  }

  for info.notes {
    append(builder, " @");
		append(builder, it);
	}

  append(builder, " { ");
  for info.members
    print_struct_type_member(builder, info, it, false, true);
  append(builder, "}");

	if info.textual_flags & .FOREIGN
		append(builder, " #foreign");
  if info.textual_flags & .NO_PADDING
		append(builder, " #no_padding");
}

print_struct_type_member :: (
	builder: *String_Builder,
	parent: *Type_Info_Struct,
	member: Type_Info_Struct_Member,
	is_polymorph_variable: bool,
	print_delimiter: bool
) {
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

print_struct_type_member_value :: (
	builder: *String_Builder,
	parent: *Type_Info_Struct,
	member: Type_Info_Struct_Member
) {
  data: *u8 = parent.constant_storage.data + member.offset_into_constant_storage;
  if member.type.type == .TYPE {
    append(builder, get_type_name((cast(**Type_Info) data).*));
  } else if member.type.type == .PROCEDURE {
    print_to_builder(builder, "0x%", (cast(**void) data).*);
  } else {
    value: Any;
    value.type = member.type;
    value.value_pointer = data;
    print_item_to_builder(builder, value);
  }
}

print_enum_type :: (builder: *String_Builder, info: *Type_Info_Enum, anonymous := false) {
	if !anonymous && info.name {
		append(builder, info.name);
		return;
	}

	assert(
		!(info.status_flags & .INCOMPLETE),
		"Cannot print type for incomplete anonymous enum %",
		info.*
	);

	if info.enum_type_flags & .FLAGS
	then append(builder, "enum_flags ");
	else append(builder, "enum ");

	if info.internal_type != type_info(int)
		print_type(builder, info.internal_type, anonymous);

  if info.enum_type_flags & .COMPLETE  then append(builder, " #complete");
  if info.enum_type_flags & .SPECIFIED then append(builder, " #specified");

	assert(
		info.names.count == info.values.count,
		"The enum % has % names but % values",
		info.*,
		info.names.count,
		info.values.count
	);

  append(builder, " { ");
  for info.names {
		append(builder, it);

		value := info.values[it_index];
		next := ifx it_index then info.values[it_index - 1] + 1 else 0;
		overflowed := it_index && next == 0;
		if value != next || overflowed {
			append(builder, " :: ");

			if info.internal_type.signed && value < 0 && cast,no_check(u64) -value != 0 {
				append(builder, "-0x");
				print_u64_base_n(builder, xx -value, FORMAT_BASE_16);
			} else {
				append(builder, "0x");
				print_u64_base_n(builder, xx value, FORMAT_BASE_16);
			}
		}

		append(builder, "; ");
	}
  append(builder, "}");
}

#import "Basic";
