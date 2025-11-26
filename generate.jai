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
        write_structures();
    }
}

LSP_Prop :: struct {
    name: string;
    type: string;
    optional: bool;
    accepted_types: []string;
    documentation: string;
}

LSP_Struct :: struct {
    name: string;
    properties: [..]LSP_Prop;
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
                lsp_p: LSP_Prop;
                p_name, ok00 := json_get(p, "name");
                assert(ok00, "This property does not have a name");
                lsp_p.name = p_name.str;

                p_type, ok01 := json_get(p, "type");
                assert(ok01, "This property does not have a type");

                t_kind, ok02 := json_get(p_type, "kind");
                assert(ok02, "This type does not have a kind");

                if t_kind.str == {
                case "base";
                    #through;
                case "reference";
                    t_name, ok000 := json_get(p_type, "name");
                    assert(ok000, "This type does not have a name");

                    lsp_p.type = t_name.str;

                case "array";
                    n, ok000 := array_type_to_string(p_type);
                    assert(ok000, "This array is wrong, %", lsp_s.name);

                    lsp_p.type = n;
                case "or";
                    ss, ok000 := or_type_to_strings(p_type);
                    assert(ok000, "This or is wrong, %", lsp_s.name);

                    lsp_p.accepted_types = ss;
                case "map";
                    n, ok000 := map_type_to_string(p_type);
                    assert(ok000, "This map is wrong, %", lsp_s.name);

                    lsp_p.type = n;
                case;
                    assert(false, "Unhandled kind (%) in %", t_kind.str, lsp_s.name);
                }

                p_optional, ok03 := json_get(p, "optional");
                if ok03 {
                    lsp_p.optional = p_optional.boolean;
                }

                p_doc, ok04 := json_get(p, "documentation");
                if ok04 {
                    lsp_p.documentation = p_doc.str;
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
            append(*sb, p.name);
            append(*sb, ": ");

            if p.optional {
                append(*sb, "Anyx = .{optional = true, accepted_types = .[");

                if p.accepted_types.count == 0 {
                    append(*sb, "type_info(");
                    append(*sb, p.type);
                    append(*sb, ")");
                } else {
                    for p.accepted_types {
                        append(*sb, "type_info(");
                        append(*sb, it);
                        append(*sb, ")");

                        if it_index != p.accepted_types.count - 1 {
                            append(*sb, ", ");
                        }
                    }
                }

                append(*sb, "]};\n");
            } else {
                append(*sb, p.type);
                append(*sb, ";\n");
            }
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

array_type_to_string :: (array_type: Json_Any) -> string, bool {
    e, ok0 := json_get(array_type, "element");
    if !ok0 return "", false;

    e_kind, ok1 := json_get(e, "kind");
    if !ok1 return "", false;

    if e_kind.str == {
    case "reference";
        #through;
    case "base";
        n, ok := json_get(e, "name");;
        if !ok return "", false;

        return sprint("[]%", n.str), true;
    case "or";
        items, ok := json_get(e, "items");
        if !ok return "", false;

        ss: [..]string;
        for items.array {
            kind, ok00 := json_get(it, "kind");
            if !ok00 return "", false;

            if kind.str != "reference" || kind.str != "base" {
                return "", false;
            }

            name, ok01 := json_get(it, "name");
            if !ok01 return "", false;

            array_add(*ss, name.str);
        }

        sb: String_Builder;
        append(*sb, "Anyx = .{accepted_types = .[");
        for ss {
            append(*sb, "type_info(");
            append(*sb, it);
            append(*sb, ")");

            if it_index != ss.count - 1 {
                append(*sb, ", ");
            }
        }

        append(*sb, "]}");

        return builder_to_string(*sb), true;
    case;
        return "", false;
    }
}

or_type_to_strings :: (or_type: Json_Any) -> []string, bool {
    items, ok0 := json_get(or_type, "items");
    if !ok0 return .[], false;

    ss: [..]string;

    for items.array {
        kind, ok1 := json_get(it, "kind");
        if !ok1 return .[], false;

        if kind.str == {
        case "reference";
            #through;
        case "base";
            name, ok2 := json_get(it, "name");
            if !ok2 return .[], false;
            array_add(*ss, name.str);
        case;
            return .[], false;
        }
    }

    return ss, true;
}

map_type_to_string :: (map_type: Json_Any) -> string, bool {
    key, ok0 := json_get(map_type, "key");
    if !ok0 return "", false;

    key_kind, ok1 := json_get(key, "kind");
    if !ok1 return "", false;

    if key_kind.str != "base" && key_kind.str != "reference" {
        return "", false;
    }

    key_name, ok2 := json_get(key, "name");
    if !ok2 return "", false;

    value, ok3 := json_get(map_type, "value");
    if !ok3 return "", false;

    value_kind, ok4 := json_get(value, "kind");
    if !ok4 return "", false;

    if value_kind.str == {
    case "base";
        #through;
    case "reference";
        value_name, ok := json_get(value, "name");
        if !ok return "", false;

        return sprint("Table(%, %)", key_name.str, value_name.str), true;
    case "array";
        value_name, ok := array_type_to_string(value);
        if !ok return "", false;

        return sprint("Table(%, %)", key_name.str, value_name), true;
    case;
        return "", false;
    }
}

#import "Basic";
#import "String";
#import "Compiler";
#import "File";
#import "Json";
