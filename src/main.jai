main :: () {
    output_log_file = file_open_append("lsp.log");

    context.logger = lsp_log;

    while true {
        s, ok := read_line_from_stdin();
        if !ok exit(69);
        log("got a line: %", s);
    }
}

#import "Basic";

#load "utils.jai";
