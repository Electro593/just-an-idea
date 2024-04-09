LSP_Type :: enum {
  NULL;
  
  BOOLEAN;
  INTEGER;
  UINTEGER;
  DECIMAL;
  STRING;
  ARRAY;
  OBJECT;
}

LSP_Boolean  :: #type,distinct bool;
LSP_Integer  :: #type,distinct s32;
LSP_UInteger :: #type,distinct u32;
LSP_Decimal  :: #type,distinct float64;
LSP_String   :: #type,distinct string;
LSP_Array    :: #type,distinct [..] LSP_Any;
LSP_Object   :: #type,distinct *Table(string, LSP_Any);

LSP_Integer_Or_String :: struct @LSP_Compound_Type {
  type: enum {
    INTEGER :: LSP_Type.INTEGER;
    STRING :: LSP_Type.STRING;
  };
  union {
    integer: LSP_Integer;
    str: LSP_String;
  };
}

LSP_Any :: struct @LSP_Compound_Type {
  type: LSP_Type;
  union {
    boolean:  LSP_Boolean;
    integer:  LSP_Integer;
    uinteger: LSP_UInteger;
    decimal:  LSP_Decimal;
    str:      LSP_String;
    array:    LSP_Array;
    object:   LSP_Object;
  };
}

lsp__cancel_request : JSON_RPC_Method : (data: *void, _params: *JSON_Element) -> *JSON_Element {
  return make_null();
}

lsp_initialize : JSON_RPC_Method : (data: *void, _params: *JSON_Element) -> *JSON_Element {
  // params: LSP_Cancel_Params;
  // lsp_cast(_params, *params);
  return make_null();
}