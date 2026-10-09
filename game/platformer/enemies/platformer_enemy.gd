class_name PlatformerEnemy
extends Enemy
## Inimigo de plataforma: anda no chão com gravidade, vira em paredes e
## BEIRADAS na patrulha e não despenca ao perseguir. O bote é horizontal.

## Diferença de altura máxima para atacar (não ataca quem está em outro andar).
@export var attack_height_tolerance := 20.0

var _patrol_dir := 1.0

@onready var _ledge_ray: RayCast2D = $LedgeRay


func patrol_direction() -> Vector2:
	if is_on_floor():
		var hit_wall := is_on_wall() and signf(get_wall_normal().x) == -_patrol_dir
		if hit_wall or not has_ground_ahead(_patrol_dir):
			_patrol_dir = -_patrol_dir
	return Vector2(_patrol_dir, 0.0)


func direction_to_target() -> Vector2:
	if target == null:
		return Vector2.ZERO
	var dx := target.global_position.x - global_position.x
	return Vector2(signf(dx), 0.0) if absf(dx) > 2.0 else Vector2.ZERO


func can_attack_target() -> bool:
	if target == null:
		return false
	var offset := target.global_position - global_position
	return absf(offset.x) <= stats.attack_range and absf(offset.y) <= attack_height_tolerance


func move_toward_direction(direction: Vector2, speed: float, delta: float) -> void:
	_apply_gravity(delta)
	var desired := direction.x * speed
	# Não despenca de plataformas perseguindo/patrulhando.
	if not is_zero_approx(desired) and is_on_floor() and not has_ground_ahead(signf(desired)):
		desired = 0.0
	velocity.x = move_toward(velocity.x, desired, stats.acceleration * delta)
	if not is_zero_approx(direction.x):
		face(Vector2(signf(direction.x), 0.0))
	move_and_slide()


func lunge_step(delta: float) -> void:
	_apply_gravity(delta)
	if is_on_floor() and not has_ground_ahead(signf(velocity.x)):
		velocity.x = 0.0
	move_and_slide()


func apply_knockback(direction: Vector2) -> void:
	var side := signf(direction.x) if not is_zero_approx(direction.x) else -facing.x
	velocity = Vector2(side * stats.knockback_speed, -80.0)


## Há chão logo à frente na direção `dir` (-1/1)?
func has_ground_ahead(dir: float) -> bool:
	if is_zero_approx(dir):
		return true
	_ledge_ray.position.x = absf(_ledge_ray.position.x) * signf(dir)
	_ledge_ray.force_raycast_update()
	return _ledge_ray.is_colliding()


func _apply_gravity(delta: float) -> void:
	velocity.y = minf(velocity.y + stats.gravity * delta, stats.max_fall_speed)
