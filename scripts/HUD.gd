extends CanvasLayer
## HUD — Heads-Up Display with stat bars, log, and minimap.

# Colors — no black / no white
const C_HP_FILL   := Color(0.878, 0.251, 0.376)
const C_HP_BG     := Color(0.337, 0.059, 0.118)
const C_MP_FILL   := Color(0.251, 0.502, 0.878)
const C_MP_BG     := Color(0.059, 0.118, 0.337)
const C_XP_FILL   := Color(0.251, 0.816, 0.376)
const C_XP_BG     := Color(0.059, 0.259, 0.118)
const C_TEXT      := Color(0.910, 0.816, 1.0)
const C_TEXT2     := Color(0.690, 0.565, 0.816)
const C_GOLD      := Color(0.941, 0.753, 0.251)
const C_PANEL_BG  := Color(0.078, 0.027, 0.145)
const C_PANEL_BOR := Color(0.439, 0.251, 0.690)
const C_LOG_DMG   := Color(0.941, 0.376, 0.439)
const C_LOG_HEAL  := Color(0.376, 0.941, 0.502)
const C_LOG_INFO  := Color(0.627, 0.502, 0.816)
const C_LOG_GOLD  := Color(0.941, 0.753, 0.251)
const C_LOG_EVENT := Color(0.376, 0.816, 0.816)
const C_LOG_SKILL := Color(0.753, 0.502, 1.0)

var _hp_bar: ProgressBar
var _mp_bar: ProgressBar
var _xp_bar: ProgressBar
var _hp_label: Label
var _mp_label: Label
var _xp_label: Label
var _level_label: Label
var _floor_label: Label
var _stats_label: Label
var _gold_label: Label
var _log_container: VBoxContainer
var _log_scroll: ScrollContainer
const MAX_LOG_LINES := 40

func _ready() -> void:
	_build_hud()
	GameState.stats_changed.connect(_on_stats_changed)
	GameState.level_up.connect(func(lv): add_log("🎉 Niveau %d! +1 point compétence!" % lv, "event"))
	GameState.floor_changed.connect(func(f): add_log("═══ Étage %d ═══" % f, "event"))

func _build_hud() -> void:
	var control := Control.new()
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(control)

	# ── LEFT PANEL: Stats ────────────────────────────────────────────
	var left := _make_panel(Vector2(0, 0), Vector2(160, 540))
	control.add_child(left)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	left.add_child(vbox)
	left.add_theme_constant_override("margin_left", 8)
	left.add_theme_constant_override("margin_right", 8)
	left.add_theme_constant_override("margin_top", 8)
	left.add_theme_constant_override("margin_bottom", 8)

	var hero_title := _make_label("⚔ HÉROS", 13, C_GOLD)
	vbox.add_child(hero_title)

	_level_label = _make_label("Niveau 1", 11, C_TEXT2)
	vbox.add_child(_level_label)
	_floor_label = _make_label("Étage 1", 11, C_TEXT2)
	vbox.add_child(_floor_label)

	vbox.add_child(_make_separator())

	_hp_bar = _make_bar(C_HP_FILL, C_HP_BG)
	vbox.add_child(_make_bar_row("HP", _hp_bar, func(): return _hp_label))
	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", 9)
	_hp_label.add_theme_color_override("font_color", C_TEXT2)

	_mp_bar = _make_bar(C_MP_FILL, C_MP_BG)
	vbox.add_child(_make_bar_row("MP", _mp_bar, func(): return _mp_label))
	_mp_label = Label.new()
	_mp_label.add_theme_font_size_override("font_size", 9)
	_mp_label.add_theme_color_override("font_color", C_TEXT2)

	_xp_bar = _make_bar(C_XP_FILL, C_XP_BG)
	vbox.add_child(_make_bar_row("XP", _xp_bar, func(): return _xp_label))
	_xp_label = Label.new()

	vbox.add_child(_make_separator())

	_stats_label = _make_label("ATQ: 5  DEF: 2", 10, C_TEXT)
	vbox.add_child(_stats_label)
	_gold_label = _make_label("Or: 0", 10, C_GOLD)
	vbox.add_child(_gold_label)

	vbox.add_child(_make_separator())

	var log_title := _make_label("📜 JOURNAL", 11, C_GOLD)
	vbox.add_child(log_title)

	_log_scroll = ScrollContainer.new()
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(_log_scroll)

	_log_container = VBoxContainer.new()
	_log_container.add_theme_constant_override("separation", 1)
	_log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_scroll.add_child(_log_container)

	var hint := _make_label("ZQSD/Flèches: bouger\nK: compétences", 9, C_TEXT2)
	vbox.add_child(hint)

	_on_stats_changed()

# ──────────────────────────────────────────────
#  API
# ──────────────────────────────────────────────
func add_log(msg: String, css_class: String = "info") -> void:
	var lbl := Label.new()
	lbl.text = msg
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_font_size_override("font_size", 9)
	var col := {
		"dmg": C_LOG_DMG, "heal": C_LOG_HEAL, "info": C_LOG_INFO,
		"gold": C_LOG_GOLD, "event": C_LOG_EVENT, "skill": C_LOG_SKILL,
		"miss": Color(0.627, 0.502, 0.753)
	}.get(css_class, C_LOG_INFO)
	lbl.add_theme_color_override("font_color", col)
	_log_container.add_child(lbl)
	while _log_container.get_child_count() > MAX_LOG_LINES:
		_log_container.get_child(0).queue_free()
	await get_tree().process_frame
	_log_scroll.scroll_vertical = 999999

# ──────────────────────────────────────────────
#  HELPERS
# ──────────────────────────────────────────────
func _on_stats_changed() -> void:
	_hp_bar.max_value = GameState.max_hp
	_hp_bar.value = GameState.hp
	_mp_bar.max_value = GameState.max_mp
	_mp_bar.value = GameState.mp
	_xp_bar.max_value = GameState.xp_next
	_xp_bar.value = GameState.xp
	_level_label.text = "Niveau %d" % GameState.level
	_floor_label.text = "Étage %d" % GameState.floor
	_stats_label.text = "ATQ: %d  DEF: %d\nPTS: %d" % [GameState.atk, GameState.def, GameState.skill_points]
	_gold_label.text = "Or: %d" % GameState.gold

func _make_panel(pos: Vector2, size: Vector2) -> MarginContainer:
	var mc := MarginContainer.new()
	mc.position = pos
	mc.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(C_PANEL_BG, 0.88)
	style.border_color = C_PANEL_BOR
	style.set_border_width_all(1)
	mc.add_theme_stylebox_override("panel", style)
	return mc

func _make_label(text: String, size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func _make_separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", C_PANEL_BOR)
	return sep

func _make_bar(fill: Color, bg: Color) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.custom_minimum_size = Vector2(0, 8)
	pb.show_percentage = false
	var style_bg := StyleBoxFlat.new()
	style_bg.bg_color = bg
	style_bg.set_corner_radius_all(2)
	var style_fill := StyleBoxFlat.new()
	style_fill.bg_color = fill
	style_fill.set_corner_radius_all(2)
	pb.add_theme_stylebox_override("background", style_bg)
	pb.add_theme_stylebox_override("fill", style_fill)
	return pb

func _make_bar_row(label_text: String, bar: ProgressBar, _lbl_getter: Callable) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	var lbl := _make_label(label_text, 9, C_TEXT2)
	lbl.custom_minimum_size.x = 20
	hb.add_child(lbl)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(bar)
	return hb
