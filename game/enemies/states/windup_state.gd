extends EnemyState
## Aviso antes do bote: para, agacha e avermelha por `windup_time`.

var _time_left := 0.0


func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	enemy.begin_windup()
	_time_left = enemy.stats.windup_time


func exit() -> void:
	enemy.end_windup()


func physics_update(delta: float) -> void:
	enemy.move_toward_direction(Vector2.ZERO, 0.0, delta)
	_time_left -= delta
	if _time_left <= 0.0:
		transition_to(ATTACK)
