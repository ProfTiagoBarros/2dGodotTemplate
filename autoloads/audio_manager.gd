extends Node
## Áudio global: música com crossfade e pool de players para SFX.
##
## AudioManager.play_music(preload("res://assets/audio/music/theme.ogg"))
## AudioManager.play_sfx(preload("res://assets/audio/sfx/jump.wav"), 0.1)
## AudioManager.play_sfx_at(stream, global_position)   # posicional 2D

const SFX_POOL_SIZE := 12
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const UI_BUS := &"UI"

var _music_players: Array[AudioStreamPlayer] = []
var _active_music := 0
var _sfx_pool: Array[AudioStreamPlayer] = []
var _next_sfx := 0
var _ui_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		_music_players.append(_create_player(MUSIC_BUS))
	for i in SFX_POOL_SIZE:
		_sfx_pool.append(_create_player(SFX_BUS))
	_ui_player = _create_player(UI_BUS)


func play_music(stream: AudioStream, fade_time: float = 1.0) -> void:
	var current := _music_players[_active_music]
	if current.stream == stream and current.playing:
		return
	if stream == null:
		stop_music(fade_time)
		return

	_active_music = 1 - _active_music
	var incoming := _music_players[_active_music]
	incoming.stream = stream
	incoming.volume_linear = 0.0
	incoming.play()

	var tween := create_tween().set_parallel()
	tween.tween_property(incoming, "volume_linear", 1.0, fade_time)
	if current.playing:
		tween.tween_property(current, "volume_linear", 0.0, fade_time)
		tween.chain().tween_callback(current.stop)


func stop_music(fade_time: float = 1.0) -> void:
	var current := _music_players[_active_music]
	if not current.playing:
		return
	var tween := create_tween()
	tween.tween_property(current, "volume_linear", 0.0, fade_time)
	tween.tween_callback(current.stop)


## Toca um efeito não posicional. `pitch_variation` (0..1) evita repetição monótona.
func play_sfx(stream: AudioStream, pitch_variation: float = 0.0, volume_linear: float = 1.0) -> void:
	if stream == null:
		return
	var player := _get_free_sfx_player()
	player.stream = stream
	player.volume_linear = volume_linear
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()


## Toca um efeito posicional na cena atual (atenuado pela distância à câmera).
func play_sfx_at(stream: AudioStream, position: Vector2, pitch_variation: float = 0.0) -> void:
	var scene := get_tree().current_scene
	if stream == null or scene == null:
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = SFX_BUS
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.finished.connect(player.queue_free)
	scene.add_child(player)
	player.global_position = position
	player.play()


func play_ui(stream: AudioStream) -> void:
	if stream == null:
		return
	_ui_player.stream = stream
	_ui_player.play()


func _get_free_sfx_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _sfx_pool:
		if not player.playing:
			return player
	# Pool cheio: reaproveita o mais antigo (round-robin).
	var stolen := _sfx_pool[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx_pool.size()
	return stolen


func _create_player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player
