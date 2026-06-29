extends Node
## DungeonGenerator — BSP-based procedural dungeon.
## Returns a Dictionary with map array and entity spawn list.

const COLS: int = 32
const ROWS: int = 24
const TILE_WALL: int = 1
const TILE_FLOOR: int = 0

class Room:
	var x: int; var y: int; var w: int; var h: int
	func _init(rx:int,ry:int,rw:int,rh:int) -> void:
		x=rx; y=ry; w=rw; h=rh
	func center() -> Vector2i:
		return Vector2i(x + w/2, y + h/2)
	func random_interior(rng: RandomNumberGenerator) -> Vector2i:
		return Vector2i(
			x + 1 + rng.randi_range(0, w-3),
			y + 1 + rng.randi_range(0, h-3)
		)
	func overlaps(other: Room) -> bool:
		return x < other.x+other.w+1 and x+w > other.x-1 \
			and y < other.y+other.h+1 and y+h > other.y-1

static func generate(floor_num: int, luck_bonus: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var map := []
	for r in ROWS:
		var row := []
		for c in COLS:
			row.append(TILE_WALL)
		map.append(row)

	var rooms: Array[Room] = []
	var attempts := 0
	while rooms.size() < 9 and attempts < 200:
		attempts += 1
		var w := rng.randi_range(4, 8)
		var h := rng.randi_range(4, 7)
		var x := rng.randi_range(1, COLS - w - 2)
		var y := rng.randi_range(1, ROWS - h - 2)
		var r := Room.new(x, y, w, h)
		var ok := true
		for existing in rooms:
			if r.overlaps(existing):
				ok = false; break
		if ok:
			rooms.append(r)
			for ry in range(r.y, r.y + r.h):
				for rx in range(r.x, r.x + r.w):
					map[ry][rx] = TILE_FLOOR

	# Connect rooms with L-shaped corridors
	for i in range(1, rooms.size()):
		var a := rooms[i-1].center()
		var b := rooms[i].center()
		_carve_corridor(map, a, b)

	# Diagonal shortcuts for variety
	if rooms.size() > 4:
		var jump := rng.randi_range(1, rooms.size()-2)
		var a2 := rooms[jump].center()
		var b2 := rooms[rng.randi_range(0, jump-1)].center()
		_carve_corridor(map, a2, b2)

	# Entities
	var entities: Array[Dictionary] = []
	var tier: int = mini(2, (floor_num - 1) / 2)

	var enemy_pools := [
		[
			{"name":"Slime Violet","emoji":"🟣","hp":12,"atk":3,"xp":5,"gold":2,"color":Color(0.5,0.2,0.8)},
			{"name":"Rat Spectral","emoji":"🐀","hp":8,"atk":4,"xp":4,"gold":1,"color":Color(0.4,0.6,0.4)},
			{"name":"Araignée Cryo","emoji":"🕷","hp":10,"atk":3,"xp":5,"gold":2,"color":Color(0.3,0.7,0.9)},
		],
		[
			{"name":"Squelette","emoji":"💀","hp":18,"atk":5,"xp":8,"gold":3,"color":Color(0.7,0.7,0.5)},
			{"name":"Liche Jr","emoji":"🧟","hp":15,"atk":6,"xp":9,"gold":4,"color":Color(0.4,0.8,0.4)},
			{"name":"Golem Rune","emoji":"🗿","hp":22,"atk":4,"xp":10,"gold":5,"color":Color(0.6,0.4,0.8)},
		],
		[
			{"name":"Démon Ardent","emoji":"😈","hp":28,"atk":8,"xp":14,"gold":7,"color":Color(0.9,0.3,0.2)},
			{"name":"Dragon Nano","emoji":"🐲","hp":35,"atk":7,"xp":18,"gold":10,"color":Color(0.3,0.8,0.3)},
			{"name":"Ombre Éternelle","emoji":"👁","hp":30,"atk":9,"xp":16,"gold":8,"color":Color(0.5,0.2,0.9)},
		],
	]

	# Player spawns in room 0
	var player_spawn: Vector2i = rooms[0].center()

	for i in range(1, rooms.size()):
		var rm := rooms[i]
		var pos: Vector2i = rm.center()
		var roll := rng.randf()

		if i == rooms.size() - 1:
			# Exit staircase in last room
			entities.append({"type":"exit","pos":pos})
		elif roll < 0.40:
			var edef: Dictionary = enemy_pools[tier][rng.randi_range(0, 2)].duplicate()
			edef["hp"] += (floor_num - 1) * 3
			edef["max_hp"] = edef["hp"]
			edef["pos"] = pos
			edef["type"] = "enemy"
			entities.append(edef)
		elif roll < 0.60:
			var base_gold: int = rng.randi_range(3, 8)
			entities.append({"type":"chest","pos":pos,"gold":base_gold})
		else:
			entities.append({"type":"shrine","pos":pos})

		# Extra chest from luck bonus
		if luck_bonus > 0 and i == 2:
			var ep: Vector2i = rm.random_interior(rng)
			entities.append({"type":"chest","pos":ep,"gold":rng.randi_range(2,5)})

	return {
		"map": map,
		"player_spawn": player_spawn,
		"entities": entities,
		"rows": ROWS,
		"cols": COLS,
	}

static func _carve_corridor(map: Array, a: Vector2i, b: Vector2i) -> void:
	# Horizontal then vertical
	var cx := a.x
	var cy := a.y
	while cx != b.x:
		map[cy][cx] = TILE_FLOOR
		cx += sign(b.x - cx)
	while cy != b.y:
		map[cy][cx] = TILE_FLOOR
		cy += sign(b.y - cy)
	map[cy][cx] = TILE_FLOOR
