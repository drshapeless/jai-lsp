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

LSP_Type_Kind :: enum {
    BASE;
    REFERENCE;
    OR;
    ARRAY;
    MAP;
}

LSP_Type :: struct {
    kind: LSP_Type_Kind;
}

LSP_Type_Base :: struct {
    using #as type: LSP_Type;
    name: string;
}

LSP_Type_Reference :: struct {
    using #as type: LSP_Type;
    name: string;
}

LSP_Type_Or :: struct {
    using #as type: LSP_Type;
    items: [] *LSP_Type;
}

LSP_Type_Array :: struct {
    using #as type: LSP_Type;
    element: *LSP_Type;
}

LSP_Type_Map :: struct {
    using #as type: LSP_Type;
    key: *LSP_Type;
    value: *LSP_Type;
}

LSP_Prop :: struct {
    name: string;
    type: *LSP_Type;
    optional: bool;
    documentation: string;
}

LSP_Struct :: struct {
    name: string;
    properties: [..]LSP_Prop;
    extends: [..]string;
    documentation: string;
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

            } else {
                if #complete p.type.type == {
                case .BASE;
                    t_b := cast(*LSP_Type_Base)p.type;
                    append(*sb, t_b.name);

                case .REFERENCE;
                    t_r := cast(*LSP_Type_Reference)p.type;
                    append(*sb, t_r.name);

                case .OR;
                    t_o := cast(*LSP_Type_Or)p.type;
                    append(*sb, "Anyx = .{ accepted_types = .[");
                    for t_o.items {

                    }
                    append(*sb, "]}")
                }
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

generate_struct_property :: (j: Json_Any) -> LSP_Prop, success:bool {
    p: LSP_Prop;
    p_name, ok0 := json_get(j, "name");
    if !ok0 return .{}, false;

    p.name = p_name.str;

    p_optional, ok1 := json_get(j, "optional");
    if ok1 {
        p.optional = p_optional.boolean;
    }

    p_doc, ok2 := json_get(j, "documentation");
    if ok2 {
        p.documentation = p_doc.str;
    }

    p_type, ok3 := json_get(j, "type");
    if !ok3 return .{}, false;

    t := generate_property_type(p_type);

    if t == null return .{}, false;

    p.type = t;

    return p, true;
}

generate_property_type :: (j: Json_Any) -> *LSP_Type {
    t_kind, ok := json_get(j, "kind");
    if !ok return null;

    t: *LSP_Type = null;
    if t_kind.str == {
    case "base";
        t_b := New(LSP_Type_Base);
        name, ok0 := json_get(j, "name");
        if ok0 {
            t_b.name = name.str;

            t = t_b;
        }

    case "reference";
        t_r := New(LSP_Type_Reference);
        name, ok0 := json_get(j, "name");
        if ok0 {
            t_r.name = name.str;

            t = t_r;
        }

    case "or";
        t_o := New(LSP_Type_Or);
        items, ok0 := json_get(j, "items");
        if ok0 {
            for items.array {
                tt := generate_property_type(it);

                if tt == null return null;

                array_add(*t_o.items, tt);
            }

            t = t_o;
        }

    case "array";
        t_a := New(LSP_Type_Array);
        element, ok0 := json_get(j, "element");
        if ok0 {
            tt := generate_property_type(element);

            if tt == null return null;

            t_a.element = tt;

            t = t_a;
        }

    case "map";
        t_m := New(LSP_Type_Map);
        key, ok0 := json_get(j, "key");
        if !ok0 return null;

        ttk := generate_property_type(key);
        if ttk == null return null;
        t_m.key = ttk;

        value, ok1 := json_get(j, "value");
        if !ok1 return null;
        ttv := generate_property_type(value);
        if ttv == null return null;
        t_m.value = ttv;
    }

    return t;
}

lsp_type_to_string :: (t: *LSP_Type, optional: bool = false) -> string {
    s: string;

    if t.kind == .OR {
        s = lsp_type_to_string_or(t, optional);
    } else if optional {
        sb: String_Builder;
        append(*sb, "Anyx = .{optional = true, accepted_types = .[type_info(");
        if t.kind == {
        case .BASE;
            append(*sb, lsp_type_to_string_base(t));

        case .REFERENCE;
            append(*sb, lsp_type_to_string_reference(t));

        case .ARRAY;
            append(*sb, lsp_type_to_string_array(t));

        case .MAP;
            append(*sb, lsp_type_to_string_map(t));
        }

        append(*sb, ")]}");
        s = builder_to_string(*sb);
    } else {
        if t.kind == {
        case .BASE;
            s = lsp_type_to_string_base(t);
        case .REFERENCE;
            s = lsp_type_to_string_reference(t);
        case .ARRAY;
            s = lsp_type_to_string_array(t);
        case .MAP;
            s = lsp_type_to_string_map(t);
        }
    }

    return s;
}

lsp_type_to_string_base :: (t: *LSP_Type) -> string {
    tt := cast(*LSP_Type_Base);

    return tt.name;
}

lsp_type_to_string_reference :: (t: *LSP_Type) -> string {
    tt := cast(*LSP_Type_Reference);

    return tt.name;
}

lsp_type_to_string_array :: (t: *LSP_Type) -> string {
    tt := cast(*LSP_Type_Array);

    assert(tt.kind == .BASE || tt.kind == .REFERENCE, "Weird element in array, %", tt.kind);

    s: string;
    if tt.element.kind == {
    case .BASE;
        s = sprint("[]%", lsp_type_to_string_base(tt.element));
    case .REFERENCE;
        s = sprint("[]%", lsp_type_to_string_reference(tt.element));
    }

    return s;
}

lsp_type_to_string_map :: (t: *LSP_Type) -> string {
    tt := cast(*LSP_Type_Map);

    assert(tt.key.kind == .BASE, "Map doesn't only have base as key, %", tt.key.kind);

    sb: String_Builder;
    append(*sb, "Table(");
    append(*sb, lsp_type_to_string_base(tt.key));
    append(*sb, ", ");

    if tt.key.kind == .OR {
        // This is a disaster, I don't have a good way to make this work.

        // Currently I create a new struct in place with default Anyx
        // value and hoping everything would be right.
        append(*sb, "Map_Value);\n");
        append(*sb, "    Map_Value :: struct {\n");
        append(*sb, "        value: ");
        append(*sb, lsp_type_to_string_or(tt.value));
        append(*sb, "\n    }");

        // TODO: But this results in an extra semi-colon at the end.
    } else {
        append(*sb, lsp_type_to_string(tt.value));
        append(*sb, ")");
    }

    return builder_to_string(*sb);
}

lsp_type_to_string_or :: (t: *LSP_Type, optional: bool = false) -> string {
    tt := cast(*LSP_Type_Or);

    sb: String_Builder;
    append(*sb, "Anyx = .{");
    if optional {
        append(*sb, "optional = true, ")
    }

    append(*sb, "accepted_types = .[");
    for tt.items {
        append(*sb, "type_info(");
        if it.kind == {
        case .BASE;
            append(*sb, lsp_type_to_string_base(it));
        case .REFERENCE;
            append(*sb, lsp_type_to_string_reference(it));
        case .ARRAY;
            append(*sb, lsp_type_to_string_array(it));
        case .MAP;
            assert(false, "Wait, or type has a map?");
        case;
            assert(false, "Weird type in or type, %", it.kind);
        }
        append(*sb, ")");

        if it_index != tt.items.count - 1 {
            append(*sb, ", ");
        }
    }

    append(*sb, "]}");
}

#import "Basic";
#import "String";
#import "Compiler";
#import "File";
#import "Json";
