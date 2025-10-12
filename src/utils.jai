read_from_stdin :: (data: *void, size: u64) -> bool {
    posix :: #import "POSIX";
    result := posix.read(posix.STDIN_FILENO, data, size);
    if result >= 0 return true; else return false;
}

read_line_from_stdin :: () -> string, bool {
    sb: String_Builder;

    c: u8;
    while c != #char "\n" {
        ok := read_from_stdin(*c, 1);
        if !ok return "", false;

        append(*sb, c);
    }

    return builder_to_string(*sb), true;
}

file_open_append :: (name: string) -> File {
    posix :: #import "POSIX";

    handle := posix.fopen(temp_c_string(name), "a");

    return File.{
        handle = handle,
    };
}

output_log_file: File;

lsp_log :: (message: string, data: *void, info: Log_Info) {
    file_write(*output_log_file, message);
    file_write(*output_log_file, "\n");
    file_flush(*output_log_file);
}

#scope_file
#import "Basic";
#import "File";
