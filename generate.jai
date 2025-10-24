#run {
    set_build_options_dc(.{do_output = false});

    generate();
}

generate :: () {
    s := read_entire_file("metaModel.json");

    meta_model, result := parse_json(s);
    if result != .OK {
        log("%", result);
        return;
    }

    {
        metadata, ok0 := json_get(meta_model, "metaData");
        assert(ok0);
        version, ok1 := json_get(metadata, "version");
        assert(ok1);

        log("generating binding for lsp version %", version.str);
    }

    {
        structures, ok := json_get(meta_model, "structures");
        assert(ok);
        generate_struct(structures);
    }
}

generate_struct :: (structures: Json_Any) {
    log("generating % structures", structures.array.count);

    for structures.array {
        name := json_get(it, "name");
        log("%", name.str);
    }
}

#import "Basic";
#import "String";
#import "Compiler";
#import "File";
#import "Json";
