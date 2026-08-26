////////////////////////////////////////////////////////
//        Parts Bin Label Generator - IMPERIAL        //
//         Fractional & Machine Screw Support         //
//                    Version 113                     //
////////////////////////////////////////////////////////

/* [Single Label Mode] */
hardware_type = "Button head bolt"; // [Phillips head bolt, Socket head bolt, Hex head bolt, Flange hex bolt, Button head bolt, Torx head bolt, Robertson pan head, Robertson flat head, Carriage bolt, Phillips head countersunk, Torx head countersunk, Socket head countersunk, Phillips wood screw, Torx wood screw, Wall anchor, Heat set insert, Standard nut, Lock nut, Flange nut, Standard washer, Spring washer, Custom text, None]
thread_spec = "1/4-20"; // [1/4-20, 5/16-18, 3/8-16, 7/16-14, 1/2-13, 9/16-12, 5/8-11, 3/4-10, 7/8-9, 1-8, #4-40, #5-40, #6-32, #8-32, #10-24, #12-24]
length_inches = 0.75; // Length in inches
custom_display_text = ""; // Custom text override (leave blank for auto-generation)
custom_text_only = "Custom"; // Used only when hardware_type is "Custom text"

/* [Multi-Label Mode] */
enable_multi_label = false;
multi_label_spec = "socket: 1/4-20x1/2, 1/4-20x3/4, 1/4-20x1, #8-32x1/2, #8-32x3/4; nut: 1/4-20, #8-32, #10-24; washer: 1/4-20, #8-32, #10-24"; // Batch spec: "type: item, item; type: item" - grammar in MULTI-LABEL SPEC PARSER section

/* [Label Properties] */
label_units = 1; // [1:Small (35.8mm), 2:Medium (77.8mm), 3:Large (119.8mm)]
base_color = "#FFFFFF"; // Base label color
content_color = "#000000"; // Text and icon color
export_mode = "Complete"; // [Complete, Base only, Content only]
enable_side_tabs = true; // Side tabs that clip into Gridfinity Extended label slots
tab_depth = 1.0; // How far each tab extends past the label end (mm)
tab_width = 6.0; // Tab width (mm)

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

// Global curve resolution (v112). Without these, OpenSCAD's defaults
// ($fa=12, $fs=2) render every icon-scale circle at 5-8 segments:
// d=5 heads/washers came out as octagons, d<=3 bores as pentagons.
// Adaptive $fa/$fs scales fragment count to feature size (d=5 -> 60
// segments, d=3 -> ~38, label corners ~23). Explicit $fn arguments
// (the intentional $fn=6 hexes) always override these globals.
$fa = 6;
$fs = 0.25;

// Internal calculations
// v113: vertical centering of the content block. The icon row
// (icon_y_pos = label_width/4, head d=5) left only 0.375mm of ink
// clearance at the top edge while the text baseline sat 1.5mm above
// the bottom - the whole block read visibly high (4:1 margin skew).
// Shifting icon row AND text down together by (1.5 - 0.375)/2 =
// 0.5625mm equalizes the ink margins (~0.9mm each, STL-verified)
// while leaving the icon-text gap and all x-geometry untouched.
content_v_shift = -(1.5 - 0.375) / 2; // -0.5625; expression form keeps it out of the customizer UI

label_length = (label_units == 1) ? 35.8 : (label_units == 2) ? 77.8 : 119.8;
text_height = (text_mode == "Raised") ? raised_height : flush_height;
font_string = str(font_family, ":style=", font_weight);
max_bolt_length = 20 * label_units;
length_mm = length_inches * 25.4; // Convert to mm for internal calculations

////////////////////////////////////////////////////////
//         IMPERIAL SYSTEM FUNCTIONS                 //
////////////////////////////////////////////////////////

function imperial_to_mm(inches) = inches * 25.4;

function generate_imperial_display_text(thread, length_inches) =
    (length_inches == 0.125) ? str(thread, " x 1/8\"") :
    (length_inches == 0.1875) ? str(thread, " x 3/16\"") :
    (length_inches == 0.25) ? str(thread, " x 1/4\"") :
    (length_inches == 0.3125) ? str(thread, " x 5/16\"") :
    (length_inches == 0.375) ? str(thread, " x 3/8\"") :
    (length_inches == 0.4375) ? str(thread, " x 7/16\"") :
    (length_inches == 0.5) ? str(thread, " x 1/2\"") :
    (length_inches == 0.5625) ? str(thread, " x 9/16\"") :
    (length_inches == 0.625) ? str(thread, " x 5/8\"") :
    (length_inches == 0.6875) ? str(thread, " x 11/16\"") :
    (length_inches == 0.75) ? str(thread, " x 3/4\"") :
    (length_inches == 0.8125) ? str(thread, " x 13/16\"") :
    (length_inches == 0.875) ? str(thread, " x 7/8\"") :
    (length_inches == 0.9375) ? str(thread, " x 15/16\"") :
    (length_inches == 1.0) ? str(thread, " x 1\"") :
    (length_inches == 1.25) ? str(thread, " x 1-1/4\"") :
    (length_inches == 1.5) ? str(thread, " x 1-1/2\"") :
    (length_inches == 1.75) ? str(thread, " x 1-3/4\"") :
    (length_inches == 2.0) ? str(thread, " x 2\"") :
    str(thread, " x ", length_inches, "\""); // Default for custom lengths

function is_nut_or_washer_type(type) =
    type == "Standard nut" || 
    type == "Lock nut" || 
    type == "Flange nut" || 
    type == "Standard washer" || 
    type == "Spring washer";

////////////////////////////////////////////////////////
//    IMPERIAL MULTI-LABEL SPEC PARSER (v106)       //
////////////////////////////////////////////////////////
// Structured batch grammar for multi_label_spec (paste-able, no
// code editing). Groups separated by ";", each group:
//     <type>: <item>, <item>, ...
// Items:
//   bolts/screws:  <thread>x<length-inches>   e.g.  1/4-20x1/2,
//                  #8-32x3/4, 1/4-20x1-1/4 (fractions & mixed numbers)
//   nuts/washers:  <thread>                   e.g.  1/4-20, #8-32
//   custom text:   literal label text         e.g.  text: Front, Back
// Type keys (case-insensitive; full customizer type names also work):
//   phillips, socket, hex, flange, button, torx, robertson, rpan,
//   rflat, carriage, phillips-csk, torx-csk, socket-csk, phillips-wood,
//   torx-wood, anchor, insert, nut, locknut, flangenut, washer,
//   springwasher, text
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
    ["flange", "Flange hex bolt"],
    ["flangebolt", "Flange hex bolt"],
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
    ["flangenut", "Flange nut"],
    ["washer", "Standard washer"],
    ["springwasher", "Spring washer"],
    ["text", "Custom text"]
];
function _type_name(k) =
    let(hits = [for (t = _TYPE_KEYS) if (t[0] == k || _lc(t[1]) == k) t[1]])
    len(hits) > 0 ? hits[0] : undef;

// --- imperial unit layer: thread + length parsing ---
// Thread: fractional or machine-screw spec as typed: "1/4-20", "#8-32", "1-8"
function _norm_thread(raw) =
    let(t = _trim(raw))
    t == "" ? undef :
    (t[0] == "#" || (ord(t[0]) >= 48 && ord(t[0]) <= 57)) ? t : undef;
// Length: inches - "1/2", "3/4", "1", "1-1/4", "0.75" -> mm value
function _frac_in(s) =
    let(sl = _idx(s, "/"))
    sl < 0 ? _num(s) :
    let(n = _num(_substr(s, 0, sl)), d = _num(_substr(s, sl + 1, len(s))))
    (n == undef || d == undef || d == 0) ? undef : n / d;
function _inches(s) =
    let(dash = _idx(s, "-"), slash = _idx(s, "/"))
    (dash > 0 && slash > dash) ?
        let(w = _num(_substr(s, 0, dash)), f = _frac_in(_substr(s, dash + 1, len(s))))
        ((w == undef || f == undef) ? undef : w + f) :
    _frac_in(s);
function _parse_len_mm(s) = let(v = _inches(s)) v == undef ? undef : v * 25.4;
function _display_text_for(th, lstr) = str(th, " x ", lstr, "\"");

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
        generate_imperial_display_text(thread_spec, length_inches);
    
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
    // Main label body with rounded corners (no mounting holes - the
    // v104 regeneration added them; removed in v109 to match the
    // pre-v99 baseline and Gridfinity Extended slot use)
    hull() {
        for (x = [-label_length/2 + corner_radius, label_length/2 - corner_radius]) {
            for (y = [-label_width/2 + corner_radius, label_width/2 - corner_radius]) {
                translate([x, y, 0]) {
                    cylinder(h = label_thickness, r = corner_radius);
                }
            }
        }
    }

    // Side tabs (v99 baseline geometry, restored in v109) - clip into
    // Gridfinity Extended label slots; centered on each end
    if (enable_side_tabs) {
        // Each tab overlaps 1mm INTO the body so the union is robust:
        // a zero-overlap coincident face can land a floating-point
        // epsilon short of the body edge and export as a disconnected
        // shell (the left tab did exactly that in v109/v110 - it
        // printed as a loose sliver). Outer extents are unchanged.
        tab_overlap = 1;
        translate([-label_length/2 - tab_depth, -tab_width/2, 0]) {
            cube([tab_depth + tab_overlap, tab_width, label_thickness]);
        }
        translate([label_length/2 - tab_overlap, -tab_width/2, 0]) {
            cube([tab_depth + tab_overlap, tab_width, label_thickness]);
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
        final_text = (display_text != "") ? display_text : str(thread, " x ", length_inches, "\"");
        render_text(final_text);
    }
}

////////////////////////////////////////////////////////
//         TEXT RENDERING (auto-fit since v108)      //
////////////////////////////////////////////////////////
// Renderer font substitution (e.g. MakerWorld) changes both glyph
// widths and vertical metrics, so:
// - Vertical: valign="baseline" with the baseline pinned 1.5mm above
//   the label's bottom edge - placement no longer depends on any
//   font's ascent/descent metrics.
// - Horizontal: estimated width from a per-character advance table
//   calibrated ~10% above DejaVu Sans Bold (the widest common
//   fallback class; OpenSCAD 2021.01 has no textmetrics()). If the
//   estimate exceeds the safe width (label_length - 8, clear of
//   the label ends), the text is condensed in x down to 80%, then
//   shrunk proportionally if still too wide. Short strings render
//   exactly as before.

// Per-character advance as a fraction of text_size (bold sans,
// conservative). Unknown characters assume 1.10.
function _adv(c) =
    let(o = ord(c))
    (o >= 48 && o <= 57) ? 0.95 :
    c == " " ? 0.70 :
    c == "." ? 0.55 :
    c == "-" ? 0.60 :
    c == "/" ? 0.55 :
    c == "#" ? 1.15 :
    c == "\"" ? 0.70 :
    c == "(" || c == ")" ? 0.60 :
    c == "I" || c == "i" || c == "l" || c == "j" || c == "!" ? 0.55 :
    c == "M" || c == "m" ? 1.45 :
    c == "W" || c == "w" ? 1.50 :
    (o >= 65 && o <= 90) ? 1.10 :
    (o >= 97 && o <= 122) ? 1.00 :
    1.10;
function _sumadv(s, i = 0) = i >= len(s) ? 0 : _adv(s[i]) + _sumadv(s, i + 1);

module render_text(text_content) {
    est_w = _sumadv(text_content) * text_size;
    avail = label_length - 8;
    squeeze = (len(text_content) == 0 || est_w <= avail) ? 1 : avail / est_w;
    x_condense = max(squeeze, 0.8);
    size_factor = (squeeze >= 0.8) ? 1 : squeeze / 0.8;
    if (squeeze < 1)
        echo(str("TEXT-FIT: '", text_content, "' condensed to ",
                 round(x_condense * 100), "%",
                 size_factor < 1 ? str(", size scaled to ", round(size_factor * 100), "%") : ""));
    translate([0, -label_width/2 + 1.5 + content_v_shift, label_thickness]) {
        linear_extrude(height = text_height) {
            scale([x_condense, 1]) {
                text(text_content, 
                     size = text_size * size_factor,
                     font = font_string,
                     halign = "center",
                     valign = "baseline");
            }
        }
    }
}

////////////////////////////////////////////////////////
//               HARDWARE ICONS                      //
////////////////////////////////////////////////////////

module render_hardware_icon(type, length_mm) {
    icon_y_pos = label_width/4 + content_v_shift; // v113: see content_v_shift
    
    if (type == "Phillips head bolt") {
        phillips_bolt_icon(length_mm, icon_y_pos);
    } else if (type == "Socket head bolt") {
        socket_bolt_icon(length_mm, icon_y_pos);
    } else if (type == "Hex head bolt") {
        hex_bolt_icon(length_mm, icon_y_pos);
    } else if (type == "Flange hex bolt") {
        flange_hex_bolt_icon(length_mm, icon_y_pos);
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
    } else if (type == "Flange nut") {
        flange_nut_icon(icon_y_pos);
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
//             FLANGE HEX BOLT ICON                   //
////////////////////////////////////////////////////////

module flange_hex_bolt_icon(length_mm, y_pos) {
    head_x = -min(length_mm, max_bolt_length)/2 - 3;
    z_pos = label_thickness;

    // Top view - round flange with a hex outline ring cut into it
    translate([head_x, y_pos, z_pos]) {
        difference() {
            cylinder(h = text_height, d = 5);
            difference() {
                cylinder(h = text_height, d = 3.6, $fn = 6);
                cylinder(h = text_height, d = 2.8, $fn = 6);
            }
        }
    }

    // Side view - hex body over a wider flange plate at the stem side
    translate([head_x + 3.5, y_pos - 2, z_pos]) {
        cube([2.5, 4, text_height]);
    }
    translate([head_x + 6, y_pos - 2.5, z_pos]) {
        cube([1, 5, text_height]);
    }

    // Stem butts the flange plate (half-height 2.5mm > 1.25mm: no notch)
    bolt_stem(length_mm, head_x + 7, y_pos);
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

module flange_nut_icon(y_pos) {
    z_pos = label_thickness;
    center_x = 0;

    translate([center_x - 2, y_pos, z_pos]) {
        difference() {
            cylinder(h = text_height, d = 5, $fn = 6);
            cylinder(h = text_height, d = 3);
        }
    }

    // Side view - nut body over a wider flange plate
    translate([center_x + 2, y_pos - 2, z_pos]) {
        cube([2.5, 4, text_height]);
    }
    translate([center_x + 4.5, y_pos - 2.5, z_pos]) {
        cube([1, 5, text_height]);
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
