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

Key_Value :: struct {
    key: string;
    value: string;
}

LSP_Struct :: struct {
    name: string;
    properties: [..]Key_Value;
    extends: [..]string;
}

lsp_structs: [..]LSP_Struct;

generate_struct :: (structures: Json_Any) {
    log("generating % structures", structures.array.count);

    for s: structures.array {
        lsp_s: LSP_Struct;

        s_name, ok0 := json_get(s, "name");
        assert(ok0, "This struct does not have a name");

        lsp_s.name = s_name.str;

        s_props, ok1 := json_get(s, "properties");
        if ok1 {
            for p: s_props.array {
                lsp_p: Key_Value;
                p_name, ok00 := json_get(p, "name");
                assert(ok00, "This property does not have a name");
                lsp_p.key = p_name.str;

                p_type, ok01 := json_get(p, "type");
                assert(ok01, "This property does not have a type");

                t_kind, ok02 := json_get(p_type, "kind");
                assert(ok02, "This type does not have a kind");

                if t_kind.str == "base" || t_kind.str == "reference" {
                    t_name, ok03 := json_get(p_type, "name");
                    assert(ok03, "This type does not have a name");

                    lsp_p.value = t_name.str;
                } else if t_kind.str == "array" {
                    t_element, ok03 := json_get(p_type, "element");
                    assert(ok03, "This type does not have an element");

                    e_name, ok04 := json_get(t_element, "name");
                    assert(ok04, "This element does not have a name, %", lsp_s.name);

                    lsp_p.value = sprint("[]%", e_name.str);
                }

                array_add(*lsp_s.properties, lsp_p);
            }
        }

        s_exts, ok2 := json_get(s, "extends");
        if ok2 {
            for e: s_exts.array {
                e_kind, ok00 := json_get(e, "kind");
                assert(ok00, "This extend does not have a kind");

                assert(e_kind.str == "reference", "This extend is not a reference");

                e_name, ok01 := json_get(e, "name");
                assert(ok01, "This extend does not have a name");

                array_add(*lsp_s.extends, e_name.str);
            }
        }

        s_mixs, ok3 := json_get(s, "mixins");
        if ok3 {
            for m: s_mixs.array {
                m_kind, ok00 := json_get(m, "kind");
                assert(ok00, "This mixin does not have a kind");

                assert(m_kind.str == "reference", "This extend is not a reference");

                m_name, ok01 := json_get(m, "name");
                assert(ok01, "This mixin does not have a name");

                array_add(*lsp_s.extends, m_name.str);
            }
        }

        array_add(*lsp_structs, lsp_s);
    }
}

write_structures :: () {
    sb: String_Builder;
    for s: lsp_structs {
        append(*sb, s.name);
        append(*sb, " :: struct {\n");

        for p: s.properties {
            append(*sb, "    ");
            append(*sb, p.key);
            append(*sb, ": ");
            append(*sb, p.value);
            append(*sb, "\n");
        }

        for e: s.extends {
            append(*sb, "    using ");
            append(*sb, e);
            append(*sb, ";\n");
        }

        append(*sb, "}\n\n");
    }

    write_entire_file("structures.jai", *sb);
}

#import "Basic";
#import "String";
#import "Compiler";
#import "File";
#import "Json";
