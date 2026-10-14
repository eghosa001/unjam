extends RefCounted

# Native-sized game onboarding copy. A fallback is intentional if a locale is
# missing any key, and native-language review remains a release gate.
const KEYS := ["rescue_intro","rescue_1","rescue_2","rescue_3","water_intro","water_1","water_2","water_3","block_intro","block_1","block_2","block_3","practice_rescue","practice_water","practice_block","practice_success","practice_blocked","practice_selected","practice_colour_mismatch","practice_water_start","practice_block_hold","practice_block_first","practice_block_missed"]
const COPY := {
    "en": ["Free the chick by opening a route to the edge.","Tap an arrow only when its path to the edge is clear.","Clear a blocker first. Wrong taps can cost a life.","Watch special arrows and gates. Free the rescue lane.","Sort the liquids so each full tube has one colour.","Tap a source tube, then a matching or empty tube.","Pour onto the same colour, or into an empty tube.","Keep an empty tube free. UNDO or HINT can help.","Place shapes, clear rows or columns, and save space.","Touch and hold a shape to lift it above the board.","Drag to valid cells and release to place the shape.","Plan all three pieces. Keep long rows available.","Try: tap the free right-facing arrow.","Try: tap PINK, then matching PINK.","Try: drag blue blocks to the outline.","NICE MOVE! You're ready to play.","Blocked! Find a clear path to the edge.","Pink selected. Now tap the matching tube.","Different colours cannot stack. Try pink.","Tap the left pink tube first.","Keep holding. Drag onto the outline.","Hold the blue piece first.","Almost! Release inside the outline."],
    # ADD_SUPPORTED_LANGUAGES
}

static func tr(key: String) -> String:
    var idx := KEYS.find(key)
    if idx < 0: return key
    var tree := Engine.get_main_loop() as SceneTree
    var manager := tree.root.get_node_or_null("LocalizationManager") if tree != null else null
    var locale := String(manager.get("language_code")) if manager != null else "en"
    var fallback: Array = COPY["en"]
    var values: Array = COPY.get(locale,fallback)
    return String(values[idx]) if values.size() == KEYS.size() else String(fallback[idx])
