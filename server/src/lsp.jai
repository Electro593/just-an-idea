LSP_EOL :: string.["\n", "\r\n", "\r"];

LSP_PositionEncodingKind :: string;
LSP_PositionEncodingKind_UTF8 : LSP_PositionEncodingKind : "utf-8";
LSP_PositionEncodingKind_UTF16 : LSP_PositionEncodingKind : "utf-16";
LSP_PositionEncodingKind_UTF32 : LSP_PositionEncodingKind : "utf-32";

LSP_LanguageId :: string;
LSP_LanguageId_ABAP            :: "abap";
LSP_LanguageId_BAT             :: "bat";
LSP_LanguageId_BIBTEX          :: "bibtex";
LSP_LanguageId_CLOJURE         :: "clojure";
LSP_LanguageId_COFFEESCRIPT    :: "coffeescript";
LSP_LanguageId_C               :: "c";
LSP_LanguageId_CPP             :: "cpp";
LSP_LanguageId_CSHARP          :: "csharp";
LSP_LanguageId_CSS             :: "css";
LSP_LanguageId_DIFF            :: "diff";
LSP_LanguageId_DART            :: "dart";
LSP_LanguageId_DOCKERFILE      :: "dockerfile";
LSP_LanguageId_ELIXIR          :: "elixir";
LSP_LanguageId_ERLANG          :: "erlang";
LSP_LanguageId_FSHARP          :: "fsharp";
LSP_LanguageId_GIT_COMMIT      :: "git-commit";
LSP_LanguageId_GIT_REBASE      :: "git-rebase";
LSP_LanguageId_GO              :: "go";
LSP_LanguageId_GROOVY          :: "groovy";
LSP_LanguageId_HANDLEBARS      :: "handlebars";
LSP_LanguageId_HTML            :: "html";
LSP_LanguageId_INI             :: "ini";
LSP_LanguageId_JAVA            :: "java";
LSP_LanguageId_JAVASCRIPT      :: "javascript";
LSP_LanguageId_JAVASCRIPTREACT :: "javascriptreact";
LSP_LanguageId_JSON            :: "json";
LSP_LanguageId_LATEX           :: "latex";
LSP_LanguageId_LESS            :: "less";
LSP_LanguageId_LUA             :: "lua";
LSP_LanguageId_MAKEFILE        :: "makefile";
LSP_LanguageId_MARKDOWN        :: "markdown";
LSP_LanguageId_OBJECTIVE_C     :: "objective-c";
LSP_LanguageId_OBJECTIVE_CPP   :: "objective-cpp";
LSP_LanguageId_PERL            :: "perl";
LSP_LanguageId_PERL6           :: "perl6";
LSP_LanguageId_PHP             :: "php";
LSP_LanguageId_POWERSHELL      :: "powershell";
LSP_LanguageId_PUG             :: "jade";
LSP_LanguageId_PYTHON          :: "python";
LSP_LanguageId_R               :: "r";
LSP_LanguageId_RAZOR           :: "razor";
LSP_LanguageId_RUBY            :: "ruby";
LSP_LanguageId_RUST            :: "rust";
LSP_LanguageId_SCSS            :: "scss";
LSP_LanguageId_SASS            :: "sass";
LSP_LanguageId_SCALA           :: "scala";
LSP_LanguageId_SHADERLAB       :: "shaderlab";
LSP_LanguageId_SHELLSCRIPT     :: "shellscript";
LSP_LanguageId_SQL             :: "sql";
LSP_LanguageId_SWIFT           :: "swift";
LSP_LanguageId_TYPESCRIPT      :: "typescript";
LSP_LanguageId_TYPESCRIPTREACT :: "typescriptreact";
LSP_LanguageId_TEX             :: "tex";
LSP_LanguageId_VB              :: "vb";
LSP_LanguageId_XML             :: "xml";
LSP_LanguageId_XSL             :: "xsl";
LSP_LanguageId_YAML            :: "yaml";

LSP_MarkupKind :: string;
LSP_MarkupKind_PlainText :: "plaintext";
LSP_MarkupKind_Markdown :: "markdown";

LSP_ResourceOperationKind :: string;
LSP_ResourceOperationKind_Create :: "create";
LSP_ResourceOperationKind_Rename :: "rename";
LSP_ResourceOperationKind_Delete :: "delete";

LSP_FailureHandlingKind :: string;
LSP_FailureHandlingKind_Abort                 :: "abort";
LSP_FailureHandlingKind_Transactional         :: "transactional";
LSP_FailureHandlingKind_TextOnlyTransactional :: "textOnlyTransactional";
LSP_FailureHandlingKind_Undo :: "undo";

LSP_WorkDoneProgressKind :: string;
LSP_WorkDoneProgressKind_Begin  :: "begin";
LSP_WorkDoneProgressKind_Report :: "report";
LSP_WorkDoneProgressKind_End    :: "end";

LSP_TraceValue :: string;
LSP_TraceValue_Off      :: "off";
LSP_TraceValue_Messages :: "messages";
LSP_TraceValue_Verbose  :: "verbose";

LSP_DocumentUri :: string;

LSP_URI :: string;

LSP_Position :: struct {
  line: u32;
  character: u32;
}

LSP_Range :: struct {
  start: LSP_Position;
  end: LSP_Position;
}

LSP_TextDocumentItem :: struct {
  uri: LSP_DocumentUri;
  languageId: LSP_LanguageId;
  version: s32;
  text: string;
}

LSP_TextDocumentIdentifier :: struct {
  uri: LSP_DocumentUri;
}

LSP_VersionedTextDocumentIdentifier :: struct {
  #as using _: LSP_TextDocumentIdentifier;
  version: s32;
}

LSP_OptionalVersionedTextDocumentIdentifier :: struct {
  #as using _: LSP_TextDocumentIdentifier;
  version: Any; @s32 @$Null
}

LSP_TextDocumentPositionParams :: struct {
  textDocument: LSP_TextDocumentIdentifier;
  position: LSP_Position;
}

LSP_DocumentFilter :: struct {
  // At least one must exist
  language: string; @?
  scheme: string; @?
  pattern: string; @?
}

LSP_DocumentSelector :: [] LSP_DocumentFilter;

LSP_TextEdit :: struct {
  range: LSP_Range;
  newText: string;
}

LSP_ChangeAnnotation :: struct {
  label: string;
  needsConfirmation: bool; @?
  description: string; @?
}

LSP_ChangeAnnotationIdentifier :: string;

LSP_AnnotatedTextExit :: struct {
  #as using _: LSP_TextEdit;
  annotationId: LSP_ChangeAnnotationIdentifier;
}

LSP_TextDocumentEdit :: struct {
  textDocument: LSP_OptionalVersionedTextDocumentIdentifier;
  edits: [] Any; @LSP_TextEdit @LSP_AnnotatedTextEdit
}

_LSP_Locations :: [..] LSP_Location;
LSP_Location :: struct {
  uri: LSP_DocumentUri;
  range: LSP_Range;
}

_LSP_LocationLinks :: [..] LSP_LocationLink;
LSP_LocationLink :: struct {
  originSelectionRange: LSP_Range; @?
  targetUri: LSP_DocumentUri;
  targetRange: LSP_Range;
  targetSelectionRange: LSP_Range;
}

LSP_Diagnostic :: struct {
  range: LSP_Range;
  severity: LSP_DiagnosticSeverity; @?
  code: Any; @? @s32 @string
  codeDescription: LSP_CodeDescription; @?
  source: string; @?
  message: string; @?
  tags: [] LSP_DiagnosticTag; @?
  relatedInformation: [] LSP_DiagnosticRelatedInformation; @?
  data: Any; @?
}

LSP_DiagnosticSeverity :: enum {
  Error       :: 1;
  Warning     :: 2;
  Information :: 3;
  Hint        :: 4;
}

LSP_DiagnosticTag :: enum {
  Unnecessary :: 1;
  Deprecated  :: 2;
}

LSP_DiagnosticRelatedInformation :: struct {
  location: LSP_Location;
  message: string;
}

LSP_CodeDescription :: struct {
  href: LSP_URI;
}

LSP_Command :: struct {
  title: string;
  command: string;
  arguments: [] Any; @?
}

LSP_MarkupContent :: struct {
  kind: LSP_MarkupKind;
  value: string;
}

LSP_CreateFileOptions :: struct {
  overwrite: bool; @?
  ignoreIfExists: bool; @?
}

LSP_CreateFile :: struct {
  kind := LSP_ResourceOperationKind_Create;
  uri: LSP_DocumentUri;
  options: LSP_CreateFileOptions; @?
  annotationId: LSP_ChangeAnnotationIdentifier; @?
}

LSP_RenameFileOptions :: struct {
  overwrite: bool; @?
  ignoreIfExists: bool; @?
}

LSP_RenameFile :: struct {
  kind := LSP_ResourceOperationKind_Rename;
  oldUri: LSP_DocumentUri;
  newUri: LSP_DocumentUri;
  options: LSP_RenameFileOptions; @?
  annotationId: LSP_ChangeAnnotationIdentifier; @?
}

LSP_DeleteFileOptions :: struct {
  recursive: bool; @?
  ignoreIfNotExists: bool; @?
}

LSP_DeleteFile :: struct {
  kind := LSP_ResourceOperationKind_Delete;
  uri: LSP_DocumentUri;
  options: LSP_DeleteFileOptions; @?
  annotationId: LSP_ChangeAnnotationIdentifier; @?
}

_LSP_WorkspaceEdit_DocumentChanges :: [] LSP_TextDocumentEdit;
_LSP_WorkspaceEdit_DocumentChangesWithResourceOperations :: [] Any; @LSP_TextDocumentEdit @LSP_CreateFile @LSP_RenameFile @LSP_DeleteFile
LSP_WorkspaceEdit :: struct {
  changes: Table(LSP_DocumentUri, [] LSP_TextEdit); @? @$Table
  documentChanges: Any; @? @_LSP_WorkspaceEdit_DocumentChanges @_LSP_WorkspaceEdit_DocumentChangesWithResourceOperations
  changeAnnotations: Table(LSP_ChangeAnnotationIdentifier, LSP_ChangeAnnotation); @? @$Table
}

LSP_ProgressToken :: struct {
  _: Any; @s32 @string
}

LSP_WorkDoneProgressBegin :: struct {
  kind := LSP_WorkDoneProgressKind_Begin;
  title: string;
  cancellable: bool; @?
  message: string; @?
  percentage: u32 = cast,no_check(u32) -1; @?
}

LSP_WorkDoneProgressReport :: struct {
  kind := LSP_WorkDoneProgressKind_Report;
  cancellable: bool; @?
  message: string; @?
  percentage: u32 = cast,no_check(u32) -1; @?
}

LSP_WorkDoneProgressEnd :: struct {
  kind := LSP_WorkDoneProgressKind_End;
  message: string; @?
}

LSP_WorkDoneProgressParams :: struct {
  workDoneToken: LSP_ProgressToken; @?
}
LSP_WorkDoneProgressOptions :: struct {
  workDoneProgress: bool; @?
}

LSP_PartialResultParams :: struct {
  partialResultToken: LSP_ProgressToken; @?
}

LSP_RegularExpressionsClientCapabilities :: struct {
  PROPERTY_PATH :: "general.regularExpressions";
  //TODO Enum values, regex
  engine: string;
  version: string; @?
}

LSP_MarkdownClientCapabilities :: struct {
  parser: string;
  version: string; @?
  allowedTags: [] string; @?
}

LSP_WorkspaceEditClientCapabilities :: struct {
  documentChanges: bool; @?
  resourceOperations: [] LSP_ResourceOperationKind; @?
  failureHandling: LSP_FailureHandlingKind; @?
  normalizedLineEndings: bool; @?
  changeAnnotationSupport: struct {
    groupsOnLabel: bool; @?
  }; @?
}

LSP_TextDocumentClientCapabilities :: struct {
  // synchronization:    *LSP_TextDocumentSyncClientCapabilities;         @?
  // completion:         *LSP_CompletionClientCapabilities;               @?
  // hover:              *LSP_HoverClientCapabilities;                    @?
  // signatureHelp:      *LSP_SignatureHelpClientCapabilities;            @?
  declaration:        *LSP_DeclarationClientCapabilities;              @?
  // definition:         *LSP_DefinitionClientCapabilities;               @?
  // typeDefinition:     *LSP_TypeDefinitionClientCapabilities;           @?
  // implementation:     *LSP_ImplementationClientCapabilities;           @?
  // references:         *LSP_ReferenceClientCapabilities;                @?
  // documentHighlight:  *LSP_DocumentHighlightClientCapabilities;        @?
  // documentSymbol:     *LSP_DocumentSymbolClientCapabilities;           @?
  // codeAction:         *LSP_CodeActionClientCapabilities;               @?
  // codeLens:           *LSP_CodeLensClientCapabilities;                 @?
  // documentLink:       *LSP_DocumentLinkClientCapabilities;             @?
  // colorProvider:      *LSP_DocumentColorClientCapabilities;            @?
  // formatting:         *LSP_DocumentFormattingClientCapabilities;       @?
  // rangeFormatting:    *LSP_DocumentRangeFormattingClientCapabilities;  @?
  // onTypeFormatting:   *LSP_DocumentOnTypeFormattingClientCapabilities; @?
  // rename:             *LSP_RenameClientCapabilities;                   @?
  // publishDiagnostics: *LSP_PublishDiagnosticsClientCapabilities;       @?
  // foldingRange:       *LSP_FoldingRangeClientCapabilities;             @?
  // selectionRange:     *LSP_SelectionRangeClientCapabilities;           @?
  // linkedEditingRange: *LSP_LinkedEditingRangeClientCapabilities;       @?
  // callHierarchy:      *LSP_CallHierarchyClientCapabilities;            @?
  // semanticTokens:     *LSP_SemanticTokensClientCapabilities;           @?
  // moniker:            *LSP_MonikerClientCapabilities;                  @?
  // typeHierarchy:      *LSP_TypeHierarchyClientCapabilities;            @?
  // inlineValue:        *LSP_InlineValueClientCapabilities;              @?
  // inlayHint:          *LSP_InlayHintClientCapabilities;                @?
  // diagnostic:         *LSP_DiagnosticClientCapabilities;               @?
}

LSP_NotebookDocumentClientCapabilities :: struct {
  // synchronization: LSP_NotebookDocumentSyncClientCapabilities;
}

LSP_ClientCapabilities :: struct {
  workspace: struct {
    applyEdit: bool; @?
    workspaceEdit: LSP_WorkspaceEditClientCapabilities; @?
    // didChangeConfiguration: LSP_DidChangeConfigurationClientCapabilities; @?
    // didChangeWatchedFiles: LSP_DidChangeWatchedFilesClientCapabilities; @?
    // symbol: LSP_WorkspaceSymbolClientCapabilities; @?
    // executeCommand: LSP_ExecuteCommandClientCapabilities; @?
    workspaceFolders: bool; @?
    configuration: bool; @?
    // semanticTokens: LSP_SemanticTokensWorkspaceClientCapabilities; @?
    // codeLens: LSP_CodeLensWorkspaceClientCapabilities; @?
    fileOperations: struct {
      dynamicRegistration: bool; @?
      didCreate: bool; @?
      willCreate: bool; @?
      didRename: bool; @?
      willRename: bool; @?
      didDelete: bool; @?
      willDelete: bool; @?
    }; @?
    // inlineValue: LSP_InlineValueWorkspaceClientCapabilities; @?
    // inlayHint: LSP_InlayHintWorkspaceClientCapabilities; @?
    // diagnostics: LSP_DiagnosticWorkspaceClientCapabilities; @?
  }; @?
  textDocument: LSP_TextDocumentClientCapabilities; @?
  notebookDocument: LSP_NotebookDocumentClientCapabilities; @?
  window: struct {
    workDoneProgress: bool; @?
    // showMessage: LSP_ShowMessageRequestClientCapabilities; @?
    // showDocument: LSP_ShowDocumentClientCapabilities; @?
  }; @?
  general: struct {
    staleRequestSupport: struct {
      cancel: bool;
      retryOnContentModified: [] string;
    }; @?
    regularExpressions: LSP_RegularExpressionsClientCapabilities; @?
    markdown: LSP_MarkdownClientCapabilities; @?
    positionEncodings: [] LSP_PositionEncodingKind; @?
  }; @?
  experimental: Any; @?
}

LSP_ServerCapabilities :: struct {
  positionEncoding:                 LSP_PositionEncodingKind; @?
  // textDocumentSync:                 Any; @?       @LSP_TextDocumentSyncOptions        @LSP_TextDocumentSyncKind
  // notebookDocumentSync:             Any; @?       @LSP_NotebookDocumentSyncOptions    @LSP_NotebookDocumentSyncRegistrationOptions
  // completionProvider:               LSP_CompletionOptions; @?
  // hoverProvider:                    Any; @? @bool @LSP_HoverOptions
  // signatureHelpProvider:            LSP_SignatureHelpOptions; @?
  declarationProvider:              Any; @? @bool @LSP_DeclarationOptions             @LSP_DeclarationRegistrationOptions
  // definitionProvider:               Any; @? @bool @LSP_DefinitionOptions
  // typeDefinitionProvider:           Any; @? @bool @LSP_TypeDefinitionOptions          @LSP_TypeDefinitionRegistrationOptions
  // implementationProvider:           Any; @? @bool @LSP_ImplementationOptions          @LSP_ImplementationRegistrationOptions
  // referencesProvider:               Any; @? @bool @LSP_ReferenceOptions
  // documentHighlightProvider:        Any; @? @bool @LSP_DocumentHighlightOptions
  // documentSymbolProvider:           Any; @? @bool @LSP_DocumentSymbolOptions
  // codeActionProvider:               Any; @? @bool @LSP_CodeActionOptions
  // codeLensProvider:                 LSP_CodeLensOptions; @?
  // documentLinkProvider:             LSP_DocumentLinkOptions; @?
  // colorProvider:                    Any; @? @bool @LSP_DocumentColorOptions           @LSP_DocumentColorRegistrationOptions
  // documentFormattingProvider:       Any; @? @bool @LSP_DocumentFormattingOptions
  // documentRangeFormattingProvider:  Any; @? @bool @LSP_DocumentRangeFormattingOptions
  // documentOnTypeFormattingProvider: LSP_DocumentOnTypeFormattingOptions; @?
  // renameProvider:                   Any; @? @bool @LSP_RenameOptions
  // foldingRangeProvider:             Any; @? @bool @LSP_FoldingRangeOptions            @LSP_FoldingRangeRegistrationOptions
  // executeCommandProvider:           LSP_ExecuteCommandOptions; @?
  // selectionRangeProvider:           Any; @? @bool @LSP_SelectionRangeOptions          @LSP_SelectionRangeRegistrationOptions
  // linkedEditingRangeProvider:       Any; @? @bool @LSP_LinkedEditingRangeOptions      @LSP_LinkedEditingRangeRegistrationOptions
  // callHierarchyProvider:            Any; @? @bool @LSP_CallHierarchyOptions           @LSP_CallHierarchyRegistrationOptions
  // semanticTokensProvider:           Any; @?       @LSP_SemanticTokensOptions          @LSP_SemanticTokensRegistrationOptions
  // monikerProvider:                  Any; @? @bool @LSP_MonikerOptions                 @LSP_MonikerRegistrationOptions
  // typeHierarchyProvider:            Any; @? @bool @LSP_TypeHierarchyOptions           @LSP_TypeHierarchyRegistrationOptions
  // inlineValueProvider:              Any; @? @bool @LSP_InlineValueOptions             @LSP_InlineValueRegistrationOptions
  // inlayHintProvider:                Any; @? @bool @LSP_InlayHintOptions               @LSP_InlayHintRegistrationOptions
  // diagnosticProvider:               Any; @?       @LSP_DiagnosticOptions              @LSP_DiagnosticRegistrationOptions
  // workspaceSymbolProvider:          Any; @? @bool @LSP_WorkspaceSymbolOptions
  workspace: struct {
    // workspaceFolders: LSP_WorkspaceFoldersServerCapabilities; @?
    fileOperations: struct {
      // didCreate:  LSP_FileOperationRegistrationOptions; @?
      // willCreate: LSP_FileOperationRegistrationOptions; @?
      // didRename:  LSP_FileOperationRegistrationOptions; @?
      // willRename: LSP_FileOperationRegistrationOptions; @?
      // didDelete:  LSP_FileOperationRegistrationOptions; @?
      // willDelete: LSP_FileOperationRegistrationOptions; @?
    }; @?
  }; @?
  experimental: Any; @?
}

LSP_Registration :: struct {
  id: string;
  method: string;
  registerOptions: Any; @?
}

LSP_Unregistration :: struct {
  id: string;
  method: string;
}

LSP_StaticRegistrationOptions :: struct {
  id: string; @?
}

LSP_TextDocumentRegistrationOptions :: struct {
  documentSelector: Any; @? @LSP_DocumentSelector @$Null
}

LSP_WorkspaceFolder :: struct {
  uri: LSP_URI;
  name: string;
}

// initialize

_LSP_InitializeParams_WorkspaceFolders :: [] LSP_WorkspaceFolder;
LSP_InitializeParams :: struct {
  #as using _: LSP_WorkDoneProgressParams;
  processId: Any; @s32 @$Null
  clientInfo: struct {
    name: string;
    version: string; @?
  }; @?
  locale: string; @?
  rootPath: Any; @string @$Null
  rootUri: Any; @LSP_DocumentUri @$Null;
  initializationOptions: Any; @?
  capabilities: LSP_ClientCapabilities;
  trace := LSP_TraceValue_Off; @?
  workspaceFolders: Any; @? @_LSP_InitializeParams_WorkspaceFolders @$Null;
}

LSP_InitializeResult :: struct {
  capabilities: LSP_ServerCapabilities;
  serverInfo: struct {
    name: string;
    version: string; @?
  }; @?
}

LSP_InitializeErrorCodes :: enum {
  unknownProtocolVersion :: 1;
}

LSP_InitializeError :: struct {
  retry: bool;
}

lsp_initialize :: (data: *Data, params: LSP_InitializeParams) -> LSP_InitializeResult {
  result := LSP_InitializeResult.{};
  error := LSP_InitializeError.{false};
  set_error_data(error);
  
  assert(!data.is_shutdown, "Cannot initialize because the server was shut down");
  assert(!data.is_initialized, "The server is already initialized.");
  
  data.is_initialized = true;
  
  result.serverInfo.name = copy_string(SERVER_VERSION);
  result.serverInfo.version = copy_string(SERVER_NAME);
  result.capabilities.declarationProvider = alloc_any(!!params.capabilities.textDocument.declaration);
  return result;
}

// initialized

LSP_InitializedParams :: struct {
}

lsp_initialized :: (data: *Data, params: LSP_InitializedParams) {
  assert_running();
}

// client/registerCapability

LSP_RegistrationParams :: struct {
  registrations: [] LSP_Registration;
}

_LSP_Client_RegisterCapability_Result :: struct {
}
_LSP_Client_RegisterCapability_Error :: struct {
}

lsp_client_registerCapability :: (data: *Data, result: _LSP_Client_RegisterCapability_Result) {
  assert_running();
}

lsp_client_registerCapability_error :: (data: *Data, code: JSON_RPC_Error_Code, message: string, error_data: _LSP_Client_RegisterCapability_Error) {
  assert_running();
}

// client/unregisterCapability

LSP_UnregistrationParams :: struct {
  unregistrations: [] LSP_Unregistration;
}

lsp_client_unregisterCapability :: (data: *Data, params: LSP_UnregistrationParams) {
  assert_running();
}

// $/setTrace

LSP_SetTraceParams :: struct {
  value: LSP_TraceValue;
}

lsp_setTrace :: (data: *Data, params: LSP_SetTraceParams) {
  assert_running();
  data.trace = params.value;
}

// $/logTrace

LSP_LogTraceParams :: struct {
  message: string;
  verbose: string; @?
}

lsp_logTrace :: (data: *Data, params: LSP_LogTraceParams) {
  assert_running();
  // send_notification("$/logTrace", params);
}

// shutdown

lsp_shutdown :: (data: *Data) {
  assert_running();
  data.is_shutdown = true;
}

// exit

lsp_exit :: (data: *Data) {
  if data.is_shutdown exit(0);
  exit(1);
}

// $/cancelRequest

LSP_CancelParams :: struct {
  id: Any; @s32 @string
}

lsp_cancel :: (data: *Data, params: LSP_CancelParams) {
  assert_running();
}

// $/progress

LSP_ProgressParams :: struct(Value_Type: Type) {
  token: LSP_ProgressToken;
  value: Value_Type;
}

lsp_progress :: (data: *Data) {
  assert_running();
}

// Go to Declaration

LSP_DeclarationClientCapabilities :: struct {
	dynamicRegistration: bool; @?
	linkSupport: bool; @?
}

LSP_DeclarationOptions :: struct {
  #as using _: LSP_WorkDoneProgressOptions;
}

LSP_DeclarationRegistrationOptions :: struct {
  #as using _0: LSP_DeclarationOptions;
	#as using _1: LSP_TextDocumentRegistrationOptions;
  #as using _2: LSP_StaticRegistrationOptions;
}

LSP_DeclarationParams :: struct {
  #as using _0: LSP_TextDocumentPositionParams;
	#as using _1: LSP_WorkDoneProgressParams;
  #as using _2: LSP_PartialResultParams;
}

LSP_DeclarationResult :: struct {
  _: Any; @LSP_Location @_LSP_Locations @_LSP_LocationLinks @$Null
}

LSP_DeclarationPartialResult :: struct {
  _: Any; @_LSP_Locations @_LSP_LocationLinks
}

lsp_textDocument_declaration :: (data: *Data, params: LSP_DeclarationParams) -> LSP_DeclarationResult {
  assert_running();
  return .{make_null_any()};
}

#scope_file

assert_running :: () #expand {
  {
    push_error(.NOT_INITIALIZED);
    assert(`data.is_initialized);
    set_error(.INVALID_REQUEST);
    assert(!`data.is_shutdown);
  }
}