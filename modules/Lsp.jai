// This file include language server protocol specification version 3.17, https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/

// integer is s32
// uinteger is u32
// decimal is float

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
    params: *LSPAny;
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
    result: *LSPAny;
    error: *ResponseError;
}

ErrorCodes :: enum s32 {
    // Defined by JSON-RPC
    ParseError           :: -32700;
    InvalidRequest       :: -32600;
    MethodNotFound       :: -32601;
    InvalidParams        :: -32602;
    InternalError        :: -32603;

    // JSON-RPC reserved error range start
    jsonrpcReservedErrorRangeStart :: -32099;
    serverErrorStart               :: jsonrpcReservedErrorRangeStart; // Deprecated alias

    // Specific JSON-RPC errors
    ServerNotInitialized :: -32002;
    UnknownErrorCode     :: -32001;

    // JSON-RPC reserved error range end
    jsonrpcReservedErrorRangeEnd :: -32000;
    serverErrorEnd               :: jsonrpcReservedErrorRangeEnd; // Deprecated alias

    // LSP reserved error range start
    lspReservedErrorRangeStart :: -32899;

    // LSP-specific errors
    RequestFailed     :: -32803;
    ServerCancelled   :: -32802;
    ContentModified   :: -32801;
    RequestCancelled  :: -32800;

    // LSP reserved error range end
    lspReservedErrorRangeEnd :: -32800;
}

NotificationMessage :: struct {
    using Message;
    method: string;
    params: *Json_Value; // Only array or object
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

DocumentFilter :: struct {
    language: *string;
    scheme: *string;
    pattern: *string;
}

DocumentSelector :: []DocumentFilter;

TextEdit :: struct {
    range: Range;
    newText: string;
}
