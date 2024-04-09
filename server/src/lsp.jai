lsp_initialize :: (data: *void, params: LSP_Initialize_Params) -> LSP_Null {
  return .{};
}

#scope_file

LSP_Boolean  :: bool;
LSP_Integer  :: s32;
LSP_UInteger :: u32;
LSP_Decimal  :: float64;
LSP_String   :: string;
LSP_Array    :: [..] LSP_Any;
LSP_Null     :: struct { value: Any; @$Null }
LSP_Object   :: struct { value: Any; @$Object }
LSP_Any      :: struct {
  value: Any; @LSP_Null @LSP_Boolean @LSP_Integer @LSP_UInteger @LSP_Decimal @LSP_String @LSP_Array @LSP_Object
}

LSP_Cancel_Params :: struct {
  id: Any; @LSP_Integer @LSP_String
}

LSP_Progress_Params :: struct {
  LSP_Progress_Token :: struct {
    value: Any; @LSP_Integer @LSP_String
  }
  
  token: LSP_Progress_Token;
  value: Any;
}

LSP_Initialize_Params :: struct {
  
}