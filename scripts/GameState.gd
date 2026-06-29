extends Node
## GameState — Autoload singleton
## Stores all persistent player & game data across scenes.

signal stats_changed
signal skill_unlocked(skill_id: String)
signal level_up(new_level: int)
signal floor_changed(floor_num: int)

# ──────────────────────────────────────────────
#  PLAYER STATS
# ──────────────────────────────────────────────
var player_name: String = "Arathos"
var level: int = 1
var floor: int = 1

var hp: int = 30
var max_hp: int = 30
var mp: int = 15
var max_mp: int = 15
var xp: int = 0
var xp_next: int = 20

var base_atk: int = 5
var base_def: int = 2
var gold: int = 0
var skill_points: int = 0

# ──────────────────────────────────────────────
#  COMPUTED STATS (skill bonuses applied)
# ──────────────────────────────────────────────
var atk: int = 5
var def: int = 2
var crit_chance: int = 0       # percentage
var heal_after_combat: int = 0
var mp_regen_per_cast: int = 0
var gold_bonus_pct: int = 0
var luck_bonus: int = 0        # extra chests per floor

# ──────────────────────────────────────────────
#  SKILL TREE
# ──────────────────────────────────────────────
# skill_id -> current level (0 = locked)
var skills: Dictionary = {}

# Skill definitions: id, name, icon, desc, max_lv, sp_cost, requires[]
const SKILL_DEFS: Array = [
	# Tier 0 — Foundation
	{
		"id": "str1", "name": "Force I", "icon": "💪",
		"desc": "ATQ +2 par niveau (max 3)",
		"max_lv": 3, "cost": 1, "requires": [],
		"row": 0, "col": 0
	},
	{
		"id": "def1", "name": "Défense I", "icon": "🛡",
		"desc": "DEF +2 par niveau (max 3)",
		"max_lv": 3, "cost": 1, "requires": [],
		"row": 0, "col": 1
	},
	{
		"id": "vit1", "name": "Vitalité", "icon": "❤",
		"desc": "HP max +8 par niveau (max 3)",
		"max_lv": 3, "cost": 1, "requires": [],
		"row": 0, "col": 2
	},
	{
		"id": "mag1", "name": "Arcane I", "icon": "✨",
		"desc": "Débloque les sorts de feu",
		"max_lv": 1, "cost": 1, "requires": [],
		"row": 0, "col": 3
	},
	# Tier 1 — Intermediate
	{
		"id": "str2", "name": "Force II", "icon": "⚔",
		"desc": "ATQ +4. Débloque la Frappe Lourde",
		"max_lv": 2, "cost": 2, "requires": ["str1"],
		"row": 1, "col": 0
	},
	{
		"id": "def2", "name": "Armure", "icon": "🏰",
		"desc": "DEF +3. Débloque l'action Bouclier",
		"max_lv": 2, "cost": 2, "requires": ["def1"],
		"row": 1, "col": 1
	},
	{
		"id": "mag2", "name": "Arcane II", "icon": "🔮",
		"desc": "Sort: récupère 1 MP par cast par niveau",
		"max_lv": 2, "cost": 2, "requires": ["mag1", "vit1"],
		"row": 1, "col": 2
	},
	{
		"id": "gold1", "name": "Pillard", "icon": "💰",
		"desc": "Or gagné +50% par niveau",
		"max_lv": 2, "cost": 1, "requires": ["def1"],
		"row": 1, "col": 3
	},
	# Tier 2 — Advanced
	{
		"id": "berz", "name": "Berserker", "icon": "🔥",
		"desc": "ATQ +6. Coups critiques (25% chance)",
		"max_lv": 2, "cost": 3, "requires": ["str2"],
		"row": 2, "col": 0
	},
	{
		"id": "palad", "name": "Paladin", "icon": "⭐",
		"desc": "Soin +3 HP après chaque combat",
		"max_lv": 2, "cost": 3, "requires": ["def2", "str1"],
		"row": 2, "col": 1
	},
	{
		"id": "arch", "name": "Archimage", "icon": "🌀",
		"desc": "Sort : dégâts ×3 au lieu de ×1.5",
		"max_lv": 1, "cost": 3, "requires": ["mag2", "str1"],
		"row": 2, "col": 2
	},
	{
		"id": "luck", "name": "Fortune", "icon": "🍀",
		"desc": "+1 coffre garanti par étage",
		"max_lv": 1, "cost": 2, "requires": ["gold1"],
		"row": 2, "col": 3
	},
]

# ──────────────────────────────────────────────
#  COMBAT FLAGS
# ──────────────────────────────────────────────
var spell_unlocked: bool = false
var heavy_unlocked: bool = false
var shield_unlocked: bool = false
var mega_spell: bool = false

# ──────────────────────────────────────────────
#  INIT
# ──────────────────────────────────────────────
func _ready() -> void:
	reset()

func reset() -> void:
	level = 1
	floor = 1
	hp = 30; max_hp = 30
	mp = 15; max_mp = 15
	xp = 0; xp_next = 20
	base_atk = 5; base_def = 2
	gold = 0; skill_points = 0
	spell_unlocked = false
	heavy_unlocked = false
	shield_unlocked = false
	mega_spell = false
	crit_chance = 0
	heal_after_combat = 0
	mp_regen_per_cast = 0
	gold_bonus_pct = 0
	luck_bonus = 0
	skills.clear()
	for s in SKILL_DEFS:
		skills[s["id"]] = 0
	_recompute_stats()

# ──────────────────────────────────────────────
#  STAT COMPUTATION
# ──────────────────────────────────────────────
func _recompute_stats() -> void:
	atk = base_atk
	def = base_def
	crit_chance = 0
	heal_after_combat = 0
	mp_regen_per_cast = 0
	gold_bonus_pct = 0
	luck_bonus = 0
	spell_unlocked = false
	heavy_unlocked = false
	shield_unlocked = false
	mega_spell = false

	var lv_str1: int = skills.get("str1", 0)
	var lv_def1: int = skills.get("def1", 0)
	var lv_vit1: int = skills.get("vit1", 0)
	var lv_mag1: int = skills.get("mag1", 0)
	var lv_str2: int = skills.get("str2", 0)
	var lv_def2: int = skills.get("def2", 0)
	var lv_mag2: int = skills.get("mag2", 0)
	var lv_gold1: int = skills.get("gold1", 0)
	var lv_berz: int  = skills.get("berz", 0)
	var lv_palad: int = skills.get("palad", 0)
	var lv_arch: int  = skills.get("arch", 0)
	var lv_luck: int  = skills.get("luck", 0)

	atk += lv_str1 * 2
	def += lv_def1 * 2
	max_hp = 30 + lv_vit1 * 8 + level * 6
	max_mp = 15 + level * 3

	if lv_mag1 >= 1: spell_unlocked = true
	if lv_str2 >= 1: heavy_unlocked = true; atk += lv_str2 * 4
	if lv_def2 >= 1: shield_unlocked = true; def += lv_def2 * 3
	if lv_mag2 >= 1: mp_regen_per_cast = lv_mag2
	if lv_gold1 >= 1: gold_bonus_pct = lv_gold1 * 50
	if lv_berz >= 1:  atk += lv_berz * 6; crit_chance = lv_berz * 25
	if lv_palad >= 1: heal_after_combat = lv_palad * 3
	if lv_arch >= 1:  mega_spell = true
	if lv_luck >= 1:  luck_bonus = 1

	hp = clamp(hp, 0, max_hp)
	mp = clamp(mp, 0, max_mp)
	emit_signal("stats_changed")

# ──────────────────────────────────────────────
#  SKILL UPGRADE
# ──────────────────────────────────────────────
func can_upgrade(skill_id: String) -> bool:
	var sdef = _get_def(skill_id)
	if sdef.is_empty(): return false
	var cur_lv: int = skills.get(skill_id, 0)
	if cur_lv >= sdef["max_lv"]: return false
	if skill_points < sdef["cost"]: return false
	for req in sdef["requires"]:
		if skills.get(req, 0) < 1: return false
	return true

func upgrade_skill(skill_id: String) -> bool:
	if not can_upgrade(skill_id): return false
	var sdef = _get_def(skill_id)
	skill_points -= sdef["cost"]
	skills[skill_id] += 1
	_recompute_stats()
	emit_signal("skill_unlocked", skill_id)
	return true

func _get_def(skill_id: String) -> Dictionary:
	for s in SKILL_DEFS:
		if s["id"] == skill_id:
			return s
	return {}

# ──────────────────────────────────────────────
#  XP / LEVELING
# ──────────────────────────────────────────────
func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_next:
		xp -= xp_next
		level += 1
		xp_next = int(xp_next * 1.4)
		base_atk += 1
		skill_points += 1
		hp = min(max_hp, hp + 6)
		mp = min(max_mp, mp + 3)
		_recompute_stats()
		emit_signal("level_up", level)

# ──────────────────────────────────────────────
#  HP / MP HELPERS
# ──────────────────────────────────────────────
func damage(amount: int) -> void:
	hp = max(0, hp - amount)
	emit_signal("stats_changed")

func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)
	emit_signal("stats_changed")

func spend_mp(amount: int) -> bool:
	if mp < amount: return false
	mp = max(0, mp - amount + mp_regen_per_cast)
	emit_signal("stats_changed")
	return true

func restore_mp(amount: int) -> void:
	mp = min(max_mp, mp + amount)
	emit_signal("stats_changed")

func add_gold(amount: int) -> void:
	var bonus: int = int(amount * gold_bonus_pct / 100.0)
	gold += amount + bonus
	emit_signal("stats_changed")

func next_floor() -> void:
	floor += 1
	heal(int(max_hp * 0.3))
	restore_mp(int(max_mp * 0.5))
	emit_signal("floor_changed", floor)
