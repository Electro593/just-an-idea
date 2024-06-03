//
// Basic Structures
//

LSP_DocumentUri :: string;

LSP_URI :: string;

LSP_RegularExpressionsClientCapabilities :: struct {
  engine: string;
  version: string; @?
}

LSP_EOL :: string.["\n", "\r\n", "\r"];

LSP_Position :: struct {
  line: u32;
  character: u32;
}

LSP_PositionEncodingKind :: string;
LSP_PositionEncodingKind_UTF8 : LSP_PositionEncodingKind : "utf-8";
LSP_PositionEncodingKind_UTF16 : LSP_PositionEncodingKind : "utf-16";
LSP_PositionEncodingKind_UTF32 : LSP_PositionEncodingKind : "utf-32";

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

LSP_MarkupKind :: string;
LSP_MarkupKind_PlainText :: "plaintext";
LSP_MarkupKind_Markdown :: "markdown";

LSP_MarkupContent :: struct {
  kind: LSP_MarkupKind;
  value: string;
}

LSP_MarkdownClientCapabilities :: struct {
  parser: string;
  version: string; @?
  allowedTags: [] string; @?
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

LSP_WorkspaceEditClientCapabilities :: struct {
  documentChanges: bool; @?
  resourceOperations: [] LSP_ResourceOperationKind; @?
  failureHandling: LSP_FailureHandlingKind; @?
  normalizedLineEndings: bool; @?
  changeAnnotationSupport: struct {
    groupsOnLabel: bool; @?
  }; @?
}

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

LSP_WorkDoneProgressOptions :: struct {
  workDoneProgress: bool; @?
}

LSP_TraceValue :: string;
LSP_TraceValue_Off      :: "off";
LSP_TraceValue_Messages :: "messages";
LSP_TraceValue_Verbose  :: "verbose";

//
// Base Protocol
//

// Cancel ($/cancelRequest)

LSP_CancelParams :: struct {
  id: Any; @s32 @string
}

// Progress ($/progress)

LSP_ProgressToken :: struct {
  _: Any; @s32 @string
}

LSP_WorkDoneProgressParams :: struct {
  workDoneToken: LSP_ProgressToken; @?
}

LSP_PartialResultParams :: struct {
  partialResultToken: LSP_ProgressToken; @?
}

LSP_ProgressParams :: struct(Value_Type: Type) {
  token: LSP_ProgressToken;
  value: Value_Type;
}

//
// Lifecycle Messages
//

// Initialize (initialize)

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
  synchronization: LSP_NotebookDocumentSyncClientCapabilities;
}

LSP_ClientCapabilities :: struct {
  workspace: struct {
    applyEdit: bool; @?
    workspaceEdit: LSP_WorkspaceEditClientCapabilities; @?
    didChangeConfiguration: LSP_DidChangeConfigurationClientCapabilities; @?
    didChangeWatchedFiles: LSP_DidChangeWatchedFilesClientCapabilities; @?
    symbol: LSP_WorkspaceSymbolClientCapabilities; @?
    executeCommand: LSP_ExecuteCommandClientCapabilities; @?
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
    showMessage: LSP_ShowMessageRequestClientCapabilities; @?
    showDocument: LSP_ShowDocumentClientCapabilities; @?
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
  notebookDocumentSync:             Any; @?       @LSP_NotebookDocumentSyncOptions    @LSP_NotebookDocumentSyncRegistrationOptions
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
  workspaceSymbolProvider:          Any; @? @bool @LSP_WorkspaceSymbolOptions
  workspace: struct {
    workspaceFolders: LSP_WorkspaceFoldersServerCapabilities; @?
    fileOperations: struct {
      didCreate:  LSP_FileOperationRegistrationOptions; @?
      willCreate: LSP_FileOperationRegistrationOptions; @?
      didRename:  LSP_FileOperationRegistrationOptions; @?
      willRename: LSP_FileOperationRegistrationOptions; @?
      didDelete:  LSP_FileOperationRegistrationOptions; @?
      willDelete: LSP_FileOperationRegistrationOptions; @?
    }; @?
  }; @?
  experimental: Any; @?
}

LSP_InitializeErrorCodes :: enum {
  unknownProtocolVersion :: 1;
}

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

LSP_InitializeError :: struct {
  retry: bool;
}

// Initialized (initialized)

LSP_InitializedParams :: struct {
}

// Register Capability (client/registerCapability)

LSP_Registration :: struct {
  id: string;
  method: string;
  registerOptions: Any; @?
}

LSP_StaticRegistrationOptions :: struct {
  id: string; @?
}

LSP_TextDocumentRegistrationOptions :: struct {
  documentSelector: Any; @? @LSP_DocumentSelector @$Null
}

LSP_RegistrationParams :: struct {
  registrations: [] LSP_Registration;
}

// Unregister Capability (client/unregisterCapability)

LSP_Unregistration :: struct {
  id: string;
  method: string;
}

LSP_UnregistrationParams :: struct {
  unregistrations: [] LSP_Unregistration;
}

// Set Trace ($/setTrace)

LSP_SetTraceParams :: struct {
  value: LSP_TraceValue;
}

// Log Trace ($/logTrace)

LSP_LogTraceParams :: struct {
  message: string;
  verbose: string; @?
}

// Shutdown (shutdown)

// Exit (exit)

//
// Document Synchronization
//

// Did Open Text Document (textDocument/didOpen)

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

LSP_DidOpenTextDocumentParams :: struct {
  textDocument: LSP_TextDocumentItem;
}

// Did Change Text Document (textDocument/didChange)

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

// Will Save Text Document (textDocument/willSave)

LSP_TextDocumentSaveReason :: struct {
  Manual     :: 1;
  AfterDelay :: 2;
  FocusOut   :: 3;
}

LSP_WillSaveTextDocumentParams :: struct {
  textDocument: LSP_TextDocumentIdentifier;
  reason: LSP_TextDocumentSaveReason;
}

// Will Save Document Wait Until (textDocument/willSaveWaitUntil)

LSP_WillSaveDocumentWaitUntilParams :: LSP_WillSaveTextDocumentParams;

LSP_WillSaveDocumentWaitUntilResult :: struct {
  _: Any; @_LSP_TextEdits @$Null
}

// Did Save Text Document (textDocument/didSave)

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

// Did Close Text Document (textDocument/didClose)

LSP_DidCloseTextDocumentParams :: struct {
  textDocument: LSP_TextDocumentIdentifier;
}

// Did Open Notebook Document (notebookDocument/didOpen)

LSP_NotebookDocument :: struct {
  uri: LSP_URI;
  notebookType: string;
  version: s32;
  metadata: Any; @$Object @?
  cells: [] LSP_NotebookCell;
}

LSP_NotebookCell :: struct {
  kind: LSP_NotebookCellKind;
  document: LSP_DocumentUri;
  metadata: Any; @$Object @?
  executionSummary: LSP_ExecutionSummary; @?
}

LSP_NotebookCellKind :: enum {
  Markup :: 1;
  Code :: 2;
}

LSP_ExecutionSummary :: struct {
  executionOrder: u32;
  success: bool; @?
}

LSP_NotebookCellTextDocumentFilter :: struct {
  notebook: Any; @string @LSP_NotebookDocumentFilter
  language: string; @?
}

LSP_NotebookDocumentFilter :: struct {
  notebookType; string; @?
  scheme: string; @?
  pattern: string; @?
}

LSP_NotebookDocumentSyncClientCapabilities :: struct {
  dynamicRegistration: bool; @?
  executionSummarySupport: bool; @?
}

LSP_NotebookDocumentSyncOptions :: struct {
  notebookSelector: struct {
    notebook: Any; @string @LSP_NotebookDocumentFilter @?
    cells: [] struct {
      language: string;
    }; @?
  };
  save: bool; @?
}

LSP_NotebookDocumentSyncRegistrationOptions :: struct {
  #as using _0: LSP_NotebookDocumentSyncOptions;
  #as using _1: LSP_StaticRegistrationOptions;
}

LSP_DidOpenNotebookDocumentParams :: struct {
  notebookDocument: LSP_NotebookDocument;
  cellTextDocuments: [] LSP_TextDocumentItem;
}

// Did Change Notebook Document (notebookDocument/didChange)

LSP_VersionedNotebookDocumentIdentifier :: struct {
  version: s32;
  uri: LSP_URI;
}

LSP_NotebookDocumentChangeEvent :: struct {
  metadata: Any; @$Object
  cells: struct {
    structure: struct {
      array: LSP_NotebookCellArrayChange;
      didOpen: [] LSP_TextDocumentItem; @?
      didClose: [] LSP_TextDocumentIdentifier; @?
    }; @?
    data: [] LSP_NotebookCell; @?
    textContent: [] struct {
      document: LSP_VersionedTextDocumentIdentifier;
      changes: [] LSP_TextDocumentContentChangeEvent;
    }; @?
  }; @?
}

LSP_NotebookCellArrayChange :: struct {
  start: u32;
  deleteCount: u32;
  cells: [] LSP_NotebookCell; @?
}

LSP_DidChangeNotebookDocumentParams :: struct {
  notebookDocument: LSP_VersionedNotebookDocumentIdentifier;
  change: LSP_NotebookDocumentChangeEvent;
}

// Did Save Notebook Document (notebookDocument/didSave)

LSP_DidSaveNotebookDocumentParams :: struct {
  notebookDocument: LSP_NotebookDocumentIdentifier;
}

// Did Close Notebook Document (notebookDocument/didClose)

LSP_NotebookDocumentIdentifier :: struct {
  uri: LSP_URI;
}

LSP_DidCloseNotebookDocumentParams :: struct {
  notebookDocument: LSP_NotebookDocumentIdentifier;
  cellTextDocuments: [] LSP_TextDocumentIdentifier;
}

//
// Language Features
//

// Go to Declaration (textDocument/declaration)

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

// Go to Definition (textDocument/definition)

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

//TODO: More

//
// Workspace Features
//

// Workspace Symbols (workspace/symbol)

LSP_WorkspaceSymbolClientCapabilities :: struct {
  dynamicRegistration: bool; @?
  symbolKind: struct {
    valueSet: [] LSP_SymbolKind; @?
  }; @?
  tagSupport: struct {
    valueSet: [] LSP_SymbolTag;
  }; @?
  resolveSupport: struct {
    properties: [] string;
  }; @?
}

LSP_WorkspaceSymbolOptions :: struct {
  #as using _: LSP_WorkDoneProgressOptions;
  resolveProvider: bool; @?
}

LSP_WorkspaceSymbolRegistrationOptions :: struct {
  #as using _: LSP_WorkspaceSymbolOptions;
}

_LSP_WorkspaceSymbol_LocationUri :: struct {
  uri: LSP_DocumentUri;
}
_LSP_WorkspaceSymbols :: [] LSP_WorkspaceSymbol;
LSP_WorkspaceSymbol :: struct {
  name: string;
  kind: LSP_SymbolKind;
  tags: [] LSP_SymbolTag; @?
  containerName: string; @?
  location: Any; @LSP_Location @_LSP_WorkspaceSymbol_LocationUri
  data: Any; @?
}

LSP_WorkspaceSymbolParams :: struct {
  #as using _0: LSP_WorkDoneProgressParams;
  #as using _1: LSP_PartialResultParams;
  query: string;
}

LSP_WorkspaceSymbolResult :: struct {
  _: Any; @_LSP_SymbolInformations @_LSP_WorkspaceSymbols @$Null
}

LSP_WorkspaceSymbolPartialResult :: struct {
  _: Any; @_LSP_SymbolInformations @_LSP_WorkspaceSymbols
}

// Workspace Symbol Resolve (workspaceSymbol/resolve)

LSP_WorkspaceSymbolResolveParams :: LSP_WorkspaceSymbol;

LSP_WorkspaceSymbolResolveResult :: LSP_WorkspaceSymbol;

// Get Configuration (workspace/configuration)

LSP_ConfigurationItem :: struct {
  scopeUri: LSP_URI; @?
  section: string; @?
}

LSP_ConfigurationParams :: struct {
  items: [] LSP_ConfigurationItem;
}

LSP_ConfigurationResult :: struct {
  _: [] Any;
}

// Did Change Configuration (workspace/didChangeConfiguration)

LSP_DidChangeConfigurationClientCapabilities :: struct {
  dynamicRegistration: bool; @?
}

LSP_DidChangeConfigurationParams :: struct {
  settings: Any;
}

// Workspace Folders (workspace/workspaceFolders)

_LSP_WorkspaceFolders :: [] LSP_WorkspaceFolder;
LSP_WorkspaceFolder :: struct {
  uri: LSP_URI;
  name: string;
}

LSP_WorkspaceFoldersServerCapabilities :: struct {
  supported: bool; @?
  changeNotifications: Any; @? @string @bool
}

LSP_WorkspaceFoldersResult :: struct {
  _: Any; @_LSP_WorkspaceFodlers @$Null
}

// Did Change Workspace Folders (workspace/didChangeWorkspaceFolders)

LSP_WorkspaceFoldersChangeEvent :: struct {
  added: [] LSP_WorkspaceFolder;
  removed: [] LSP_WorkspaceFolder;
}

LSP_DidChangeWorkspaceFoldersParams :: struct {
  event: LSP_WorkspaceFoldersChangeEvent;
}

// Will Create Files (workspace/willCreateFiles)

LSP_FileOperationRegistrationOptions :: struct {
  filters: [] LSP_FileOperationFilter;
}

LSP_FileOperationPatternKind :: string;
LSP_FileOperationPatternKind_File :: "file";
LSP_FileOperationPatternKind_Folder :: "folder";

LSP_FileOperationPatternOptions :: struct {
  ignoreCase: bool; @?
}

LSP_FileOperationPattern :: struct {
  glob: string;
  matches: LSP_FileOperationPatternKind; @?
  options: LSP_FileOperationPatternOptions; @?
}

LSP_FileOperationFilter :: struct {
  scheme: string; @?
  pattern: LSP_FileOperationPattern;
}

LSP_FileCreate :: struct {
  uri: string;
}

LSP_CreateFilesParams :: struct {
  files: [] LSP_FileCreate;
} 

LSP_CreateFilesResult :: struct {
  _: Any; @LSP_WorkspaceEdit @$Null
}

//TODO: Check what happens if the results are just optional instead of Any w/ $Null

// Did Create Files (workspace/didCreateFiles)

LSP_DidCreateFilesParams :: LSP_CreateFilesParams;

// Will Rename Files (workspace/willRenameFiles)

LSP_FileRename :: struct {
  oldUri: string;
  newUri: string;
}

LSP_RenameFilesParams :: struct {
  files: [] LSP_FileRename;
}

LSP_RenameFilesResult :: struct {
  _: Any; @LSP_WorkspaceEdit @$Null
}

// Did Rename Files (workspace/didRenameFiles)

LSP_DidRenameFilesParams :: LSP_RenameFilesParams;

// Will Delete Files (workspace/willDeleteFiles)

LSP_FileDelete :: struct {
  uri: string;
}

LSP_DeleteFilesParams :: struct {
  files: [] LSP_FileDelete;
}

LSP_DeleteFilesResult :: struct {
  _: Any; @LSP_WorkspaceEdit @$Null
}

// Did Delete Files (workspace/didDeleteFiles)

LSP_DidDeleteFilesParams :: LSP_DeleteFilesParams;

// Did Change Watched Files

LSP_DidChangeWatchedFilesClientCapabilities :: struct {
  dynamicRegistration: bool; @?
  relativePatternSupport: bool; @?
}

LSP_DidChangeWatchedFilesRegistrationOptions :: struct {
  watchers: [] LSP_FileSystemWatcher;
}

LSP_Pattern :: string;

LSP_RelativePattern :: struct {
  baseUri: Any; @LSP_WorkspaceFolder @LSP_URI
  pattern: LSP_Pattern;
}

LSP_GlobPattern :: struct {
  _: Any; @LSP_Pattern @LSP_RelativePattern
}

LSP_FileSystemWatcher :: struct {
  globPattern: LSP_GlobPattern;
  kind := LSP_WatchKind.Create; @?
}

LSP_WatchKind :: enum u32 {
  Create :: 1;
  Change :: 2;
  Delete :: 4;
}

LSP_FileEvent :: struct {
  uri: LSP_DocumentUri;
  type: LSP_FileChangeType;
}

LSP_FileChangeType :: enum u32 {
  Created :: 1;
  Changed :: 2;
  Deleted :: 3;
}

LSP_DidChangeWatchedFilesParams :: struct {
  changes: [] LSP_FileEvent;
}

// Execute Command (workspace/executeCommand)

LSP_ExecuteCommandClientCapabilities :: struct {
  dynamicRegistration: bool; @?
}

LSP_ExecuteCommandOptions :: struct {
  #as using _: LSP_WorkDoneProgressOptions;
  commands: [] string;
}

LSP_ExecuteCommandRegistrationOptions :: struct {
  #as using _: LSP_ExecuteCommandOptions;
}

LSP_ExecuteCommandParams :: struct {
  #as using _: LSP_WorkDoneProgressParams;
  command: string;
  arguments: [] Any; @?
}

LSP_ExecuteCommandResult :: struct {
  _: Any;
}

// Apply Edit (workspace/applyEdit)

LSP_ApplyWorkspaceEditParams :: struct {
  label: string; @?
  edit: LSP_WorkspaceEdit;
}

LSP_ApplyWorkspaceEditResult :: struct {
  applied: bool;
  failureReason: string; @?
  failedChange: u32; @?
}

//
// Window Features
//

// Show Message Notification (window/showMessage)

LSP_MessageType :: enum {
  Error :: 1;
  Warning :: 2;
  Info :: 3;
  Log :: 4;
  Debug :: 5;
}

LSP_ShowMessageParams :: struct {
  type: LSP_MessageType;
  message: string;
}

// Show Message Request

LSP_ShowMessageRequestClientCapabilities :: struct {
  messageActionItem: struct {
    additionalPropertiesSupport: bool; @?
  }; @?
}

LSP_MessageActionItem :: struct {
  title: string;
}

LSP_ShowMessageRequestParams :: struct {
  type: LSP_MessageType;
  message: string;
  actions: [] LSP_MessageActionItem; @?
}

LSP_ShowMessageRequestResult :: struct {
  _: Any; @LSP_MessageActionItem @$Null
}

// Log Message (window/logMessage)

LSP_LogMessageParams :: struct {
  type: LSP_MessageType;
  message: string;
}

// Show Document Request (window/showDocument)

LSP_ShowDocumentClientCapabilities :: struct {
  support: bool;
}

LSP_ShowDocumentParams :: struct {
  uri: LSP_URI;
  external: bool; @?
  takeFocus: bool; @?
  selection: LSP_Range; @?
}

LSP_ShowDocumentResult :: struct {
  success: bool;
}

// Create Work Done Progress (window/workDoneProgress/create)

LSP_WorkDoneProgressCreateParams :: struct {
  token: LSP_ProgressToken;
}

// Cancel a Work Done Progress (window/workDoneProgress/cancel)

LSP_WorkDoneProgressCancelParams :: struct {
  token: LSP_ProgressToken;
}

// Sent Telemetry (telemetry/event)

LSP_SentTelemetryParams :: struct {
  _: Any; @$Object @$Array
}

#scope_module

#import "Hash_Table";