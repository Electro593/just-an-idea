lsp_initialize :: (data: *void, params: LSP_InitializeParams) -> LSP_Null {
  return .{};
}

#scope_file

LSP_Null     :: struct { value: Any; @$Null }
LSP_Object   :: struct { value: Any; @$Object }
LSP_Any      :: struct {
  value: Any; @LSP_Null @LSP_Boolean @LSP_Integer @LSP_UInteger @LSP_Decimal @LSP_String @LSP_Array @LSP_Object
}

LSP_CancelParams :: struct {
  id: Any; @LSP_Integer @LSP_String
}

LSP_ProgressParams :: struct {
  LSP_ProgressToken :: struct {
    value: Any; @LSP_Integer @LSP_String
  }
  
  token: LSP_ProgressToken;
  value: Any;
}

LSP_DocumentUri :: string;
LSP_URI :: string;

LSP_RegularExpressionsClientCapabilities :: struct {
  PROPERTY_PATH :: "general.regularExpressions";
  //TODO Enum values, regex
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
  languageId: string;
  version: s32;
  text: string;
}
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

LSP_Location :: struct {
  uri: LSP_DocumentUri;
  range: LSP_Range;
}

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
  arguments: [] LSP_Any; @?
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
  kind: string = "create";
  uri: LSP_DocumentUri;
  options: LSP_CreateFileOptions; @?
  annotationId: LSP_ChangeAnnotationIdentifier; @?
}
LSP_RenameFileOptions :: struct {
  overwrite: bool; @?
  ignoreIfExists: bool; @?
}
LSP_RenameFile :: struct {
  kind: string = "rename";
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
  kind: string = "delete";
  uri: LSP_DocumentUri;
  options: LSP_DeleteFileOptions; @?
  annotationId: LSP_ChangeAnnotationIdentifier; @?
}

LSP_WorkspaceEdit :: struct {
  //TODO: Halp.. maybe some frobs?
  //TODO: Also, fix unions or something
  changes: Table(LSP_DocumentUri, [] LSP_TextEdit); @?
  documentChanges: [] Any; @? @LSP_TextDocumentEdit @LSP_CreateFile @LSP_RenameFile @LSP_DeleteFile
  changeAnnotations: Table(string, LSP_ChangeAnnotation); @?
}


LSP_InitializeParams :: struct {
}