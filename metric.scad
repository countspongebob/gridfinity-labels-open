////////////////////////////////////////////////////////
//         Parts Bin Label Generator - METRIC         //
//          ISO Metric Machine Screw Support          //
//                    Version 106                     //
////////////////////////////////////////////////////////

/* [Single Label Mode] */
hardware_type = "Button head bolt"; // [Phillips head bolt, Socket head bolt, Hex head bolt, Button head bolt, Torx head bolt, Robertson pan head, Robertson flat head, Carriage bolt, Phillips head countersunk, Torx head countersunk, Socket head countersunk, Phillips wood screw, Torx wood screw, Wall anchor, Heat set insert, Standard nut, Lock nut, Standard washer, Spring washer, Custom text, None]
thread_spec = "M5"; // [M2, M2.5, M3, M4, M5, M6, M8, M10, M12, M14]
length_input_mm = 16; // Length in millimeters
custom_display_text = ""; // Custom text override (leave blank for auto-generation)
custom_text_only = "Custom"; // Used only when hardware_type is "Custom text"

/* [Multi-Label Mode] */
enable_multi_label = false;
multi_label_spec = "socket: M5x8, M5x12, M5x16, M3x8, M3x12; nut: M5, M3, M4; washer: M5, M3, M4"; // Batch spec: "type: item, item; type: item" - grammar in MULTI-LABEL SPEC PARSER section

/* [Label Properties] */
label_units = 1; // [1:Small (35.8mm), 2:Medium (77.8mm), 3:Large (119.8mm)]
base_color = "#2C3E50"; // Base label color
content_color = "#FFFFFF"; // Text and icon color
export_mode = "Complete"; // [Complete, Base only, Content only]

/* [Typography] */
font_family = "Roboto"; // [Arial, Roboto, Open Sans, Noto Sans, Liberation Sans]
font_weight = "Bold"; // [Regular, Bold, Light, Medium]
text_size = 4.0;
text_mode = "Raised"; // [Raised, Flush]

/* [Advanced Settings] */
label_width = 11.5;
label_thickness = 0.8;
corner_radius = 0.9;
edge_chamfer = 0.2;
raised_height = 0.2;
flush_height = 0.01;
hole_diameter = 1.5;

// Internal calculations
label_length = (label_units == 1) ? 35.8 : (label_units == 2) ? 77.8 : 119.8;
text_height = (text_mode == "Raised") ? raised_height : flush_height;
font_string = str(font_family, ":style=", font_weight);
max_bolt_length = 20 * label_units;
length_mm = length_input_mm; // Direct metric input, no conversion needed

////////////////////////////////////////////////////////
//           METRIC SYSTEM FUNCTIONS                 //
////////////////////////////////////////////////////////

// Standard metric callout: "M5 x 16" (length always in mm)
function generate_metric_display_text(thread, length) =
    str(thread, " x ", length);

function is_nut_or_washer_type(type) =
    type == "Standard nut" || 
    type == "Lock nut" || 
    type == "Standard washer" || 
    type == "Spring washer";

////////////////////////////////////////////////////////
//     METRIC MULTI-LABEL SPEC PARSER (v106)        //
////////////////////////////////////////////////////////
// Structured batch grammar for multi_label_spec (paste-able, no
// code editing). Groups separated by ";", each group:
//     <type>: <item>, <item>, ...
// Items:
//   bolts/screws:  <thread>x<length-mm>       e.g.  M5x8, M4x12.5
//   nuts/washers:  <thread>                   e.g.  M5
//   custom text:   literal label text         e.g.  text: Front, Back
// Type keys (case-insensitive; full customizer type names also work):
//   phillips, socket, hex, button, torx, robertson, rpan, rflat,
//   carriage, phillips-csk, torx-csk, socket-csk, phillips-wood,
//   torx-wood, anchor, insert, nut, locknut, washer, springwasher, text
// Unknown types and malformed items are skipped with a console
// warning; every parsed label is echoed to the console for review.
// Custom text items cannot contain "," or ";" characters.

// --- generic string helpers (OpenSCAD has no regex: built by hand) ---
function _substr(s, b, e) =
    (e <= b) ? "" : chr([for (i = [b : 1 : e - 1]) ord(s[i])]);
function _lc(s) =
    len(s) == 0 ? "" :
    chr([for (i = [0 : 1 : len(s) - 1])
        let(o = ord(s[i])) (o >= 65 && o <= 90) ? o + 32 : o]);
function _split(s, sep) =
    let(m = len(s) == 0 ? [] : search(sep, s, 0),
        pos = len(m) == 0 ? [] : m[0],
        bounds = concat([-1], pos, [len(s)]))
    [for (j = [0 : 1 : len(bounds) - 2]) _substr(s, bounds[j] + 1, bounds[j + 1])];
function _idx(s, c) = let(m = search(c, s)) len(m) == 0 ? -1 : m[0];
function _fns(s, i) = i >= len(s) ? len(s) : (s[i] == " " || s[i] == "\t") ? _fns(s, i + 1) : i;
function _lns(s, i) = i < 0 ? -1 : (s[i] == " " || s[i] == "\t") ? _lns(s, i - 1) : i;
function _trim(s) = let(b = _fns(s, 0), e = _lns(s, len(s) - 1)) b > e ? "" : _substr(s, b, e + 1);
function _num(s, i = 0, acc = 0, dec = false, scale = 0.1, any = false) =
    len(s) == 0 ? undef :
    i >= len(s) ? (any ? acc : undef) :
    s[i] == "." ? (dec ? undef : _num(s, i + 1, acc, true, 0.1, any)) :
    let(d = ord(s[i]) - 48)
    (d < 0 || d > 9) ? undef :
    dec ? _num(s, i + 1, acc + d * scale, true, scale / 10, true) :
    _num(s, i + 1, acc * 10 + d, false, 0.1, true);

// --- type keyword table (aliases -> customizer type names) ---
_TYPE_KEYS = [
    ["phillips", "Phillips head bolt"],
    ["socket", "Socket head bolt"],
    ["hex", "Hex head bolt"],
    ["button", "Button head bolt"],
    ["torx", "Torx head bolt"],
    ["robertson", "Robertson pan head"],
    ["rpan", "Robertson pan head"],
    ["rflat", "Robertson flat head"],
    ["carriage", "Carriage bolt"],
    ["phillips-csk", "Phillips head countersunk"],
    ["torx-csk", "Torx head countersunk"],
    ["socket-csk", "Socket head countersunk"],
    ["phillips-wood", "Phillips wood screw"],
    ["torx-wood", "Torx wood screw"],
    ["anchor", "Wall anchor"],
    ["insert", "Heat set insert"],
    ["nut", "Standard nut"],
    ["locknut", "Lock nut"],
    ["washer", "Standard washer"],
    ["springwasher", "Spring washer"],
    ["text", "Custom text"]
];
function _type_name(k) =
    let(hits = [for (t = _TYPE_KEYS) if (t[0] == k || _lc(t[1]) == k) t[1]])
    len(hits) > 0 ? hits[0] : undef;

// --- metric unit layer: thread + length parsing ---
// Thread: "M" + number (M2 ... M14); "m5" is normalized to "M5"
function _norm_thread(raw) =
    let(t = _trim(raw))
    len(t) < 2 ? undef :
    (t[0] == "m" || t[0] == "M") && _num(_substr(t, 1, len(t))) != undef ?
        str("M", _substr(t, 1, len(t))) : undef;
// Length: millimeters, whole or decimal ("8", "12.5") -> mm value
function _parse_len_mm(s) = _num(s);
function _display_text_for(th, lstr) = str(th, " x ", lstr);

// --- shared grammar layer ---
// Item -> [type, thread, display_text, length_mm], or undef if malformed
function _parse_item(tname, raw) =
    tname == "Custom text" ? [tname, "", raw, 0] :
    let(x = _idx(_lc(raw), "x"))
    (is_nut_or_washer_type(tname) || x < 0) ?
        let(th = _norm_thread(raw))
        (th == undef ?
            (echo(str("MULTI-LABEL: skipped unparseable item '", raw, "'")) undef) :
            [tname, th, is_nut_or_washer_type(tname) ? "" : th, 0]) :
    let(th = _norm_thread(_substr(raw, 0, x)),
        lstr = _trim(_substr(raw, x + 1, len(raw))),
        lmm = _parse_len_mm(lstr))
    (th == undef || lmm == undef || lmm <= 0) ?
        (echo(str("MULTI-LABEL: skipped unparseable item '", raw, "'")) undef) :
    [tname, th, _display_text_for(th, lstr), lmm];

function _parse_group(g) =
    let(ci = _idx(g, ":"))
    ci < 0 ?
        (echo(str("MULTI-LABEL: skipped group without ':' -> '", g, "'")) []) :
    let(key = _lc(_trim(_substr(g, 0, ci))),
        tname = _type_name(key))
    tname == undef ?
        (echo(str("MULTI-LABEL: skipped group, unknown type '", key, "'")) []) :
    [for (item = _split(_substr(g, ci + 1, len(g)), ","))
        let(it = _trim(item))
        if (it != "")
        let(spec = _parse_item(tname, it))
        if (spec != undef) spec];

function parse_multi_label_spec(s) =
    [for (g = _split(s, ";"))
        let(gt = _trim(g))
        if (gt != "")
        each _parse_group(gt)];

////////////////////////////////////////////////////////
//                 MAIN EXECUTION                    //
////////////////////////////////////////////////////////

if (enable_multi_label) {
    generate_multi_labels();
} else {
    // Generate display text if not provided
    final_display_text = (custom_display_text != "") ? custom_display_text :
        (is_nut_or_washer_type(hardware_type) || hardware_type == "Custom text") ? "" :
        generate_metric_display_text(thread_spec, length_input_mm);
    
    create_single_label(
        type = hardware_type,
        thread = thread_spec,
        display_text = final_display_text,
        length_mm = length_mm
    );
}

////////////////////////////////////////////////////////
//              MULTI-LABEL GENERATION               //
////////////////////////////////////////////////////////

module generate_multi_labels() {
    parsed_specs = parse_multi_label_spec(multi_label_spec);
    echo(str("MULTI-LABEL: ", len(parsed_specs), " labels parsed from spec"));
    for (s = parsed_specs)
        echo(str("MULTI-LABEL:   [", s[0], "] ", s[2] != "" ? s[2] : s[1]));
    
    grid_columns = 3;
    h_spacing = label_length + 4;
    v_spacing = 15;
    
    for (i = [0 : 1 : len(parsed_specs) - 1]) {
        spec = parsed_specs[i];
        row = floor(i / grid_columns);
        col = i % grid_columns;
        
        translate([col * h_spacing, -row * v_spacing, 0]) {
            create_single_label(
                type = spec[0],
                thread = spec[1], 
                display_text = spec[2],
                length_mm = spec[3]
            );
        }
    }
}

////////////////////////////////////////////////////////
//              SINGLE LABEL CREATION                //
////////////////////////////////////////////////////////

module create_single_label(type, thread, display_text, length_mm) {
    // Base structure
    if (export_mode == "Complete" || export_mode == "Base only") {
        color(base_color) {
            label_base();
        }
    }
    
    // Content (text and icons)
    if (export_mode == "Complete" || export_mode == "Content only") {
        color(content_color) {
            label_content(type, thread, display_text, length_mm);
        }
    }
}

////////////////////////////////////////////////////////
//                LABEL BASE                         //
////////////////////////////////////////////////////////

module label_base() {
    difference() {
        // Main label body with rounded corners
        hull() {
            for (x = [-label_length/2 + corner_radius, label_length/2 - corner_radius]) {
                for (y = [-label_width/2 + corner_radius, label_width/2 - corner_radius]) {
                    translate([x, y, 0]) {
                        cylinder(h = label_thickness, r = corner_radius);
                    }
                }
            }
        }
        
        // Mounting holes
        for (x = [-(label_length-2)/2, (label_length-2)/2]) {
            translate([x, 0, -0.1]) {
                cylinder(h = label_thickness + 0.2, d = hole_diameter);
            }
        }
    }
}

////////////////////////////////////////////////////////
//               LABEL CONTENT                       //
////////////////////////////////////////////////////////

module label_content(type, thread, display_text, length_mm) {
    if (type == "Custom text") {
        render_text((display_text != "") ? display_text : custom_text_only);
    } else if (is_nut_or_washer_type(type)) {
        render_hardware_icon(type, length_mm);
        render_text(thread);
    } else {
        // Bolts and screws
        render_hardware_icon(type, length_mm);
        final_text = (display_text != "") ? display_text : str(thread, " x ", length_input_mm);
        render_text(final_text);
    }
}

////////////////////////////////////////////////////////
//                TEXT RENDERING                     //
////////////////////////////////////////////////////////

module render_text(text_content) {
    translate([0, -label_width/2 + 2, label_thickness]) {
        linear_extrude(height = text_height) {
            text(text_content, 
                 size = text_size,
                 font = font_string,
                 halign = "center",
                 valign = "center");
        }
    }
}

////////////////////////////////////////////////////////
//               HARDWARE ICONS                      //
////////////////////////////////////////////////////////

module render_hardware_icon(type, length_mm) {
    icon_y_pos = label_width/4;
    
    if (type == "Phillips head bolt") {
        phillips_bolt_icon(length_mm, icon_y_pos);
    } else if (type == "Socket head bolt") {
        socket_bolt_icon(length_mm, icon_y_pos);
    } else if (type == "Hex head bolt") {
        hex_bolt_icon(length_mm, icon_y_pos);
    } else if (type == "Button head bolt") {
        button_bolt_icon(length_mm, icon_y_pos);
    } else if (type == "Torx head bolt") {
        torx_bolt_icon(length_mm, icon_y_pos);
    } else if (type == "Robertson pan head") {
        robertson_pan_icon(length_mm, icon_y_pos);
    } else if (type == "Robertson flat head") {
        robertson_flat_icon(length_mm, icon_y_pos);
    } else if (type == "Carriage bolt") {
        carriage_bolt_icon(length_mm, icon_y_pos);
    } else if (type == "Phillips head countersunk") {
        phillips_countersunk_icon(length_mm, icon_y_pos);
    } else if (type == "Torx head countersunk") {
        torx_countersunk_icon(length_mm, icon_y_pos);
    } else if (type == "Socket head countersunk") {
        socket_countersunk_icon(length_mm, icon_y_pos);
    } else if (type == "Phillips wood screw") {
        phillips_wood_screw_icon(length_mm, icon_y_pos);
    } else if (type == "Torx wood screw") {
        torx_wood_screw_icon(length_mm, icon_y_pos);
    } else if (type == "Wall anchor") {
        wall_anchor_icon(length_mm, icon_y_pos);
    } else if (type == "Heat set insert") {
        heat_insert_icon(length_mm, icon_y_pos);
    } else if (type == "Standard nut") {
        standard_nut_icon(icon_y_pos);
    } else if (type == "Lock nut") {
        lock_nut_icon(icon_y_pos);
    } else if (type == "Standard washer") {
        standard_washer_icon(icon_y_pos);
    } else if (type == "Spring washer") {
        spring_washer_icon(icon_y_pos);
    }
}

////////////////////////////////////////////////////////
//              BOLT STEM HELPER                     //
////////////////////////////////////////////////////////

module bolt_stem(length_mm, start_x, y_pos, stem_width = 2.5) {
    effective_length = min(length_mm, max_bolt_length);
    z_pos = label_thickness;
    
    if (length_mm > max_bolt_length) {
        // Split stem for long bolts
        gap = 2;
        segment_len = (effective_length - gap) / 2;
        
        translate([start_x, y_pos - stem_width/2, z_pos]) {
            cube([segment_len, stem_width, text_height]);
        }
        
        translate([start_x + segment_len + gap, y_pos - stem_width/2, z_pos]) {
            cube([segment_len, stem_width, text_height]);
        }
    } else {
        translate([start_x, y_pos - stem_width/2, z_pos]) {
            cube([effective_length, stem_width, text_height]);
        }
    }
}

////////////////////////////////////////////////////////
//               PHILLIPS HEAD ICONS                 //
////////////////////////////////////////////////////////

module phillips_bolt_icon(length_mm, y_pos) {
    head_x = -min(length_mm, max_bolt_length)/2 - 3;
    z_pos = label_thickness;
    
    translate([head_x, y_pos, z_pos]) {
        difference() {
            cylinder(h = text_height, d = 5);
            translate([-2, -0.4, 0]) cube([4, 0.8, text_height]);
            translate([-0.4, -2, 0]) cube([0.8, 4, text_height]);
        }
    }
    
    translate([head_x + 6, y_pos, z_pos]) {
        intersection() {
            cylinder(h = text_height, d = 5);
            translate([-5, -2.5, 0]) cube([5, 5, text_height]);
        }
    }
    
    bolt_stem(length_mm, head_x + 6, y_pos); // v105: stem butts the dome's flat bearing face
}

module phillips_countersunk_icon(length_mm, y_pos) {
    head_x = -min(length_mm, max_bolt_length)/2 - 2;
    z_pos = label_thickness;
    
    translate([head_x, y_pos, z_pos]) {
        difference() {
            cylinder(h = text_height, d = 5);
            translate([-2, -0.4, 0]) cube([4, 0.8, text_height]);
            translate([-0.4, -2, 0]) cube([0.8, 4, text_height]);
        }
    }
    
    translate([head_x + 4, y_pos, z_pos]) {
        linear_extrude(height = text_height) {
            polygon(points = [[0, -2.5], [3, 0], [0, 2.5]]);
        }
    }
    
    bolt_stem(length_mm, head_x + 5, y_pos);
}

module phillips_wood_screw_icon(length_mm, y_pos) {
    head_x = -min(length_mm, max_bolt_length)/2 - 2;
    z_pos = label_thickness;
    
    translate([head_x, y_pos, z_pos]) {
        difference() {
            cylinder(h = text_height, d = 5);
            translate([-2, -0.4, 0]) cube([4, 0.8, text_height]);
            translate([-0.4, -2, 0]) cube([0.8, 4, text_height]);
        }
    }
    
    translate([head_x + 4, y_pos, z_pos]) {
        linear_extrude(height = text_height) {
            polygon(points = [[0, -2.5], [3, 0], [0, 2.5]]);
        }
    }
    
    stem_length = max(0, length_mm - 2);
    if (stem_length > 0) {
        bolt_stem(stem_length, head_x + 5, y_pos);
        
        tip_x = head_x + 5 + min(stem_length, max_bolt_length);
        translate([tip_x, y_pos, z_pos]) {
            linear_extrude(height = text_height) {
                polygon(points = [[0, -1.25], [2, 0], [0, 1.25]]);
            }
        }
    }
}

////////////////////////////////////////////////////////
//             ROBERTSON HEAD ICONS                  //
////////////////////////////////////////////////////////

module robertson_pan_icon(length_mm, y_pos) {
    head_x = -min(length_mm, max_bolt_length)/2 - 3;
    z_pos = label_thickness;
    
    // Top view - circle with square recess (Robertson square drive)
    translate([head_x, y_pos, z_pos]) {
        difference() {
            cylinder(h = text_height, d = 5);
            translate([-1.1, -1.1, 0]) cube([2.2, 2.2, text_height]);
        }
    }
    
    // Side view - dome profile (same as Phillips)
    translate([head_x + 6, y_pos, z_pos]) {
        intersection() {
            cylinder(h = text_height, d = 5);
            translate([-5, -2.5, 0]) cube([5, 5, text_height]);
        }
    }
    
    // Stem starts at head_x + 6, butting the dome's flat bearing face
    // (flat face half-height 2.5mm > stem half-width 1.25mm: no notch)
    bolt_stem(length_mm, head_x + 6, y_pos);
}

module robertson_flat_icon(length_mm, y_pos) {
    head_x = -min(length_mm, max_bolt_length)/2 - 2;
    z_pos = label_thickness;
    
    // Top view - circle with square recess (Robertson square drive)
    translate([head_x, y_pos, z_pos]) {
        difference() {
            cylinder(h = text_height, d = 5);
            translate([-1.1, -1.1, 0]) cube([2.2, 2.2, text_height]);
        }
    }
    
    // Side view - countersunk flat head triangle (same as Phillips countersunk)
    translate([head_x + 4, y_pos, z_pos]) {
        linear_extrude(height = text_height) {
            polygon(points = [[0, -2.5], [3, 0], [0, 2.5]]);
        }
    }
    
    bolt_stem(length_mm, head_x + 5, y_pos);
}

////////////////////////////////////////////////////////
//               CARRIAGE BOLT ICON                  //
////////////////////////////////////////////////////////

module carriage_bolt_icon(length_mm, y_pos) {
    head_x = -min(length_mm, max_bolt_length)/2 - 3;
    z_pos = label_thickness;
    
    // Top view - solid circle (no tool relief on carriage bolts)
    translate([head_x, y_pos, z_pos]) {
        cylinder(h = text_height, d = 5);
    }
    
    // Side view - dome profile (same as Phillips)
    translate([head_x + 6, y_pos, z_pos]) {
        intersection() {
            cylinder(h = text_height, d = 5);
            translate([-5, -2.5, 0]) cube([5, 5, text_height]);
        }
    }
    
    bolt_stem(length_mm, head_x + 6, y_pos); // v105: stem butts the dome's flat bearing face
}

////////////////////////////////////////////////////////
//                SOCKET HEAD ICONS                  //
////////////////////////////////////////////////////////

module socket_bolt_icon(length_mm, y_pos) {
    head_x = -min(length_mm, max_bolt_length)/2 - 3;
    z_pos = label_thickness;
    
    translate([head_x, y_pos, z_pos]) {
        difference() {
            cylinder(h = text_height, d = 5);
            cylinder(h = text_height, d = 3, $fn = 6);
        }
    }
    
    translate([head_x + 3.5, y_pos - 2.5, z_pos]) {
        cube([4, 5, text_height]);
    }
    
    bolt_stem(length_mm, head_x + 6, y_pos);
}

module socket_countersunk_icon(length_mm, y_pos) {
    head_x = -min(length_mm, max_bolt_length)/2 - 2;
    z_pos = label_thickness;
    
    translate([head_x, y_pos, z_pos]) {
        difference() {
            cylinder(h = text_height, d = 5);
            cylinder(h = text_height, d = 3, $fn = 6);
        }
    }
    
    translate([head_x + 4, y_pos, z_pos]) {
        linear_extrude(height = text_height) {
            polygon(points = [[0, -2.5], [3, 0], [0, 2.5]]);
        }
    }
    
    bolt_stem(length_mm, head_x + 5, y_pos);
}

////////////////////////////////////////////////////////
//                HEX HEAD ICON                      //
////////////////////////////////////////////////////////

module hex_bolt_icon(length_mm, y_pos) {
    head_x = -min(length_mm, max_bolt_length)/2 - 3;
    z_pos = label_thickness;
    
    translate([head_x, y_pos, z_pos]) {
        cylinder(h = text_height, d = 5, $fn = 6);
    }
    
    translate([head_x + 3.5, y_pos - 2.5, z_pos]) {
        cube([3, 5, text_height]);
    }
    
    bolt_stem(length_mm, head_x + 5.5, y_pos);
}

////////////////////////////////////////////////////////
//               BUTTON HEAD ICON                    //
////////////////////////////////////////////////////////

module button_bolt_icon(length_mm, y_pos) {
    head_x = -min(length_mm, max_bolt_length)/2 - 3;
    z_pos = label_thickness;
    
    translate([head_x, y_pos, z_pos]) {
        difference() {
            cylinder(h = text_height, d = 5);
            cylinder(h = text_height, d = 3, $fn = 6);
        }
    }
    
    translate([head_x + 6, y_pos, z_pos]) {
        intersection() {
            scale([1, 1, 0.6]) cylinder(h = text_height * 1.67, d = 5);
            translate([-5, -2.5, 0]) cube([5, 5, text_height]);
        }
    }
    
    bolt_stem(length_mm, head_x + 6, y_pos); // v105: stem butts the dome's flat bearing face
}

////////////////////////////////////////////////////////
//                TORX HEAD ICONS                    //
////////////////////////////////////////////////////////

module torx_star(size) {
    for (i = [0:5]) {
        rotate([0, 0, i * 60]) {
            translate([0, -size/2, 0]) {
                hull() {
                    circle(d = 0.3);
                    translate([0, size, 0]) circle(d = 0.3);
                }
            }
        }
    }
}

module torx_bolt_icon(length_mm, y_pos) {
    head_x = -min(length_mm, max_bolt_length)/2 - 3;
    z_pos = label_thickness;
    
    translate([head_x, y_pos, z_pos]) {
        difference() {
            cylinder(h = text_height, d = 5);
            linear_extrude(height = text_height) torx_star(2.5);
        }
    }
    
    translate([head_x + 3.5, y_pos - 2.5, z_pos]) {
        cube([4, 5, text_height]);
    }
    
    bolt_stem(length_mm, head_x + 6, y_pos);
}

module torx_countersunk_icon(length_mm, y_pos) {
    head_x = -min(length_mm, max_bolt_length)/2 - 2;
    z_pos = label_thickness;
    
    translate([head_x, y_pos, z_pos]) {
        difference() {
            cylinder(h = text_height, d = 5);
            linear_extrude(height = text_height) torx_star(2.5);
        }
    }
    
    translate([head_x + 4, y_pos, z_pos]) {
        linear_extrude(height = text_height) {
            polygon(points = [[0, -2.5], [3, 0], [0, 2.5]]);
        }
    }
    
    bolt_stem(length_mm, head_x + 5, y_pos);
}

module torx_wood_screw_icon(length_mm, y_pos) {
    head_x = -min(length_mm, max_bolt_length)/2 - 2;
    z_pos = label_thickness;
    
    translate([head_x, y_pos, z_pos]) {
        difference() {
            cylinder(h = text_height, d = 5);
            linear_extrude(height = text_height) torx_star(2.5);
        }
    }
    
    translate([head_x + 4, y_pos, z_pos]) {
        linear_extrude(height = text_height) {
            polygon(points = [[0, -2.5], [3, 0], [0, 2.5]]);
        }
    }
    
    stem_length = max(0, length_mm - 2);
    if (stem_length > 0) {
        bolt_stem(stem_length, head_x + 5, y_pos);
        
        tip_x = head_x + 5 + min(stem_length, max_bolt_length);
        translate([tip_x, y_pos, z_pos]) {
            linear_extrude(height = text_height) {
                polygon(points = [[0, -1.25], [2, 0], [0, 1.25]]);
            }
        }
    }
}

////////////////////////////////////////////////////////
//            SPECIALIZED HARDWARE                   //
////////////////////////////////////////////////////////

module wall_anchor_icon(length_mm, y_pos) {
    z_pos = label_thickness;
    start_x = -min(length_mm, max_bolt_length)/2 - 4;
    
    for (i = [0:4]) {
        translate([start_x + i * 2, y_pos, z_pos]) {
            linear_extrude(height = text_height) {
                polygon(points = [[-1, -2], [1, -1.5], [1, 1.5], [-1, 2]]);
            }
        }
    }
    
    if (length_mm > 8) {
        translate([start_x + 8, y_pos - 1.5, z_pos]) {
            cube([min(length_mm - 8, max_bolt_length - 8), 3, text_height]);
        }
    }
}

module heat_insert_icon(length_mm, y_pos) {
    z_pos = label_thickness;
    center_x = 0;
    
    translate([center_x - 2, y_pos, z_pos]) {
        difference() {
            cylinder(h = text_height, d = 4);
            cylinder(h = text_height, d = 2.5);
        }
    }
    
    for (i = [0:3]) {
        translate([center_x + 2 + i * 2, y_pos - 2, z_pos]) {
            cube([1, 4, text_height]);
        }
    }
}

////////////////////////////////////////////////////////
//              NUTS AND WASHERS                     //
////////////////////////////////////////////////////////

module standard_nut_icon(y_pos) {
    z_pos = label_thickness;
    center_x = 0;
    
    translate([center_x - 2, y_pos, z_pos]) {
        difference() {
            cylinder(h = text_height, d = 5, $fn = 6);
            cylinder(h = text_height, d = 3);
        }
    }
    
    translate([center_x + 2, y_pos - 2.5, z_pos]) {
        cube([3, 5, text_height]);
    }
}

module lock_nut_icon(y_pos) {
    z_pos = label_thickness;
    center_x = 0;
    
    translate([center_x - 2, y_pos, z_pos]) {
        difference() {
            cylinder(h = text_height, d = 5, $fn = 6);
            cylinder(h = text_height, d = 3);
        }
    }
    
    translate([center_x + 2, y_pos - 2.5, z_pos]) {
        cube([3, 5, text_height]);
    }
    translate([center_x + 2, y_pos - 2, z_pos]) {
        cube([4, 4, text_height]);
    }
}

module standard_washer_icon(y_pos) {
    z_pos = label_thickness;
    center_x = 0;
    
    translate([center_x - 1, y_pos, z_pos]) {
        difference() {
            cylinder(h = text_height, d = 5);
            cylinder(h = text_height, d = 3);
        }
    }
    
    translate([center_x + 2, y_pos - 2.5, z_pos]) {
        cube([1, 5, text_height]);
    }
}

module spring_washer_icon(y_pos) {
    z_pos = label_thickness;
    center_x = 0;
    
    translate([center_x - 1, y_pos, z_pos]) {
        difference() {
            cylinder(h = text_height, d = 5);
            cylinder(h = text_height, d = 3);
            translate([0, -0.4, 0]) cube([5, 0.8, text_height]);
        }
    }
    
    translate([center_x + 2, y_pos - 2.5, z_pos]) {
        cube([1, 5, text_height]);
    }
}
