extends CanvasLayer
## CombatScreen — overlay UI for turn-based combat.

signal combat_finished(player_won: bool)

const C_BG       := Color(0.067, 0.020, 0.133, 0.92)
const C_PANEL    := Color(0.094, 0.027, 0.173)
const C_BORDER   := Color(0.439, 0.251, 0.690)
const C_GOLD     := Color(0.941, 0.753, 0.251)
const C_TEXT     := Color(0.910, 0.816, 1.0)
const C_TEXT2    := Color(0.690, 0.565, 0.816)
const C_HP_FILL  := Color(0.878, 0.251, 0.376)
const C_HP_BG    := Color(0.337, 0.059, 0.118)
const C_BTN_BG   := Color(0.196, 0.071, 0.337)
const C_BTN_HOV  := Color(0.314, 0.118, 0.502)
const C_BTN_DIS  := Color(0.157, 0.078, 0.251)

var _combat: CombatSystem
var _enemy_hp_bar: ProgressBar
var _enemy_name_lbl: Label
var _enemy_sprite_lbl: Label
var _log_lbl: Label
var _btns: Dictionary = {}
var _hud_ref: Node

func _ready() -> void:
	layer = 50
	visible = false
	_combat = CombatSystem.new()
	add_child(_combat)
	_combat.combat_log.connect(_on_combat_log)
	_combat.combat_ended.connect(_on_combat_ended)
	_combat.enemy_hp_changed.connect(_on_enemy_hp_changed)
	_build_ui()

func start(enemy_data: Dictionary, hud: Node) -> void:
	_hud_ref = hud
	_combat.start_combat(enemy_data)
	_enemy_name_lbl.text = enemy_data.get("name", "Ennemi")
	_enemy_sprite_lbl.text = enemy_data.get("emoji", "👾")
	_enemy_hp_bar.max_value = enemy_data.get("max_hp", 1)
	_enemy_hp_bar.value = enemy_data.get("hp", 1)
	_log_lbl.text = ""
	visible = true
	_update_buttons()

func _build_ui() -> void:
	var ctrl := Control.new()
	ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ctrl)

	# Dark overlay
	var overlay := ColorRect.new()
	overlay.color = C_BG
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ctrl.add_child(overlay)

	# Center panel
	var panel_mc := MarginContainer.new()
	panel_mc.set_anchors_preset(Control.PRESET_CENTER)
	panel_mc.custom_minimum_size = Vector2(280, 340)
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = C_PANEL
	pstyle.border_color = C_BORDER
	pstyle.set_border_width_all(2)
	pstyle.set_corner_radius_all(6)
	pstyle.set_content_margin_all(16)
	panel_mc.add_theme_stylebox_override("panel", pstyle)
	ctrl.add_child(panel_mc)
	# Center it
	panel_mc.position = Vector2(960/2 - 140, 540/2 - 170)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel_mc.add_child(vbox)

	# Enemy name
	_enemy_name_lbl = Label.new()
	_enemy_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_name_lbl.add_theme_font_size_override("font_size", 16)
	_enemy_name_lbl.add_theme_color_override("font_color", C_GOLD)
	vbox.add_child(_enemy_name_lbl)

	# Enemy sprite
	_enemy_sprite_lbl = Label.new()
	_enemy_sprite_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_sprite_lbl.add_theme_font_size_override("font_size", 40)
	vbox.add_child(_enemy_sprite_lbl)

	# Enemy HP bar
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 6)
	var hp_lbl := Label.new(); hp_lbl.text = "HP"; hp_lbl.add_theme_font_size_override("font_size", 11)
	hp_lbl.add_theme_color_override("font_color", C_TEXT2)
	hp_row.add_child(hp_lbl)
	_enemy_hp_bar = ProgressBar.new()
	_enemy_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enemy_hp_bar.custom_minimum_size.y = 10
	_enemy_hp_bar.show_percentage = false
	var bgstyle := StyleBoxFlat.new(); bgstyle.bg_color = C_HP_BG; bgstyle.set_corner_radius_all(3)
	var fstyle  := StyleBoxFlat.new(); fstyle.bg_color  = C_HP_FILL; fstyle.set_corner_radius_all(3)
	_enemy_hp_bar.add_theme_stylebox_override("background", bgstyle)
	_enemy_hp_bar.add_theme_stylebox_override("fill", fstyle)
	hp_row.add_child(_enemy_hp_bar)
	vbox.add_child(hp_row)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", C_BORDER)
	vbox.add_child(sep)

	# Combat log line
	_log_lbl = Label.new()
	_log_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_log_lbl.add_theme_font_size_override("font_size", 11)
	_log_lbl.add_theme_color_override("font_color", C_TEXT2)
	_log_lbl.custom_minimum_size.y = 20
	vbox.add_child(_log_lbl)

	# Action buttons
	var btn_data := [
		{"id": "attack",  "label": "⚔ Attaquer",     "always": true},
		{"id": "heavy",   "label": "💢 Frappe Lourde", "always": false},
		{"id": "spell",   "label": "✨ Sort",           "always": false},
		{"id": "shield",  "label": "🛡 Bouclier",      "always": false},
		{"id": "flee",    "label": "🏃 Fuir",           "always": true},
	]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(grid)

	for bd in btn_data:
		var btn := Button.new()
		btn.text = bd["label"]
		btn.add_theme_font_size_override("font_size", 11)
		btn.custom_minimum_size = Vector2(110, 32)
		var ns := StyleBoxFlat.new(); ns.bg_color = C_BTN_BG; ns.border_color = C_BORDER
		ns.set_border_width_all(1); ns.set_corner_radius_all(3); ns.set_content_margin_all(4)
		var hs := StyleBoxFlat.new(); hs.bg_color = C_BTN_HOV; hs.border_color = C_GOLD
		hs.set_border_width_all(1); hs.set_corner_radius_all(3); hs.set_content_margin_all(4)
		var ds := StyleBoxFlat.new(); ds.bg_color = C_BTN_DIS; ds.border_color = C_BTN_DIS
		ds.set_border_width_all(1); ds.set_corner_radius_all(3); ds.set_content_margin_all(4)
		btn.add_theme_stylebox_override("normal", ns)
		btn.add_theme_stylebox_override("hover", hs)
		btn.add_theme_stylebox_override("disabled", ds)
		btn.add_theme_color_override("font_color", C_TEXT)
		btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.3, 0.5))
		var bid := bd["id"]
		btn.pressed.connect(func(): _on_action(bid))
		_btns[bd["id"]] = btn
		grid.add_child(btn)

func _on_action(action: String) -> void:
	if not _combat.can_act(): return
	match action:
		"attack": _combat.action_attack()
		"heavy":  _combat.action_heavy()
		"spell":  _combat.action_spell()
		"shield": _combat.action_shield()
		"flee":   _combat.action_flee()
	_update_buttons()

func _update_buttons() -> void:
	_btns["heavy"].disabled  = not GameState.heavy_unlocked
	_btns["spell"].disabled  = not GameState.spell_unlocked or GameState.mp < 3
	_btns["shield"].disabled = not GameState.shield_unlocked

func _on_combat_log(msg: String, css_class: String) -> void:
	_log_lbl.text = msg
	if _hud_ref:
		_hud_ref.add_log(msg, css_class)

func _on_enemy_hp_changed(hp: int, max_hp: int) -> void:
	_enemy_hp_bar.max_value = max_hp
	_enemy_hp_bar.value = hp

func _on_combat_ended(player_won: bool) -> void:
	await get_tree().create_timer(0.5).timeout
	visible = false
	emit_signal("combat_finished", player_won)
