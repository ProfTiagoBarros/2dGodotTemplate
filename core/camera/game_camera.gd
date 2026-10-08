class_name GameCamera
extends Camera2D
## Câmera com screen shake baseado em "trauma" (GDC 2016, Squirrel Eiserloh):
## o deslocamento é proporcional a trauma² e amostrado de ruído coerente,
## o que soa mais natural que valores aleatórios por frame.

@export var max_offset := Vector2(10.0, 7.0)
## Quanto trauma é perdido por segundo.
@export var trauma_decay := 1.5
@export var noise_speed := 25.0

var trauma := 0.0

var _noise := FastNoiseLite.new()
var _noise_time := 0.0


func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 1.0
	EventBus.camera_shake_requested.connect(add_trauma)


func add_trauma(amount: float) -> void:
	if not Settings.get_value("game", "screen_shake"):
		return
	trauma = clampf(trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	if trauma <= 0.0:
		offset = Vector2.ZERO
		return
	trauma = maxf(trauma - trauma_decay * delta, 0.0)
	_noise_time += delta * noise_speed
	var shake := trauma * trauma
	offset = Vector2(
		max_offset.x * shake * _noise.get_noise_2d(_noise_time, 0.0),
		max_offset.y * shake * _noise.get_noise_2d(0.0, _noise_time),
	)
