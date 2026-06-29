extends Node2D
## Dungeon — renders the tilemap and manages all entities.

const TILE_SIZE: int = 16

const C_WALL_BASE  := Color(0.227, 0.078, 0.365)
const C_WALL_EDGE  := Color(0.290, 0.125, 0.439)
const C_WALL_CRACK := Color(0.365, 0.200, 0.502)
const C_FLOOR_A    := Color(0.145, 0.047, 0.239)
const C_FLOOR_B    := Color(0.173, 0.071, 0.267)
const C_FLOOR_DOT  := Color(0.220, 0.102, 0.325)
const C_FOG        := Color(0.059, 0.027, 0.110)
const C_FOG_EDGE   := Color(0.086, 0.043, 0.149)

const C_EXIT_DOOR  := Color(0.376, 0.627, 1.0)
const C_EXIT_GLOW  := Color(0.220, 0.502, 0.902)
const C_CHEST      := Color(0.251, 0.816, 0.627)
const C_CHEST_OPEN := Color(0.125, 0.439, 0.314)
const C_CHEST_BAND := Color(0.941, 0.753, 0.251)
const C_SHRINE     := Color(1.0, 0.627, 0.251)
const C_SHRINE_OFF := Color(0.400, 0.251, 0.063)

var _map: Array = []
var _fog: Array = []
var _entities: Array[Dictionary] = []
var _rows: int = 0
var _cols: int = 0
var _anim_t: float = 0.0

func _ready() -> void:
	pass

func load_dungeon(data: Dictionary) -> void:
	_map = data["map"]
	_rows = data["rows"]
	_cols = data["cols"]
	_entities = []
	for e in data["entities"]:
		_entities.append(e.duplicate(true))
	_fog = []
	for r in _rows:
		var row := []
		for c in _cols:
			row.append(true)
		_fog.append(row)
	queue_redraw()

func _process(delta: float) -> void:
	_anim_t += delta
	queue_redraw()

func _draw() -> void:
	if _map.is_empty(): return

	for r in _rows:
		for c in _cols:
			var x: int = c * TILE_SIZE
			var y: int = r * TILE_SIZE
			var rect := Rect2(x, y, TILE_SIZE, TILE_SIZE)

			if _fog[r][c]:
				draw_rect(rect, C_FOG)
				draw_rect(Rect2(x, y, TILE_SIZE / 2, TILE_SIZE / 2), C_FOG_EDGE)
				continue

			if _map[r][c] == 1:
				draw_rect(rect, C_WALL_BASE)
				draw_rect(Rect2(x + 1, y + 1, TILE_SIZE - 2, 3), C_WALL_EDGE)
				draw_rect(Rect2(x + 1, y + 1, 3, TILE_SIZE - 2), C_WALL_EDGE)
				if (r + c) % 5 == 0:
					draw_rect(Rect2(x + 4, y + 4, 2, 2), C_WALL_CRACK)
			else:
				var alt: bool = (r + c) % 2 == 0
				draw_rect(rect, C_FLOOR_A if alt else C_FLOOR_B)
				if alt:
					draw_rect(Rect2(x + 7, y + 7, 2, 2), C_FLOOR_DOT)

	for i in _entities.size():
		var e: Dictionary = _entities[i]
		var pos: Vector2i = e["pos"]
		if pos.y >= _rows or pos.x >= _cols: continue
		if _fog[pos.y][pos.x]: continue
		_draw_entity(e)

func _draw_entity(e: Dictionary) -> void:
	var x: int = e["pos"].x * TILE_SIZE
	var y: int = e["pos"].y * TILE_SIZE

	match e["type"]:
		"enemy":
			if not e.get("alive", true): return
			var ec: Color = e.get("color", Color(0.878, 0.188, 0.376))
			draw_rect(Rect2(x + 3, y + 3, 10, 10), ec)
			draw_rect(Rect2(x + 3, y + 3, 10, 4), ec.lightened(0.3))
			draw_rect(Rect2(x + 5, y + 5, 2, 2), Color(0.8, 1.0, 0.8))
			draw_rect(Rect2(x + 9, y + 5, 2, 2), Color(0.8, 1.0, 0.8))
			var hp_frac: float = float(e.get("hp",1)) / float(e.get("max_hp",1))
			draw_rect(Rect2(x + 1, y + 14, 14, 2), Color(0.4, 0.1, 0.1))
			draw_rect(Rect2(x + 1, y + 14, int(14 * hp_frac), 2), Color(0.878, 0.188, 0.376))
		"chest":
			var open: bool = e.get("open", false)
			var cc: Color = C_CHEST_OPEN if open else C_CHEST
			draw_rect(Rect2(x + 2, y + 7, 12, 7), cc)
			if not open:
				draw_rect(Rect2(x + 2, y + 6, 12, 3), cc.lightened(0.3))
				draw_rect(Rect2(x + 6, y + 8, 4, 3), C_CHEST_BAND)
		"shrine":
			var used: bool = e.get("used", false)
			var sc: Color = C_SHRINE_OFF if used else C_SHRINE
			draw_rect(Rect2(x + 5, y + 8, 6, 7), sc)
			draw_rect(Rect2(x + 3, y + 13, 10, 2), sc.darkened(0.2))
			if not used:
				var glow: float = abs(sin(_anim_t * 2.5)) * 0.5 + 0.3
				draw_rect(Rect2(x + 7, y + 3, 2, 5), Color(C_SHRINE, glow))
				draw_rect(Rect2(x + 5, y + 5, 6, 2), Color(C_SHRINE, glow))
		"exit":
			draw_rect(Rect2(x + 3, y + 2, 10, 13), C_EXIT_DOOR)
			draw_rect(Rect2(x + 5, y + 4, 6, 9), C_EXIT_GLOW)
			var shimmer: float = abs(sin(_anim_t * 3.0)) * 0.4 + 0.3
			draw_rect(Rect2(x + 5, y + 4, 6, 9), Color(1.0, 1.0, 1.0, shimmer * 0.15))
			draw_rect(Rect2(x + 10, y + 9, 2, 3), Color(0.196, 0.251, 0.502))

func is_walkable(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.x >= _cols or pos.y < 0 or pos.y >= _rows:
		return false
	return _map[pos.y][pos.x] == 0

func get_entity_at(pos: Vector2i) -> Dictionary:
	for i in _entities.size():
		var e: Dictionary = _entities[i]
		if e["pos"] == pos:
			if e["type"] == "enemy" and not e.get("alive", true):
				continue
			if e["type"] == "chest" and e.get("open", false):
				continue
			if e["type"] == "shrine" and e.get("used", false):
				continue
			return e
	return {}

func get_entity_index_at(pos: Vector2i) -> int:
	for i in _entities.size():
		var e: Dictionary = _entities[i]
		if e["pos"] == pos:
			return i
	return -1

func mark_entity_dead(pos: Vector2i) -> void:
	var idx: int = get_entity_index_at(pos)
	if idx >= 0:
		_entities[idx]["alive"] = false
	queue_redraw()

func mark_entity_used(pos: Vector2i, field: String = "open") -> void:
	var idx: int = get_entity_index_at(pos)
	if idx >= 0:
		_entities[idx][field] = true
	queue_redraw()

func reveal_fog(center: Vector2i, radius: int) -> void:
	var r2: int = radius * radius
	for r in _rows:
		for c in _cols:
			var dx: int = c - center.x
			var dy: int = r - center.y
			if dx * dx + dy * dy <= r2:
				_fog[r][c] = false
	queue_redraw()
