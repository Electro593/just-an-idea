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

_LSP_TextEdits :: [] LSP_TextEdit;
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
  synchronization:    *LSP_TextDocumentSyncClientCapabilities;         @?
  // completion:         *LSP_CompletionClientCapabilities;               @?
  // hover:              *LSP_HoverClientCapabilities;                    @?
  // signatureHelp:      *LSP_SignatureHelpClientCapabilities;            @?
  declaration:        *LSP_DeclarationClientCapabilities;              @?
  definition:         *LSP_DefinitionClientCapabilities;               @?
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
  textDocumentSync:                 Any; @?       @LSP_TextDocumentSyncOptions        @LSP_TextDocumentSyncKind
  // notebookDocumentSync:             Any; @?       @LSP_NotebookDocumentSyncOptions    @LSP_NotebookDocumentSyncRegistrationOptions
  // completionProvider:               LSP_CompletionOptions; @?
  // hoverProvider:                    Any; @? @bool @LSP_HoverOptions
  // signatureHelpProvider:            LSP_SignatureHelpOptions; @?
  declarationProvider:              Any; @? @bool @LSP_DeclarationOptions             @LSP_DeclarationRegistrationOptions
  definitionProvider:               Any; @? @bool @LSP_DefinitionOptions
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

lsp_initialize :: (data: *Data, params: *LSP_InitializeParams) -> LSP_InitializeResult {
  result := LSP_InitializeResult.{};
  error := LSP_InitializeError.{false};
  set_error_data(error);
  
  assert(!data.is_shutdown, "Cannot initialize because the server was shut down");
  assert(!data.is_initialized, "The server is already initialized.");
  
  data.client = .{};
  if !is_any_null(params.processId) {
    pid := cast_any(params.processId, s32).*;
    #if OS == .WINDOWS {
      data.client.info.dwProcessId = pid;
    } else #if OS == .LINUX || OS == .MACOS {
      data.client.pid = pid;
    }
  }
  
  result.serverInfo.name = copy_string(SERVER_VERSION);
  result.serverInfo.version = copy_string(SERVER_NAME);
  result.capabilities.declarationProvider = alloc_any(!!params.capabilities.textDocument.declaration);
  result.capabilities.definitionProvider = alloc_any(!!params.capabilities.textDocument.definition);
  result.capabilities.textDocumentSync = alloc_any(LSP_TextDocumentSyncOptions.{
    openClose = true,
    change = .Incremental,
    willSave = false,
    willSaveUntilWait = false,
    save = alloc_any(false),
  });
  
  data.capabilities = copy_casted_json(params.capabilities);
  
  data.is_initialized = true;
  return result;
}

// initialized

LSP_InitializedParams :: struct {
}

lsp_initialized :: (data: *Data, params: *LSP_InitializedParams) {
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

// lsp_client_registerCapability :: (data: *Data, result: _LSP_Client_RegisterCapability_Result) {
//   assert_running();
// }

// lsp_client_registerCapability_error :: (data: *Data, code: JSON_RPC_Error_Code, message: string, error_data: _LSP_Client_RegisterCapability_Error) {
//   assert_running();
// }

// client/unregisterCapability

LSP_UnregistrationParams :: struct {
  unregistrations: [] LSP_Unregistration;
}

// lsp_client_unregisterCapability :: (data: *Data, params: *LSP_UnregistrationParams) {
//   assert_running();
// }

// $/setTrace

LSP_SetTraceParams :: struct {
  value: LSP_TraceValue;
}

lsp_setTrace :: (data: *Data, params: *LSP_SetTraceParams) {
  assert_running();
  data.trace = params.value;
}

// $/logTrace

LSP_LogTraceParams :: struct {
  message: string;
  verbose: string; @?
}

lsp_logTrace :: (data: *Data, message: string, verbose_extra := "") {
  assert_running();
  rpc_debug_log("Trace is %", data.trace);
  if data.trace == LSP_TraceValue_Off return;
  params := LSP_LogTraceParams.{message = message};
  if data.trace == LSP_TraceValue_Verbose
    params.verbose = verbose_extra;
  add_request_to_batch("$/logTrace", params, true);
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

// lsp_cancel :: (data: *Data, params: LSP_CancelParams) {
//   assert_running();
// }

// $/progress

LSP_ProgressParams :: struct(Value_Type: Type) {
  token: LSP_ProgressToken;
  value: Value_Type;
}

// lsp_progress :: (data: *Data) {
//   assert_running();
// }

//
// Document Synchronization
//

LSP_TextDocumentSyncClientCapabilities :: struct {
  dynamicRegistration: bool; @?
  willSave: bool; @?
  willSaveUntilWait: bool; @?
  didSave: bool; @?
}

LSP_TextDocumentSyncKind :: enum {
  None        :: 0;
  Full        :: 1;
  Incremental :: 2;
}

LSP_TextDocumentSyncOptions :: struct {
  openClose: bool; @?
  change: LSP_TextDocumentSyncKind; @?
  willSave: bool; @?
  willSaveUntilWait: bool; @?
  save: Any; @? @bool @LSP_SaveOptions
}

// Did Open Text Document

LSP_DidOpenTextDocumentParams :: struct {
  textDocument: LSP_TextDocumentItem;
}

lsp_textDocument_didOpen :: (data: *Data, params: *LSP_DidOpenTextDocumentParams) {
  assert_running();
  decode_uri(*params.textDocument.uri);
  // TODO: Handle externally-modified files?
  launch_compiler(data, params.textDocument.uri);
}

// Did Change Text Document

LSP_TextDocumentChangeRegistrationOptions :: struct {
  #as using _: LSP_TextDocumentRegistrationOptions;
  syncKind: LSP_TextDocumentSyncKind;
}

_LSP_TextDocumentContentChangeEvent_Range :: struct {
  range: LSP_Range;
  rangeLength: u32; @?
  text: string;
}
_LSP_TextDocumentContentChangeEvent_Full :: struct {
  text: string;
}
LSP_TextDocumentContentChangeEvent :: struct {
  _: Any; @_LSP_TextDocumentContentChangeEvent_Range @_LSP_TextDocumentContentChangeEvent_Full
}

LSP_DidChangeTextDocumentParams :: struct {
  textDocument: LSP_VersionedTextDocumentIdentifier;
  contentChanges: [] LSP_TextDocumentContentChangeEvent;
}

lsp_textDocument_didChange :: (data: *Data, params: *LSP_DidChangeTextDocumentParams) {
  assert_running();
  decode_uri(*params.textDocument.uri);
  //TODO: Handle this
  // apply_document_changes(data, params.textDocument.uri, params.contentChanges);
  launch_compiler(data, params.textDocument.uri);
}

// Will Save Text Document

LSP_TextDocumentSaveReason :: struct {
  Manual     :: 1;
  AfterDelay :: 2;
  FocusOut   :: 3;
}

LSP_WillSaveTextDocumentParams :: struct {
  textDocument: LSP_TextDocumentIdentifier;
  reason: LSP_TextDocumentSaveReason;
}

lsp_textDocument_willSave :: (data: *Data, params: *LSP_WillSaveTextDocumentParams) {
  assert_running();
}

// Will Save Document Wait Until

LSP_WillSaveDocumentWaitUntilParams :: LSP_WillSaveTextDocumentParams;

LSP_WillSaveDocumentWaitUntilResult :: struct {
  _: Any; @_LSP_TextEdits @$Null
}

lsp_textDocument_willSaveWaitUntil :: (data: *Data, params: *LSP_WillSaveDocumentWaitUntilParams) -> LSP_WillSaveDocumentWaitUntilResult {
  assert_running();
  return .{make_null_any()};
}

// Did Save Text Document

LSP_SaveOptions :: struct {
  includeText: bool; @?
}

LSP_TextDocumentSaveRegistrationOptions :: struct {
  #as using _: LSP_TextDocumentRegistrationOptions;
  includeText: bool; @?
}

LSP_DidSaveTextDocumentParams :: struct {
  textDocument: LSP_TextDocumentIdentifier;
  text: string; @?
}

lsp_textDocument_didSave :: (data: *Data, params: *LSP_DidSaveTextDocumentParams) {
  assert_running();
}

// Did Close Text Document

LSP_DidCloseTextDocumentParams :: struct {
  textDocument: LSP_TextDocumentIdentifier;
}

lsp_textDocument_didClose :: (data: *Data, params: *LSP_DidCloseTextDocumentParams) {
  assert_running();
}

//TODO: Notebook (didOpen, didChange, didSave, didClose)

//
// Language Features
//

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

lsp_textDocument_declaration :: (data: *Data, params: *LSP_DeclarationParams) -> LSP_DeclarationResult {
  assert_running();
  
  header, success := lock_and_open_index(null, false);
  assert(success, "Could not open the index");
  
  links, found := find_declaration_links(*header, params.textDocument.uri, params.position);
  close_and_unlock_index(*header);
  if !found return .{make_null_any()};
  
  if data.capabilities.textDocument.declaration.linkSupport
    return .{alloc_any(links)};
  locations := location_links_to_locations(links);
  return .{alloc_any(locations)};
}

// Go to Definition

LSP_DefinitionClientCapabilities :: struct {
	dynamicRegistration: bool; @?
	linkSupport: bool; @?
}

LSP_DefinitionOptions :: struct {
  #as using _: LSP_WorkDoneProgressOptions;
}

LSP_DefinitionRegistrationOptions :: struct {
  #as using _0: LSP_DefinitionOptions;
	#as using _1: LSP_TextDocumentRegistrationOptions;
}

LSP_DefinitionParams :: struct {
  #as using _0: LSP_TextDocumentPositionParams;
	#as using _1: LSP_WorkDoneProgressParams;
  #as using _2: LSP_PartialResultParams;
}

LSP_DefinitionResult :: struct {
  _: Any; @LSP_Location @_LSP_Locations @_LSP_LocationLinks @$Null
}

LSP_DefinitionPartialResult :: struct {
  _: Any; @_LSP_Locations @_LSP_LocationLinks
}

lsp_textDocument_definition :: (data: *Data, params: *LSP_DefinitionParams) -> LSP_DefinitionResult {
  assert_running();
  
  header, success := lock_and_open_index(null, false);
  assert(success, "Could not open the index");
  
  links, found := find_definition_links(*header, params.textDocument.uri, params.position);
  close_and_unlock_index(*header);
  if !found return .{make_null_any()};
  
  if data.capabilities.textDocument.definition.linkSupport
    return .{alloc_any(links)};
  locations := location_links_to_locations(links);
  return .{alloc_any(locations)};
}

#scope_file

assert_running :: () #expand {
  {
    if !is_process_running(`data.client) then lsp_exit(`data);
    push_error(.NOT_INITIALIZED);
    assert(`data.is_initialized);
    set_error(.INVALID_REQUEST);
    assert(!`data.is_shutdown);
  }
}

is_process_running :: (process: Process) -> bool {
  #if OS == .WINDOWS {
    OpenProcess :: (dwDesiredAccess: DWORD, bInheritHandle: BOOL, dwProcessId: DWORD) -> HANDLE #foreign kernel32;
    SYNCHRONIZE : DWORD : 0x00100000;
    
    if process.info.dwProcessId == -1 then return true;
    handle := OpenProcess(SYNCHRONIZE, xx false, xx process.info.dwProcessId);
    status := WaitForSingleObject(handle, 0);
    CloseHandle(handle);
    return status == WAIT_TIMEOUT;
  } else #if OS == .LINUX || OS == .MACOS {
    if process.pid == 0 return true;
    return kill(process.pid, 0) != -1;
  }
}

apply_document_changes :: (data: *Data, uri: LSP_DocumentUri, content_changes: [] LSP_TextDocumentContentChangeEvent) {
  // header, success := lock_and_open_index(null, true);
  // assert(success, "Could not open the index");
  
  // //TODO: If we get an earlier version, something screwed up, so flush the database
  
  // for content_changes {
  //   if is_any_of_type(it._, _LSP_TextDocumentContentChangeEvent_Full) {
  //     success = remove_document(*header, uri);
  //     assert(success, "Could not remove % from the index", uri);
  //     break;
  //   } else {
  //     change := cast_any(it._, _LSP_TextDocumentContentChangeEvent_Range);
  //     apply_document_change(*header, change.range);
  //   }
  // }
  
  // close_and_unlock_index(*header);
}

launch_compiler :: (data: *Data, document: LSP_DocumentUri) {
  //TODO: Find main/module file
  //TODO: Use config if jai is not in path
  //TODO: Allow for user metaprograms and arguments for specific files
  
  // Wait for, or kill, the compiler
  header, success := lock_and_open_index(*data.compiler, false);
  assert(success, "Could not open the index");
  close_and_unlock_index(*header);
  
  success = create_process(*data.compiler, "jai", document, "file", "--", "meta", "Parse", working_directory = SERVER_FOLDER);
  assert(success, "Failed to launch compiler: 'jai % file -- meta Parse' in '${extensionDirectory}/%'", document, SERVER_FOLDER);
}

location_links_to_locations :: (links: [] LSP_LocationLink) -> [] LSP_Location {
  locations: [] LSP_Location;
  locations.count = links.count;
  locations.data = alloc(links.count * size_of(LSP_Location));
  
  for links {
    locations[it_index] = .{
      uri = it.targetUri,
      range = it.targetRange
    };
  }
  
  free(links.data);
  return locations;
}

decode_uri :: (uri: *string) {
  get_hex_value :: inline (char: u8) -> u8 {
    return char - cast(u8)
      ifx char <= #char "9" then #char "0"
      else ifx char <= #char "Z" then #char "A" - 10
      else #char "a" - 10;
  }
  
  i, j := 0;
  while i < uri.count {
    if uri.*[i] == #char "%" {
      value := (get_hex_value(uri.*[i+1]) << 4) | get_hex_value(uri.*[i+2]);
      uri.*[j] = value;
      i += 3;
    } else {
      uri.*[j] = uri.*[i];
      i += 1;
    }
    j += 1;
  }
  
  uri.count = j;
}

apply_document_change :: (lines: *[..] string, text: string, start_line: s64, start_column: s64, end_line: s64, end_column: s64) {
  remove_selection :: (lines: *[..] string, sl: s64, sc: s64, el: s64, ec: s64) {
    assert(sl >= 0 && sc >= 0 && el >= 0 && ec >= 0, "Cannot have a negative range (%,%)->(%,%)", sl, sc, el, ec);
    assert(sc <= ec && sl <= el, "Cannot have an end (%,%) before the start (%,%)", el, ec, sl, sc);
    assert(lines.count > el, "Cannot remove line % of only % lines", el, lines.count);
    
    start_line := lines.*[sl];
    end_line := lines.*[el];
    lead := sc;
    tail := end_line.count - ec;
    
    // Merge the parts before and after the selection
    line: string;
    line.count = lead + tail;
    line.data = alloc(line.count);
    memcpy(line.data, start_line.data, lead);
    memcpy(line.data + lead, end_line.data + ec, tail);
    free(start_line);
    lines.*[sl] = line;
    
    // Remove the remaining lines
    for sl+1..el free(lines.*[it]);
    memcpy(lines.data + sl+1, lines.data + el+1, (lines.count - (el+1)) * size_of(type_of(lines.*[0])));
    lines.count -= el - sl;
  }
  
  insert_text :: (lines: *[..] string, text: string, sl: s64, sc: s64) {
    assert(sl >= 0 && sc >= 0, "Cannot have a negative insertion point (%,%)", sl, sc);
    start := lines.*[sl];
    
    // Get the number of added lines
    j := 0;
    lines_to_add := 0;
    while j < text.count {
      defer j += 1;
      if !is_any(text[j], "\r\n") continue;
      lines_to_add += 1;
      j += xx (j+1 < text.count && text[j] == #char "\r" && text[j+1] == #char "\n");
    }
    
    if lines_to_add {
      // Insert the new lines
      original_line_count := lines.count;
      array_resize(lines, original_line_count + lines_to_add, false);
      memcpy(lines.data + sl + 1 + lines_to_add, lines.data + sl + 1, (original_line_count - sl - 1) * size_of(type_of(lines.*[0])));
      memset(lines.data + sl + 1, 0, lines_to_add * size_of(type_of(lines.*[0])));
      
      // Split the insert point into two
      tail_line := string.{start.count - sc, null};
      tail_line.data = alloc(tail_line.count);
      memcpy(tail_line.data, start.data + sc, tail_line.count);
      free(lines.*[sl + lines_to_add]);
      lines.*[sl + lines_to_add] = tail_line;
      lines.*[sl].count = sc;
    }
    
    // Insert the new text
    j = 0;
    l := sl;
    line_start := 0;
    while j <= text.count {
      defer j += 1;
      if j < text.count && !is_any(text[j], "\r\n") continue;
      
      old_line := lines.*[l];
      lead := ifx l == sl then sc else 0;
      insertion := j - line_start;
      tail := old_line.count - lead;
      
      line := string.{lead + insertion + tail, null};
      line.data = alloc(line.count);
      memcpy(line.data, old_line.data, lead);
      memcpy(line.data + lead, text.data + line_start, insertion);
      memcpy(line.data + lead + insertion, old_line.data + lead, tail);
      free(old_line);
      lines.*[l] = line;
      
      j += xx (j+1 < text.count && text[j] == #char "\r" && text[j+1] == #char "\n");
      l += 1;
      line_start = j + 1;
    }
  }
  
  //TODO encoding
  if !lines.count array_add(lines, "");
  remove_selection(lines, start_line, start_column, end_line, end_column);
  insert_text(lines, text, start_line, start_column);
}

RUN_TESTS :: false;
#if RUN_TESTS {
  #run {
    test_decode_uri :: (expected: string, uri: string) {
      document_uri: LSP_DocumentUri = copy_string(uri);
      decode_uri(*document_uri);
      assert(expected == cast(string) document_uri, "Expected % from % but got %", expected, uri, document_uri);
    }
    
    test_apply_document_change :: (expected_lines: [] string, start_lines: [] string, text: string, start_line: s64, start_column: s64, end_line: s64, end_column: s64) {
      lines: [..] string;
      for start_lines array_add(*lines, copy_string(it));
      // print("(%,%)->(%,%):\n%\n", start_line, start_column, end_line, end_column, text);
      // print("Start: %\n", lines);
      apply_document_change(*lines, text, start_line, start_column, end_line, end_column);
      // print("End: %\n", lines);
      // print("Expected: %\n\n", expected_lines);
      assert(expected_lines.count == lines.count, "The counts weren't the same (expected %, but got %)", expected_lines.count, lines.count);
      for lines
        assert(expected_lines[it_index] == it, "The lines weren't the same (expected line % to be '%', but got '%'", it_index, expected_lines[it_index], it);
      for lines free(it);
      array_free(lines);
    }
    
    test_decode_uri("a:\\b\\c\\d.e", "a:\\b\\c\\d.e");
    test_decode_uri("a:\\b\\c\\d.e", "a%3A\\b\\c\\d.e");
    
    // Add start
    test_apply_document_change(.["za1","b2","c3"], .["a1","b2","c3"], "z", 0, 0, 0, 0);
    test_apply_document_change(.["z","!a1","b2","c3"], .["a1","b2","c3"], "z\n!", 0, 0, 0, 0);
    
    // Add middle
    test_apply_document_change(.["a1","bz2","c3"], .["a1","b2","c3"], "z", 1, 1, 1, 1);
    test_apply_document_change(.["a1","b!","z","?2","c3"], .["a1","b2","c3"], "!\nz\n?", 1, 1, 1, 1);
    
    // Add end
    test_apply_document_change(.["a1","b2","c3z"], .["a1","b2","c3"], "z", 2, 2, 2, 2);
    test_apply_document_change(.["a1","b2","c3!","z"], .["a1","b2","c3"], "!\nz", 2, 2, 2, 2);
    test_apply_document_change(.["a1","b2","",""], .["a1","b2",""], "\n", 2, 0, 2, 0);
    
    // Remove start
    test_apply_document_change(.["b2","c3"], .["a1","b2","c3"], "", 0, 0, 1, 0);
    test_apply_document_change(.["2","c3"], .["a1","b2","c3"], "", 0, 0, 1, 1);
    
    // Remove middle
    test_apply_document_change(.["a3"], .["a1","b2","c3"], "", 0, 1, 2, 1);
    test_apply_document_change(.[""], .["a1","b2","c3"], "", 0, 0, 2, 2);
    
    // Remove end
    test_apply_document_change(.["a1","b2"], .["a1","b2","c3"], "", 1, 2, 2, 2);
    test_apply_document_change(.["a1","b"], .["a1","b2","c3"], "", 1, 1, 2, 2);
    
    // Replace start
    test_apply_document_change(.["z1","b2","c3"], .["a1","b2","c3"], "z", 0, 0, 0, 1);
    test_apply_document_change(.["z2","c3"], .["a1","b2","c3"], "z", 0, 0, 1, 1);
    
    // Replace middle
    test_apply_document_change(.["a1","z","c3"], .["a1","b2","c3"], "z", 1, 0, 1, 2);
    test_apply_document_change(.["az3"], .["a1","b2","c3"], "z", 0, 1, 2, 1);
    
    // Replace end
    test_apply_document_change(.["a1","b2","cz"], .["a1","b2","c3"], "z", 2, 1, 2, 2);
    test_apply_document_change(.["a1","bz"], .["a1","b2","c3"], "z", 1, 1, 2, 2);
    
    // Add more than remove
    test_apply_document_change(.["a","w","x","y","z","","3"], .["a1","b2","c3"], "\nw\nx\ny\nz\n\n", 0, 1, 2, 1);
    
    // Remove more than add
    test_apply_document_change(.["","x","y"], .["a1","b2","c3","d4","e5","f6"], "\nx\ny", 0, 0, 5, 2);
  }
}

#scope_file

#import "String";