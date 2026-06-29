extends Node
## Main — root scene orchestrator.

const TILE_SIZE: int = 16

# Scene offsets for the dungeon viewport
const DUNGEON_OFFSET := Vector2(160, 0)
const DUNGEON_SCALE  := Vector2(4.0, 4.0)  # pixel-perfect ×4 scale

var _dungeon_node: Node2D
var _player_node: Node2D
var _camera: Camera2D
var _hud: Node
var _combat_screen: Node
var _skill_panel: Control
var _game_over_screen: Control

var _in_combat: bool = false
var _skill_panel_open: bool = false

func _ready() -> void:
	_setup_world()
	_setup_hud()
	_setup_combat()
	_setup_skill_panel()
	_setup_game_over()
	_connect_signals()
	_start_floor()

# ──────────────────────────────────────────────
#  SETUP
# ──────────────────────────────────────────────
func _setup_world() -> void:
	var sub := SubViewportContainer.new()
	sub.stretch = true
	sub.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sub)

	var viewport := SubViewport.new()
	viewport.size = Vector2i(960, 540)
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	sub.add_child(viewport)

	# Dungeon Node2D (rendered at 1:1 then scaled by camera)
	_dungeon_node = Node2D.new()
	_dungeon_node.set_script(load("res://scripts/Dungeon.gd"))
	viewport.add_child(_dungeon_node)

	# Camera for smooth follow + scale
	_camera = Camera2D.new()
	_camera.zoom = DUNGEON_SCALE
	viewport.add_child(_camera)

	# Player
	_player_node = Node2D.new()
	_player_node.set_script(load("res://scripts/Player.gd"))
	viewport.add_child(_player_node)
	_player_node.moved.connect(_on_player_moved)
	_player_node.interact.connect(_on_player_interact)

func _setup_hud() -> void:
	_hud = load("res://scripts/HUD.gd").new()
	add_child(_hud)

func _setup_combat() -> void:
	_combat_screen = load("res://scripts/CombatScreen.gd").new()
	add_child(_combat_screen)
	_combat_screen.combat_finished.connect(_on_combat_finished)

func _setup_skill_panel() -> void:
	# Right-side skill tree panel
	_skill_panel = PanelContainer.new()
	_skill_panel.set_script(load("res://scripts/SkillTreePanel.gd"))
	_skill_panel.visible = false
	_skill_panel.size = Vector2(220, 540)
	_skill_panel.position = Vector2(960 - 220, 0)
	_skill_panel.z_index = 40

	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.059, 0.016, 0.118, 0.96)
	pstyle.border_color = Color(0.439, 0.251, 0.690)
	pstyle.set_border_width_all(2)
	_skill_panel.add_theme_stylebox_override("panel", pstyle)

	add_child(_skill_panel)

func _setup_game_over() -> void:
	_game_over_screen = Control.new()
	_game_over_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_game_over_screen.visible = false
	_game_over_screen.z_index = 100
	add_child(_game_over_screen)

	var bg := ColorRect.new()
	bg.color = Color(0.039, 0.008, 0.082, 0.95)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_game_over_screen.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	vbox.custom_minimum_size = Vector2(300, 200)
	vbox.position = Vector2(480 - 150, 270 - 100)
	_game_over_screen.add_child(vbox)

	var title := Label.new()
	title.text = "✦ DÉFAITE ✦"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.941, 0.376, 0.439))
	vbox.add_child(title)

	var sub_lbl := Label.new()
	sub_lbl.text = "Le donjon vous a englouti..."
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 14)
	sub_lbl.add_theme_color_override("font_color", Color(0.690, 0.565, 0.816))
	vbox.add_child(sub_lbl)

	var restart_btn := Button.new()
	restart_btn.text = "↺ Recommencer"
	restart_btn.add_theme_font_size_override("font_size", 14)
	restart_btn.custom_minimum_size = Vector2(180, 44)
	var bstyle := StyleBoxFlat.new()
	bstyle.bg_color = Color(0.314, 0.118, 0.502)
	bstyle.border_color = Color(0.941, 0.753, 0.251)
	bstyle.set_border_width_all(2)
	bstyle.set_corner_radius_all(6)
	bstyle.set_content_margin_all(8)
	restart_btn.add_theme_stylebox_override("normal", bstyle)
	restart_btn.add_theme_color_override("font_color", Color(0.941, 0.753, 0.251))
	restart_btn.pressed.connect(_restart_game)
	vbox.add_child(restart_btn)

func _connect_signals() -> void:
	GameState.stats_changed.connect(_check_death)

# ──────────────────────────────────────────────
#  GAME FLOW
# ──────────────────────────────────────────────
func _start_floor() -> void:
	var data: Dictionary = DungeonGenerator.generate(GameState.floor, GameState.luck_bonus)
	_dungeon_node.load_dungeon(data)
	_player_node.setup(_dungeon_node, data["player_spawn"])
	_camera.position = Vector2(data["player_spawn"]) * TILE_SIZE
	_hud.add_log("═══ Étage %d ═══" % GameState.floor, "event")
	_hud.add_log("Explorez le donjon — [K] pour les compétences", "info")

func _restart_game() -> void:
	_game_over_screen.visible = false
	GameState.reset()
	_start_floor()

# ──────────────────────────────────────────────
#  INPUT
# ──────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if _in_combat: return

	if event.is_action_pressed("ui_skill_tree"):
		_skill_panel_open = not _skill_panel_open
		_skill_panel.visible = _skill_panel_open
		return

	if event.is_action_pressed("move_up"):    _player_node.try_move(0, -1)
	elif event.is_action_pressed("move_down"): _player_node.try_move(0, 1)
	elif event.is_action_pressed("move_left"): _player_node.try_move(-1, 0)
	elif event.is_action_pressed("move_right"):_player_node.try_move(1, 0)

# ──────────────────────────────────────────────
#  EVENTS
# ──────────────────────────────────────────────
func _on_player_moved(new_pos: Vector2i) -> void:
	# Smooth camera follow
	var target := Vector2(new_pos) * TILE_SIZE
	var tween := create_tween()
	tween.tween_property(_camera, "position", target, 0.12).set_trans(Tween.TRANS_QUAD)

func _on_player_interact(tile_pos: Vector2i) -> void:
	var entity: Dictionary = _dungeon_node.get_entity_at(tile_pos)
	if entity.is_empty(): return

	match entity["type"]:
		"enemy":
			_begin_combat(entity, tile_pos)
		"chest":
			_open_chest(entity, tile_pos)
		"shrine":
			_use_shrine(entity, tile_pos)
		"exit":
			_go_next_floor()

func _begin_combat(entity: Dictionary, pos: Vector2i) -> void:
	_in_combat = true
	_combat_screen.start(entity, _hud)

func _on_combat_finished(player_won: bool) -> void:
	_in_combat = false
	if player_won:
		# Find and mark enemy dead
		for ep in _dungeon_node._entities:
			if ep["type"] == "enemy" and ep.get("alive", true):
				if ep["pos"] == _combat_screen._combat._enemy.get("pos", ep["pos"]):
					_dungeon_node.mark_entity_dead(ep["pos"])
					break
		AudioManager.play_level_up() if GameState.level > 1 else null
	else:
		if GameState.hp <= 0:
			AudioManager.play_death()
			_game_over_screen.visible = true

func _open_chest(entity: Dictionary, pos: Vector2i) -> void:
	var gold: int = entity.get("gold", 3)
	GameState.add_gold(gold)
	_dungeon_node.mark_entity_used(pos, "open")
	_hud.add_log("📦 Coffre: +%d Or!" % gold, "gold")
	AudioManager.play_chest()
	_player_node.try_move(pos.x - _player_node.grid_pos.x,
						  pos.y - _player_node.grid_pos.y)

func _use_shrine(entity: Dictionary, pos: Vector2i) -> void:
	var restore_hp := int(GameState.max_hp * 0.4)
	var restore_mp := int(GameState.max_mp * 0.5)
	GameState.heal(restore_hp)
	GameState.restore_mp(restore_mp)
	GameState.skill_points += 1
	GameState.emit_signal("stats_changed")
	_dungeon_node.mark_entity_used(pos, "used")
	_hud.add_log("🔮 Sanctuaire: +%d HP, MP restauré, +1 compétence!" % restore_hp, "event")
	AudioManager.play_skill_unlock()
	_player_node.try_move(pos.x - _player_node.grid_pos.x,
						  pos.y - _player_node.grid_pos.y)

func _go_next_floor() -> void:
	GameState.next_floor()
	_hud.add_log("Vous descendez plus profond...", "event")
	_start_floor()

func _check_death() -> void:
	if GameState.hp <= 0 and not _in_combat:
		_game_over_screen.visible = true
