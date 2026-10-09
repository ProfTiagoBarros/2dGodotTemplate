extends EnemyState


func physics_update(delta: float) -> void:
	if enemy.target == null:
		transition_to(PATROL)
		return
	if enemy.can_attack_target():
		transition_to(WINDUP)
		return
	var direction := enemy.direction_to_target()
	enemy.face(direction)
	enemy.move_toward_direction(direction, enemy.stats.chase_speed, delta)
