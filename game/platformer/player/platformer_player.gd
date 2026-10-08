class_name PlatformerPlayer
extends CharacterBody2D
## Player de plataforma (side-scrolling). A decisão "o que fazer agora" vive nos estados
## (states/); este script expõe só as primitivas de movimento e reage a eventos.

@export var stats: PlatformerStats
@export var knockback := Vector2(160.0, -180.0)

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var facing := 1.0

@onready var visual: Node2D = $Visual
@onready var health: HealthComponent = $HealthComponent
@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	health.health_changed.connect(_on_health_changed)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	# Adiado para que a HUD (instanciada depois) já esteja conectada.
	_on_health_changed.call_deferred(health.current, health.max_health)


func _physics_process(delta: float) -> void:
	# Roda antes da StateMachine (o pai é processado antes dos filhos).
	if Input.is_action_just_pressed(&"jump"):
		jump_buffer_timer = stats.jump_buffer_time
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)
	coyote_timer = stats.coyote_time if is_on_floor() else maxf(coyote_timer - delta, 0.0)


func get_input_axis() -> float:
	return Input.get_axis(&"move_left", &"move_right")


func apply_gravity(delta: float) -> void:
	var rising_with_jump := velocity.y < 0.0 and Input.is_action_pressed(&"jump")
	var gravity := stats.jump_gravity if rising_with_jump else stats.fall_gravity
	velocity.y = minf(velocity.y + gravity * delta, stats.max_fall_speed)


func apply_horizontal(delta: float, on_ground: bool) -> void:
	var axis := get_input_axis()
	var rate: float
	if is_zero_approx(axis):
		rate = stats.friction if on_ground else stats.air_friction
	else:
		rate = stats.acceleration if on_ground else stats.air_acceleration
		facing = signf(axis)
		visual.scale.x = facing
	velocity.x = move_toward(velocity.x, axis * stats.max_speed, rate * delta)


func wants_to_jump() -> bool:
	return jump_buffer_timer > 0.0


func can_jump() -> bool:
	return coyote_timer > 0.0


func jump() -> void:
	velocity.y = -stats.jump_velocity
	jump_buffer_timer = 0.0
	coyote_timer = 0.0


func _on_health_changed(current: int, max_health: int) -> void:
	EventBus.player_health_changed.emit(current, max_health)


func _on_damaged(_amount: int, source: Node) -> void:
	var direction := -facing
	if source is Node2D:
		var away := signf(global_position.x - (source as Node2D).global_position.x)
		if away != 0.0:
			direction = away
	velocity = Vector2(knockback.x * direction, knockback.y)
	EventBus.camera_shake_requested.emit(0.5)

	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(1.0, 0.3, 0.3), 0.05)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.3)


func _on_died() -> void:
	set_physics_process(false)
	state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 0.4)
	EventBus.player_died.emit()
