class_name TopDownEnemy
extends Enemy
## Inimigo top-down: vagueia perto do ponto de origem (com pausas) e
## persegue/ataca em 2D.

@export var wander_radius := 60.0
@export var wander_pause := Vector2(0.5, 1.2)

var _home := Vector2.ZERO
var _wander_point := Vector2.ZERO
var _wander_wait := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	super._ready()
	_home = global_position
	_wander_point = _home


func patrol_direction() -> Vector2:
	if _wander_wait > 0.0:
		_wander_wait -= get_physics_process_delta_time()
		return Vector2.ZERO
	var to_point := _wander_point - global_position
	if to_point.length() < 4.0 or is_on_wall():
		_wander_point = _home + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.3, 1.0) * wander_radius
		_wander_wait = _rng.randf_range(wander_pause.x, wander_pause.y)
		return Vector2.ZERO
	return to_point.normalized()


func direction_to_target() -> Vector2:
	if target == null:
		return Vector2.ZERO
	return global_position.direction_to(target.global_position)


func move_toward_direction(direction: Vector2, speed: float, delta: float) -> void:
	velocity = velocity.move_toward(direction * speed, stats.acceleration * delta)
	face(direction)
	move_and_slide()
