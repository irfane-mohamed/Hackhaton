extends Node
## AudioManager — Generates simple sound effects procedurally.
## No external audio files required.

var _players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8

func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

func _get_free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0]

## Play a generated tone burst
func play_tone(freq: float, duration: float, volume_db: float = -8.0) -> void:
	var p := _get_free_player()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = duration
	p.stream = gen
	p.volume_db = volume_db
	p.play()
	await get_tree().process_frame
	var pb := p.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null: return
	var sample_rate := 22050.0
	var samples := int(sample_rate * duration)
	for i in samples:
		var t := float(i) / sample_rate
		var env := 1.0 - (t / duration)  # linear decay
		var val := sin(TAU * freq * t) * env * 0.4
		pb.push_frame(Vector2(val, val))

func play_hit() -> void:
	play_tone(220.0, 0.08, -6.0)

func play_crit() -> void:
	play_tone(440.0, 0.12, -4.0)

func play_spell() -> void:
	play_tone(660.0, 0.18, -6.0)

func play_level_up() -> void:
	play_tone(523.0, 0.15, -4.0)
	await get_tree().create_timer(0.15).timeout
	play_tone(659.0, 0.15, -4.0)
	await get_tree().create_timer(0.15).timeout
	play_tone(784.0, 0.25, -4.0)

func play_chest() -> void:
	play_tone(392.0, 0.1, -6.0)
	await get_tree().create_timer(0.1).timeout
	play_tone(523.0, 0.15, -6.0)

func play_step() -> void:
	play_tone(80.0 + randf() * 20.0, 0.04, -16.0)

func play_skill_unlock() -> void:
	play_tone(784.0, 0.1, -5.0)
	await get_tree().create_timer(0.1).timeout
	play_tone(988.0, 0.18, -5.0)

func play_death() -> void:
	play_tone(150.0, 0.3, -4.0)
	await get_tree().create_timer(0.3).timeout
	play_tone(100.0, 0.5, -4.0)
