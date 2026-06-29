extends PanelContainer
## SkillTreePanel — displays and handles the skill tree UI.

const NODE_SIZE := Vector2(60, 60)
const NODE_GAP := Vector2(10, 14)
const ROWS := 3

# Colors — no black / no white
const C_LOCKED    := Color(0.196, 0.071, 0.337)
const C_AVAILABLE := Color(0.314, 0.118, 0.502)
const C_UNLOCKED  := Color(0.502, 0.251, 0.816)
const C_MAXED     := Color(0.376, 0.157, 0.627)
const C_BORDER_LOCK  := Color(0.314, 0.157, 0.502)
const C_BORDER_AVAIL := Color(0.565, 0.314, 0.816)
const C_BORDER_GOLD  := Color(0.941, 0.753, 0.251)
const C_TEXT_DIM  := Color(0.690, 0.565, 0.816)
const C_TEXT_GOLD := Color(0.941, 0.753, 0.251)
const C_XP_GREEN  := Color(0.251, 0.816, 0.376)
const C_CONNECTOR := Color(0.502, 0.314, 0.690)

var _buttons: Dictionary = {}  # skill_id -> Button
var _tooltip_panel: PanelContainer
var _tooltip_name: Label
var _tooltip_desc: Label
var _tooltip_cost: Label
var _points_label: Label

func _ready() -> void:
	_build_ui()
	GameState.stats_changed.connect(_refresh)
	GameState.skill_unlocked.connect(func(_id): _refresh())

func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)

	# Title bar
	var title := Label.new()
	title.text = "✦ COMPÉTENCES ✦"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", C_TEXT_GOLD)
	title.add_theme_font_size_override("font_size", 13)
	vbox.add_child(title)

	# Skill points display
	_points_label = Label.new()
	_points_label.text = "Points disponibles: 0"
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_points_label.add_theme_color_override("font_color", C_XP_GREEN)
	_points_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_points_label)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Group skills by row
	var rows_map: Dictionary = {}
	for sdef in GameState.SKILL_DEFS:
		var r: int = sdef["row"]
		if not rows_map.has(r):
			rows_map[r] = []
		rows_map[r].append(sdef)

	for row_idx in range(ROWS):
		if not rows_map.has(row_idx): continue
		var row_label := Label.new()
		row_label.text = ["— Fondation —", "— Intermédiaire —", "— Avancé —"][row_idx]
		row_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row_label.add_theme_color_override("font_color", Color(0.565, 0.376, 0.753))
		row_label.add_theme_font_size_override("font_size", 9)
		vbox.add_child(row_label)

		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 6)
		vbox.add_child(hbox)

		for sdef in rows_map[row_idx]:
			var node := _make_skill_node(sdef)
			hbox.add_child(node)
			_buttons[sdef["id"]] = node

	# Tooltip (hidden by default)
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.visible = false
	_tooltip_panel.z_index = 100
	var tstyle := StyleBoxFlat.new()
	tstyle.bg_color = Color(0.094, 0.027, 0.173)
	tstyle.border_color = C_TEXT_GOLD
	tstyle.set_border_width_all(1)
	tstyle.set_corner_radius_all(4)
	tstyle.set_content_margin_all(8)
	_tooltip_panel.add_theme_stylebox_override("panel", tstyle)
	var tvbox := VBoxContainer.new()
	_tooltip_panel.add_child(tvbox)
	_tooltip_name = Label.new()
	_tooltip_name.add_theme_font_size_override("font_size", 12)
	_tooltip_name.add_theme_color_override("font_color", C_TEXT_GOLD)
	tvbox.add_child(_tooltip_name)
	_tooltip_desc = Label.new()
	_tooltip_desc.add_theme_font_size_override("font_size", 10)
	_tooltip_desc.add_theme_color_override("font_color", C_TEXT_DIM)
	_tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	_tooltip_desc.custom_minimum_size.x = 160
	tvbox.add_child(_tooltip_desc)
	_tooltip_cost = Label.new()
	_tooltip_cost.add_theme_font_size_override("font_size", 10)
	_tooltip_cost.add_theme_color_override("font_color", C_XP_GREEN)
	tvbox.add_child(_tooltip_cost)
	get_tree().root.call_deferred("add_child", _tooltip_panel)

func _make_skill_node(sdef: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(58, 58)
	btn.text = sdef["icon"] + "\n" + sdef["name"]
	btn.add_theme_font_size_override("font_size", 9)

	var style_normal := StyleBoxFlat.new()
	style_normal.set_corner_radius_all(4)
	style_normal.set_content_margin_all(4)
	btn.add_theme_stylebox_override("normal", style_normal)

	btn.pressed.connect(func(): _on_skill_pressed(sdef["id"]))
	btn.mouse_entered.connect(func(): _show_tooltip(sdef))
	btn.mouse_exited.connect(func(): _hide_tooltip())
	btn.set_meta("skill_id", sdef["id"])
	btn.set_meta("style_normal", style_normal)
	return btn

func _refresh() -> void:
	_points_label.text = "Points disponibles: %d" % GameState.skill_points

	for sid in _buttons:
		var btn: Button = _buttons[sid]
		var lv: int = GameState.skills.get(sid, 0)
		var sdef: Dictionary = {}
		for s in GameState.SKILL_DEFS:
			if s["id"] == sid: sdef = s; break
		if sdef.is_empty(): continue

		var req_met := sdef["requires"].all(func(r): return GameState.skills.get(r, 0) >= 1)
		var maxed := lv >= sdef["max_lv"]
		var can_up := req_met and not maxed and GameState.skill_points >= sdef["cost"]

		var style: StyleBoxFlat = btn.get_meta("style_normal")
		if maxed:
			style.bg_color = C_MAXED
			style.border_color = C_BORDER_GOLD
			style.set_border_width_all(2)
			btn.modulate = Color(1.0, 0.941, 0.502)
		elif lv > 0:
			style.bg_color = C_UNLOCKED
			style.border_color = C_BORDER_GOLD
			style.set_border_width_all(1)
			btn.modulate = Color.WHITE
		elif can_up:
			style.bg_color = C_AVAILABLE
			style.border_color = C_BORDER_AVAIL
			style.set_border_width_all(1)
			btn.modulate = Color.WHITE
		else:
			style.bg_color = C_LOCKED
			style.border_color = C_BORDER_LOCK
			style.set_border_width_all(1)
			btn.modulate = Color(0.6, 0.5, 0.7)

		# Level dots suffix
		var dots := "●".repeat(lv) + "○".repeat(sdef["max_lv"] - lv)
		btn.text = "%s\n%s\n%s" % [sdef["icon"], sdef["name"], dots]
		btn.disabled = not can_up and lv == 0 and not req_met

func _on_skill_pressed(skill_id: String) -> void:
	if GameState.upgrade_skill(skill_id):
		AudioManager.play_skill_unlock()
		_refresh()

func _show_tooltip(sdef: Dictionary) -> void:
	var lv := GameState.skills.get(sdef["id"], 0)
	_tooltip_name.text = "%s %s [%d/%d]" % [sdef["icon"], sdef["name"], lv, sdef["max_lv"]]
	_tooltip_desc.text = sdef["desc"]
	var req_text := ""
	if not sdef["requires"].is_empty():
		var names := []
		for r in sdef["requires"]:
			for s in GameState.SKILL_DEFS:
				if s["id"] == r: names.append(s["name"])
		req_text = "\nRequiert: " + ", ".join(names)
	_tooltip_cost.text = "Coût: %d pt(s)%s" % [sdef["cost"], req_text]
	_tooltip_panel.visible = true

func _hide_tooltip() -> void:
	_tooltip_panel.visible = false

func _process(_delta: float) -> void:
	if _tooltip_panel and _tooltip_panel.visible:
		var mp := get_viewport().get_mouse_position()
		_tooltip_panel.position = mp + Vector2(12, 12)
