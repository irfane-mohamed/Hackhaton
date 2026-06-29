extends Node2D
## Player — handles movement on the tile grid and rendering.

signal moved(new_pos: Vector2i)
signal interact(tile_pos: Vector2i)

const TILE_SIZE: int = 16
const FOG_RADIUS: int = 5
const MOVE_DURATION: float = 0.12

var grid_pos: Vector2i = Vector2i.ZERO
var _moving: bool = false
var _facing: int = 1  # 1=right, -1=left
var _anim_timer: float = 0.0
var _bob: float = 0.0
var _shield_visible: bool = false

# Pixel art colors — no black/white
const COLOR_BODY   := Color(0.941, 0.753, 0.251)  # gold
const COLOR_HEAD   := Color(0.973, 0.847, 0.471)  # light gold
const COLOR_CAPE   := Color(0.502, 0.188, 0.816)  # amethyst
const COLOR_SWORD  := Color(0.753, 0.753, 1.0)    # pale blue steel
const COLOR_HILT   := Color(0.941, 0.753, 0.251)  # gold
const COLOR_EYE    := Color(0.196, 0.059, 0.271)  # deep purple (not black)
const COLOR_SHIELD := Color(0.376, 0.627, 1.0)    # blue shield

var _dungeon_ref: Node = null

func _ready() -> void:
	z_index = 10

func setup(dungeon: Node, spawn: Vector2i) -> void:
	_dungeon_ref = dungeon
	grid_pos = spawn
	position = Vector2(spawn.x * TILE_SIZE, spawn.y * TILE_SIZE)
	_reveal_fog()

func _process(delta: float) -> void:
	_anim_timer += delta
	_bob = sin(_anim_timer * 4.0) * 1.2
	queue_redraw()

func _draw() -> void:
	var t := Vector2.ZERO  # draw at local origin

	# Shield glow
	if _shield_visible:
		draw_rect(Rect2(t + Vector2(-2, -2), Vector2(TILE_SIZE + 4, TILE_SIZE + 4)),
				  Color(COLOR_SHIELD, 0.3), false, 1.5)

	# Cape (behind body)
	draw_rect(Rect2(t + Vector2(1, 9 + _bob), Vector2(3, 7)), COLOR_CAPE)
	draw_rect(Rect2(t + Vector2(12, 9 + _bob), Vector2(3, 7)), COLOR_CAPE)

	# Body
	draw_rect(Rect2(t + Vector2(4, 8 + _bob), Vector2(8, 7)), COLOR_BODY)

	# Head
	draw_rect(Rect2(t + Vector2(5, 3 + _bob), Vector2(6, 6)), COLOR_HEAD)

	# Eyes
	draw_rect(Rect2(t + Vector2(6 if _facing > 0 else 8, 5 + _bob), Vector2(2, 2)), COLOR_EYE)
	draw_rect(Rect2(t + Vector2(9 if _facing > 0 else 5, 5 + _bob), Vector2(2, 2)), COLOR_EYE)

	# Sword
	var sx := 13 if _facing > 0 else -1
	draw_rect(Rect2(t + Vector2(sx, 7 + _bob), Vector2(3, 8)), COLOR_SWORD)
	draw_rect(Rect2(t + Vector2(sx - 1, 10 + _bob), Vector2(5, 2)), COLOR_HILT)

func try_move(dx: int, dy: int) -> void:
	if _moving: return
	if dx != 0:
		_facing = sign(dx)

	var target := grid_pos + Vector2i(dx, dy)
	if _dungeon_ref == null: return
	if not _dungeon_ref.is_walkable(target): return

	# Check entity at target
	var entity = _dungeon_ref.get_entity_at(target)
	if entity != null:
		emit_signal("interact", target)
		return

	_move_to(target)
	AudioManager.play_step()

func _move_to(target: Vector2i) -> void:
	_moving = true
	grid_pos = target
	var tween := create_tween()
	tween.tween_property(self, "position",
		Vector2(target.x * TILE_SIZE, target.y * TILE_SIZE),
		MOVE_DURATION).set_trans(Tween.TRANS_QUAD)
	tween.finished.connect(func():
		_moving = false
		_reveal_fog()
		emit_signal("moved", grid_pos)
	)

func _reveal_fog() -> void:
	if _dungeon_ref:
		_dungeon_ref.reveal_fog(grid_pos, FOG_RADIUS)

func set_shield(active: bool) -> void:
	_shield_visible = active
	queue_redraw()

func is_moving() -> bool:
	return _moving
