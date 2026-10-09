extends EnemyState
## Bote: avança rápido na direção do player com a hitbox de ataque ativa.

var _time_left := 0.0


func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	enemy.start_lunge()
	_time_left = enemy.stats.lunge_time


func exit() -> void:
	enemy.end_lunge()


func physics_update(delta: float) -> void:
	enemy.lunge_step(delta)
	_time_left -= delta
	if _time_left <= 0.0:
		transition_to(RECOVER)
