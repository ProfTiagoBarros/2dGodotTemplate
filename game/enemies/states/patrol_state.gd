extends EnemyState


func physics_update(delta: float) -> void:
	enemy.move_toward_direction(enemy.patrol_direction(), enemy.stats.patrol_speed, delta)
	if enemy.target != null:
		transition_to(CHASE)
