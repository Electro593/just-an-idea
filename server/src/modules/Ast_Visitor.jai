// Continue will skip all subnodes of the current
// Pointer will set `it to **Code_Node
// Reverse will push nodes to the stack before entering the body
Ast_Visitor :: struct(V := void) {
  union {
    root: *Code_Node;
    root_pointer: **Code_Node;
  }
  visited: *Table(*Code_Node, V);
}

for_expansion :: (visitor: Ast_Visitor, body: Code, flags: For_Flags) #expand {
  is_reverse :: flags & .REVERSE;
  is_pointer :: flags & .POINTER;

  // To avoid cycles, we're using a visited hashset. Callers can pass their own if they're
  // processing multiple roots to avoid iterating over the same nodes.
  ini :: initializer_of(visitor.V);
  _visited: Table(*Code_Node, visitor.V);
  _visited.entries = .{count = 0, data = null};
  visited := ifx visitor.visited then visitor.visited else *_visited;
  defer deinit(*_visited);

  // We're using an iterative depth-first traversal of the AST graph
  #if is_pointer {
    stack: [..] **Code_Node;
    array_add(*stack, visitor.root_pointer);
  } else {
    stack: [..] *Code_Node;
    array_add(*stack, visitor.root);
  }
  defer array_free(stack);

  //TODO: Test continue
  //TODO: Test that visited works with pointers

  while stack.count {
    popped := stack[stack.count - 1];
    curr := #ifx is_pointer then popped.* else popped; // Weird compiler bug doesn't like `it.*
    `it := popped;
    stack.count -= 1;

    #if is_pointer {
      push :: (node: **Code_Node) #expand {
        array_add(*`stack, node);
      }
    } else {
      push :: (node: **Code_Node) #expand {
        array_add(*`stack, node.*);
      }
    }

    // Mark the current node as visited, or skip it if we've already seen it
    if !curr || !popped continue;
    value, newly_added := find_or_add(visited, curr);
    // TODO: it_index should be the parent
    `it_index := newly_added;
    if newly_added {
      #if ini {
        ini(value);
      } else {
        memset(value, 0, size_of(visitor.V));
      }
    } else continue;

    #if !is_reverse {
      // The body comes first so 'continue' skips all subnodes
      #insert (remove=#assert false) body;

      // If is_pointer, body can change `it.* so we need to refresh curr's value
      #if is_pointer curr = popped.*;
    }

    // Add subnodes to the stack if we haven't already seen this node
    if newly_added {
      if #complete curr.kind == {
        case .UNINITIALIZED;

        case .BLOCK;
          using node: *Code_Block = xx curr;
          for * < members push(xx it);
          push(xx *belongs_to_struct);
          push(xx *parent);

        case .LITERAL;
          using node: *Code_Literal = xx curr;
          if value_type == {
            case .ARRAY;
              for * < array_literal_info.array_members push(xx it);
              push(xx *array_literal_info.alignment);
              push(xx *array_literal_info.element_type);

            case .STRUCT;
              for * < struct_literal_info.arguments push(xx it);
              push(xx *struct_literal_info.type_expression);

            case .POINTER;
              if pointer_literal_info.pointer_literal_type == {
                case .GLOBAL_SYMBOL;
                  push(xx *pointer_literal_info.global_symbol);

                case .STRING_OR_ARRAY_LITERAL_DATA_POINTER;
                  push(xx *pointer_literal_info.string_or_array_literal);
              }
          }

        case .IDENT;
          using node: *Code_Ident = xx curr;
          push(xx *resolved_declaration);

        case .UNARY_OPERATOR;
          using node: *Code_Unary_Operator = xx curr;
          push(xx *subexpression);

        case .BINARY_OPERATOR;
          using node: *Code_Binary_Operator = xx curr;
          push(xx *right);
          push(xx *left);

        case .PROCEDURE_BODY;
          using node: *Code_Procedure_Body = xx curr;
          push(xx *header);
          push(xx *block);

        case .PROCEDURE_CALL;
          using node: *Code_Procedure_Call = xx curr;
          if context_modification
            for * < context_modification.modification_expressions
              push(xx it);
          push(xx *macro_expansion_block);
          for * < arguments_sorted push(xx it);
          for * < arguments_unsorted {
            push(xx *it.expression);
            push(xx *it.name);
          }
          if overloads
            for * < overloads.* push(xx it);
          push(xx *resolved_procedure_expression);
          push(xx *procedure_expression);

        case .CONTEXT;
          using node: *Code_Context = xx curr;

        case .WHILE;
          using node: *Code_While = xx curr;
          push(xx *block);
          push(xx *condition);

        case .IF;
          using node: *Code_If = xx curr;
          push(xx *else_block);
          push(xx *then_block);
          push(xx *condition);

        case .LOOP_CONTROL;
          using node: *Code_Loop_Control = xx curr;
          push(xx *target_ident);

        case .CASE;
          using node: *Code_Case = xx curr;
          push(xx *owning_if);
          push(xx *then_block);
          push(xx *condition);

        case .RETURN;
          using node: *Code_Return = xx curr;
          for * < arguments_sorted push(xx it);
          for * < arguments_unsorted {
            push(xx *it.expression);
            push(xx *it.name);
          }

        case .FOR;
          using node: *Code_For = xx curr;
          push(xx *macro_expansion_procedure_call);
          push(xx *want_reverse_expression);
          push(xx *want_pointer_expression);
          push(xx *want_replacement_for_expansion);
          push(xx *index_decl);
          push(xx *ident_decl);
          push(xx *ident_it_index);
          push(xx *ident_it);
          push(xx *block);
          push(xx *iteration_expression_right);
          push(xx *iteration_expression);

        case .TYPE_DEFINITION;
          using node: *Code_Type_Definition = xx curr;

        case .TYPE_INSTANTIATION;
          using node: *Code_Type_Instantiation = xx curr;
          push(xx *array_dimension);
          push(xx *array_element_type);
          push(xx *type_directive_target);
          push(xx *pointer_to);
          push(xx *must_implement);
          push(xx *type_valued_expression);

        case .ENUM;
          using node: *Code_Enum = xx curr;
          for * < notes push(xx it);
          push(xx *block);
          push(xx *internal_type_inst);

        case .PROCEDURE_HEADER;
          using node: *Code_Procedure_Header = xx curr;
          for * < notes push(xx it);
          push(xx *body_or_null);
          for * < modify_directives push(xx it);
          push(xx *polymorph_source_header);
          push(xx *library_identifier);
          for * < parameter_usings push(xx it);
          for * < returns push(xx it);
          for * < arguments push(xx it);
          push(xx *constants_block);

        case .STRUCT;
          using node: *Code_Struct = xx curr;
          for * < notes push(xx it);
          push(xx *constants_block);
          push(xx *arguments_block);
          push(xx *block);
          for * < modify_directives push(xx it);

        case .COMMA_SEPARATED_ARGUMENTS;
          using node: *Code_Comma_Separated_Arguments = xx curr;
          for * < arguments push(xx *it.node);

        case .EXTRACT;
          using node: *Code_Extract = xx curr;
          push(xx *from);

        case .DIRECTIVE_BYTES;
          using node: *Code_Directive_Bytes = xx curr;
          push(xx *expression);

        case .MAKE_VARARGS;
          using node: *Code_Make_Varargs = xx curr;
          for * < expressions push(xx it);

        case .DECLARATION;
          using node: *Code_Declaration = xx curr;
          for * < notes push(xx it);
          push(xx *alignment_expression);
          push(xx *expression);
          push(xx *type_inst);
          push(xx *import_target);

        case .CAST;
          using node: *Code_Cast = xx curr;
          push(xx *expression);
          push(xx *target_type);

        case .DIRECTIVE_IMPORT;
          using node: *Code_Directive_Import = xx curr;
          push(xx *program_parameters_call);
          push(xx *module_parameters_call);

        case .DIRECTIVE_THIS;

        case .DIRECTIVE_THROUGH;
          using node: *Code_Directive_Through = xx curr;

        case .DIRECTIVE_LOAD;
          using node: *Code_Directive_Load = xx curr;

        case .DIRECTIVE_RUN;
          using node: *Code_Directive_Run = xx curr;
          push(xx *procedure);

        case .DIRECTIVE_CODE;
          using node: *Code_Directive_Code = xx curr;
          push(xx *expression);

          case .DIRECTIVE_POKE_NAME;
          using node: *Code_Directive_Poke_Name = xx curr;
          push(xx *module_struct);

        case .ASM;
          using node: *Code_Asm = xx curr;

        case .DIRECTIVE_BAKE;
          using node: *Code_Directive_Bake = xx curr;
          push(xx *procedure_call);

        case .DIRECTIVE_MODIFY;
          using node: *Code_Directive_Modify = xx curr;
          push(xx *block);

        case .DIRECTIVE_LIBRARY;
          using node: *Code_Directive_Library = xx curr;

        case .EXPRESSION_QUERY;
          using node: *Code_Expression_Query = xx curr;
          push(xx *expression_to_query);

        case .PUSH_CONTEXT;
          using node: *Code_Push_Context = xx curr;
          push(xx *block);
          push(xx *to_push);

        case .NOTE;
          using node: *Code_Note = xx curr;

        case .DIRECTIVE_PLACE;

        case .DIRECTIVE_SCOPE;
          using node: *Code_Directive_Scope = xx curr;

        case .TYPE_QUERY;
          using node: *Code_Type_Query = xx curr;
          push(xx *type_to_query);

        case .DIRECTIVE_LOCATION;
          using node: *Code_Directive_Location = xx curr;
          push(xx *expression);

        case .DIRECTIVE_MODULE_PARAMETERS;
          using node: *Code_Directive_Module_Parameters = xx curr;
          push(xx *common_code);
          push(xx *program_parameters);
          push(xx *module_parameters);

        case .DIRECTIVE_ADD_CONTEXT;

        case .DIRECTIVE_COMPILE_TIME;

        case .COMPOUND_DECLARATION;
          using node: *Code_Compound_Declaration = xx curr;
          for * < notes push(xx it);
          push(xx *alignment_expression);
          push(xx *declaration_properties);
          push(xx *comma_separated_assignment);

        case .DEFER;
          using node: *Code_Defer = xx curr;
          push(xx *block);

        case .USING;
          using node: *Code_Using = xx curr;
          push(xx *filter_expression);
          push(xx *expression);

        case .PLACEHOLDER;
          using node: *Code_Placeholder = xx curr;

        case .DIRECTIVE_INSERT;
          using node: *Code_Directive_Insert = xx curr;
          push(xx *remove_replacement);
          push(xx *continue_replacement);
          push(xx *break_replacement);
          push(xx *scope_redirection);
          push(xx *expression);
          push(xx *expansion);

        case .DIRECTIVE_PROCEDURE_NAME;
          using node: *Code_Directive_Procedure_Name = xx curr;
          push(xx *argument);

        case .DIRECTIVE_WILDCARD;
          using node: *Code_Directive_Wildcard = xx curr;

        case .DIRECTIVE_EXISTS;
          using node: *Code_Directive_Exists = xx curr;
          push(xx *sync_expression);
          push(xx *query_expression);

        case .DIRECTIVE_CONTEXT_TYPE;
          using node: *Code_Directive_Context_Type = xx curr;

        case .RESOLVED_OVERLOAD;
          using node: *Code_Resolved_Overload = xx curr;
          push(xx *source_expression);
          push(xx *result);

        case .DIRECTIVE_OVERLAY;
          using node: *Code_Directive_Overlay = xx curr;
          push(xx *declaration_or_using);
          push(xx *target_expression);
      }
    }

    #if is_reverse {
      // This is useful if you're serializing, for example, and want to invalidate pointer values
      #insert (remove=#assert false) body;
    }
  }
}

#scope_file

#import "Basic";
#import "Compiler";
#import "Hash_Table";
