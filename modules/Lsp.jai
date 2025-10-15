// This file include language server protocol specification version 3.17, https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification

// integer is s32
// uinteger is u32
// decimal is float

// All the optional field defined in the spec are just plain value, if
// it is a null, return a stub of zero value.

LSP_Type :: enum {
    NULL;
    BOOLEAN;
    INTEGER;
    UINTEGER;
    DECIMAL;
    STRING;
    OBJECT;
    ARRAY;
}

Key_Value :: struct {
    key: string;
    value: LSPAny;
}

// I am too lazy to use a hash table for an object.
LSPObject :: []Key_Value;

LSPAny :: struct {
    type: LSP_Type;
    union {
        boolean: bool;
        integer: s32;
        uinteger: u32;
        decimal: float;
        str: string;
        object: LSPObject;
        array: []LSPAny;
    };
}

Message :: struct {
    jsonrpc: string;
}

RequestMessage :: struct {
    using Message;
    // By jsonrpc standard, id can be int or string, but forget about string now
    id: s32;
    method: string;
    // params can only be a struct or array
    // params: *LSPAny;

    // Since we are so likely to combine a param struct into the
    // RequestMessage, I would rather make a function that does it.
}

ResponseError :: struct {
    code: s32;
    message: string;
    data: *LSPAny;
}

ResponseMessage :: struct {
    using Message;
    // This is weirder, id can be int, string or null in this case.
    id: u32;

    // Result is required on success.
    // result: *LSPAny;

    // Error is in request fail
    // error: *ResponseError;
}

ErrorCodes :: enum s32 {
    // Defined by JSON-RPC
    ParseError           :: -32700;
    InvalidRequest       :: -32600;
    MethodNotFound       :: -32601;
    InvalidParams        :: -32602;
    InternalError        :: -32603;

    /**
     * This is the start range of JSON-RPC reserved error codes.
     * It doesn't denote a real error code. No LSP error codes should
     * be defined between the start and end range. For backwards
     * compatibility the `ServerNotInitialized` and the `UnknownErrorCode`
     * are left in the range.
     *
     * @since 3.16.0
     */
    jsonrpcReservedErrorRangeStart :: -32099;
    // @deprecated use jsonrpcReservedErrorRangeStart
    serverErrorStart     :: jsonrpcReservedErrorRangeStart;

    /**
     * Error code indicating that a server received a notification or
     * request before the server received the `initialize` request.
     */
    ServerNotInitialized :: -32002;
    UnknownErrorCode     :: -32001;

    /**
     * This is the end range of JSON-RPC reserved error codes.
     * It doesn't denote a real error code.
     *
     * @since 3.16.0
     */
    jsonrpcReservedErrorRangeEnd :: -32000;
    // @deprecated use jsonrpcReservedErrorRangeEnd
    serverErrorEnd       :: jsonrpcReservedErrorRangeEnd;

    /**
     * This is the start range of LSP reserved error codes.
     * It doesn't denote a real error code.
     *
     * @since 3.16.0
     */
    lspReservedErrorRangeStart :: -32899;

    /**
     * A request failed but it was syntactically correct, e.g the
     * method name was known and the parameters were valid. The error
     * message should contain human readable information about why
     * the request failed.
     *
     * @since 3.17.0
     */
    RequestFailed        :: -32803;

    /**
     * The server cancelled the request. This error code should
     * only be used for requests that explicitly support being
     * server cancellable.
     *
     * @since 3.17.0
     */
    ServerCancelled      :: -32802;

    /**
     * The server detected that the content of a document got
     * modified outside normal conditions. A server should
     * NOT send this error code if it detects a content change
     * in its unprocessed messages. The result even computed
     * on an older state might still be useful for the client.
     *
     * If a client decides that a result is not of any use anymore
     * the client should cancel the request.
     */
    ContentModified      :: -32801;

    /**
     * The client has canceled a request and a server has detected
     * the cancel.
     */
    RequestCancelled     :: -32800;

    /**
     * This is the end range of LSP reserved error codes.
     * It doesn't denote a real error code.
     *
     * @since 3.16.0
     */
    lspReservedErrorRangeEnd :: -32800;
}

NotificationMessage :: struct {
    using Message;
    method: string;
    // params: *Json_Value; // Only array or object
}

CancelParams :: struct {
    id: s32;
}

ProgressToken :: s32;
ProgressParams :: struct ($T: Type) {
    token: ProgressToken;
    value: T;
}

HoverParams :: struct {
    textDocument: string;

    position: struct {
        line: u32;
        character: u32;
    };
}

HoverResult :: struct {
    value: string;
}

DocumentUri :: string;
URI :: string;

// I don't know whether this is useful.
RegularExpressionsClientCapabilities :: struct {
    engine: string;
    version: string;
}

EOL :: string.["\n", "\r\n", "\r"];

Position :: struct {
    line: u32;
    character: u32;
}

PositionEncodingKind :: string;

UTF8 : PositionEncodingKind : "utf-8";
UTF16 : PositionEncodingKind : "utf-16";
UTF32 : PositionEncodingKind : "utf-32";

Range :: struct {
    start: Position;
    end: Position;
}

TextDocumentItem :: struct {
    uri: DocumentUri;
    languageId: string;
    version: s32;
    text: string;
}

TextDocumentIdentifier :: struct {
    uri: DocumentUri;
}

VersionedTextDocumentIdentifier :: struct {
    using TextDocumentIdentifier;
    version: s32;
}

OptionalVersionedTextDocumentIdentifier :: struct {
    using TextDocumentIdentifier;
    version: *s32;
}

TextDocumentPositionParams :: struct {
    textDocument: TextDocumentIdentifier;
    position: Position;
}

// Three members are optional
DocumentFilter :: struct {
    language: string;
    scheme: string;
    pattern: string;
}

DocumentSelector :: []DocumentFilter;

TextEdit :: struct {
    range: Range;
    newText: string;
}

ChangeAnnotation :: struct {
    label: string;
    needsConfirmation: bool; // optional
    description: string; // optional
}

ChangeAnnotationIdentifier :: string;

AnnotatedTextEdit :: struct {
    using TextEdit;
    annotationId: ChangeAnnotationIdentifier;
}

TextDocumentEdit :: struct {
    TextDocument: OptionalVersionedTextDocumentIdentifier;
    // edits is either an array of TextEdit or AnnotatedTextEdit, but
    // the latter is only supported in version 3.16
    edits: []AnnotatedTextEdit;
}

Location :: struct {
    uri: DocumentUri;
    range: Range;
}

LocationLink :: struct {
    originSelectionRange: Range; // optional
    targetUri: DocumentUri;
    targetRange: Range;
    targetSelectionRange: Range;
}

Diagnostic :: struct {
    range: Range;
    severity: DiagnosticSeverity; // optional
    code: s32; // optional
    codeDescription: CodeDescription; // optional
    source: string; // optional
    message: string;
    tags: []DiagnosticTag; // optional
    relatedInformation: []DiagnosticRelatedInformation; // optional
    data: LSPAny; // optional
}

DiagnosticSeverity :: enum s32 {
    /**
     * Reports an error.
     */
    Error        :: 1;

    /**
     * Reports a warning.
     */
    Warning      :: 2;

    /**
     * Reports an information.
     */
    Information  :: 3;

    /**
     * Reports a hint.
     */
    Hint         :: 4;
}

DiagnosticTag :: enum s32 {
    /**
     * Unused or unnecessary code.
     *
     * Clients are allowed to render diagnostics with this tag faded out
     * instead of having an error squiggle.
     */
    Unnecessary  :: 1;

    /**
     * Deprecated or obsolete code.
     *
     * Clients are allowed to rendered diagnostics with this tag strike through.
     */
    Deprecated   :: 2;
}

/**
 * Represents a related message and source code location for a diagnostic.
 * This should be used to point to code locations that cause or are related to
 * a diagnostics, e.g when duplicating a symbol in a scope.
 */
DiagnosticRelatedInformation :: struct {
    /**
    * The location of this related diagnostic information.
    */
    location: Location;

    /**
    * The message of this related diagnostic information.
    */
    message: string;
}

CodeDescription :: struct {
    href: URI;
}

Command :: struct {
    /**
     * Title of the command, like `save`.
     */
    title: string;
    /**
     * The identifier of the actual command handler.
     */
    command: string;
    /**
     * Arguments that the command handler should be
     * invoked with.
     */
    arguments: []LSPAny; // optional
}

MarkupKind :: enum {
    plaintext;
    markdown;
}

MarkupContent :: struct {
    kind: MarkupKind;
    value: string;
}

MarkdownClientCapabilities :: struct {
    parser: string;
    version: string;
    allowedTags: []string;
}

CreateFileOptions :: struct {
    overwrite: bool; // optional
    ignoreIfExists: bool; // optional
}

CreateFile :: struct {
    kind := "create";
    uri: DocumentUri;
    options: CreateFileOptions; // optional
    annotationId: ChangeAnnotationIdentifier; // optional
}

RenameFileOptions :: struct {
    overwrite: bool; // optional
    ignoreIfExists: bool; // optional
}

RenameFile :: struct {
    kind := "rename";
    oldUri: DocumentUri;
    newUri: DocumentUri;
    options: RenameFileOptions; // optional
    annotationId: ChangeAnnotationIdentifier; // optional
}

DeleteFileOptions :: struct {
    recursive: bool; // optional
    ignoreIfNotExists: bool; // optional
}

DeleteFile :: struct {
    kind := "delete";
    uri: DocumentUri;
    options: DeleteFileOptions; // optional
    annotationId: ChangeAnnotationIdentifier; // optional
}

WorkspaceEdit :: struct {
    changes: LSPObject; // optional { [uri: DocumentUri]: TextEdit[]; }
    documentChanges: LSPObject; // optional ( TextDocumentEdit[] |		(TextDocumentEdit | CreateFile | RenameFile | DeleteFile)[] )
    changeAnnotations: LSPObject; // optional { [id: string ]: ChangeAnnotation; }
}

WorkspaceEditClientCapabilities :: struct {
    documentChanges: bool; // optional
    resourceOperations: []ResourceOperationKind; // optional
    failureHandling: FailureHandlingKind; // optional
    normalizesLineEndings: bool; // optional
    changeAnnotationSupport: struct {
        groupsOnLabel: bool; // optional
    }; // optional
}

ResourceOperationKind :: enum {
    create;
    rename;
    delete;
}

FailureHandlingKind :: enum {
    abort;
    transactional;
    textOnlyTransactional;
    undo;
}

WorkDoneProgressBegin :: struct {
    kind := "begin";
    title: string;
    cancellable: bool; // optional
    message: string; // optional
    percentage: u32; // optional
}

WorkDoneProgressReport :: struct {
    kind := "report";
    cancellable: boolean; // optional
    message: string; // optional
    percentage: u32; // optional
}

WorkDoneProgressEnd :: struct {
    kind := "end";
    message: string; // optional
}

WorkDoneProgressParams :: struct {
    workDoneToken: ProgressToken; // optional
}

WorkDoneProgressOptions :: struct {
    workDoneProgress: bool; // optional
}

WorkDoneProgressOptions :: struct {
    partialResultToken: ProgressToken; // optional
}

TraceValue :: enum {
    off;
    messages;
    verbose;
}
