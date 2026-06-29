extends Node
## CombatSystem — manages turn-based combat flow.

signal combat_log(msg: String, css_class: String)
signal combat_ended(player_won: bool)
signal enemy_hp_changed(hp: int, max_hp: int)

var _enemy: Dictionary = {}
var _shield_active: bool = false
var _locked: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func start_combat(enemy_data: Dictionary) -> void:
	_enemy = enemy_data.duplicate(true)
	_shield_active = false
	_locked = false
	emit_signal("combat_log", "⚔ Combat contre %s!" % _enemy["name"], "dmg")

func get_enemy() -> Dictionary:
	return _enemy

func can_act() -> bool:
	return not _locked

# ──────────────────────────────────────────────
#  PLAYER ACTIONS
# ──────────────────────────────────────────────
func action_attack() -> void:
	if _locked: return
	_locked = true
	var dmg := _calc_player_dmg(1.0)
	var crit_roll := _rng.randf_range(0.0, 100.0)
	var is_crit := crit_roll < float(GameState.crit_chance)
	if is_crit:
		dmg = int(dmg * 2.0)
		emit_signal("combat_log", "💥 CRITIQUE! %d dégâts!" % dmg, "gold")
		AudioManager.play_crit()
	else:
		emit_signal("combat_log", "⚔ Attaque: %d dégâts" % dmg, "dmg")
		AudioManager.play_hit()
	_deal_to_enemy(dmg)

func action_heavy() -> void:
	if _locked or not GameState.heavy_unlocked: return
	_locked = true
	var dmg := _calc_player_dmg(1.8)
	emit_signal("combat_log", "💢 Frappe Lourde: %d dégâts!" % dmg, "gold")
	AudioManager.play_hit()
	_deal_to_enemy(dmg)

func action_spell() -> void:
	if _locked or not GameState.spell_unlocked: return
	if GameState.mp < 3:
		emit_signal("combat_log", "Pas assez de MP!", "miss")
		return
	_locked = true
	GameState.spend_mp(3)
	var mult := 3.0 if GameState.mega_spell else 1.5
	var dmg := int(GameState.atk * mult)
	emit_signal("combat_log", "✨ Sort: %d dégâts (MP -%d)" % [dmg, 3 - GameState.mp_regen_per_cast], "spell")
	AudioManager.play_spell()
	_deal_to_enemy(dmg)

func action_shield() -> void:
	if _locked or not GameState.shield_unlocked: return
	_locked = true
	_shield_active = true
	emit_signal("combat_log", "🛡 Bouclier activé! (DEF ×2 ce tour)", "info")
	_enemy_turn()

func action_flee() -> void:
	if _locked: return
	_locked = true
	var chance := 0.40 + (float(GameState.level) * 0.02)
	if _rng.randf() < chance:
		emit_signal("combat_log", "🏃 Fuite réussie!", "info")
		emit_signal("combat_ended", false)
	else:
		emit_signal("combat_log", "Fuite échouée!", "miss")
		_enemy_turn()

# ──────────────────────────────────────────────
#  INTERNALS
# ──────────────────────────────────────────────
func _calc_player_dmg(multiplier: float) -> int:
	return max(1, int(GameState.atk * multiplier))

func _deal_to_enemy(dmg: int) -> void:
	_enemy["hp"] = max(0, _enemy["hp"] - dmg)
	emit_signal("enemy_hp_changed", _enemy["hp"], _enemy["max_hp"])
	if _enemy["hp"] <= 0:
		_on_enemy_defeated()
	else:
		_enemy_turn()

func _enemy_turn() -> void:
	var eff_def := GameState.def * (2 if _shield_active else 1)
	var raw_dmg := _enemy.get("atk", 3)
	var dmg := max(0, raw_dmg - eff_def)
	_shield_active = false
	if dmg == 0:
		emit_signal("combat_log", "%s attaque: BLOQUÉ!" % _enemy["name"], "miss")
	else:
		GameState.damage(dmg)
		emit_signal("combat_log", "%s: -%d HP" % [_enemy["name"], dmg], "dmg")

	if GameState.hp <= 0:
		emit_signal("combat_log", "Vous êtes mort...", "dmg")
		emit_signal("combat_ended", false)
	else:
		_locked = false

func _on_enemy_defeated() -> void:
	var gold_base: int = _enemy.get("gold", 1)
	var xp_amt: int   = _enemy.get("xp", 2)
	GameState.gain_xp(xp_amt)
	GameState.add_gold(gold_base)
	if GameState.heal_after_combat > 0:
		GameState.heal(GameState.heal_after_combat)
		emit_signal("combat_log",
			"⭐ Paladin: +%d HP récupérés" % GameState.heal_after_combat, "heal")
	emit_signal("combat_log",
		"%s vaincu! +%d XP, +%d Or" % [_enemy["name"], xp_amt, gold_base], "gold")
	emit_signal("combat_ended", true)
