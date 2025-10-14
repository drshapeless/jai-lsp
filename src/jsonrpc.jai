Message :: struct {
    jsonrpc: string;
}

Request_Message :: struct {
    using Message;
    // By jsonrpc standard, id can be int or string, but forget about string now
    id: s32;
    method: string;
    // params can only be a struct or array
    params: *Json_Value;
}

Response_Error :: struct {
    code: s32;
    message: string;
    data: *Json_Value;
    error: *Json_Value;
}

Response_Message :: struct {
    using Message;
    // This is weirder, id can be int, string or null in this case.
    id: u32;
    result: *Json_Value;
    error: *Response_Error;
}

Error_Codes :: enum s32 {
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

Notification_Message :: struct {
    using Message;
    method: string;
    params: *Json_Value; // Only array or object
}

Cancel_Params :: struct {
    id: s32;
}

Progress_Token :: s32;
Progress_Params :: struct {
    token: Progress_Token;
    value: *Json_Value;
}

Hover_Params :: struct {
    textDocument: string;
    // I am not sure whether this would compile.
    position: struct {
        line: u32;
        character: u32;
    };
}

Hover_Result :: struct {
    value: string;
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

DocumentUri :: string;
URI :: string;

TextDocumentItem :: struct {
    uri: DocumentUri;
    languageId: string;
    version: s32;
    text: string;
}

#scope_file
#import "Json";
