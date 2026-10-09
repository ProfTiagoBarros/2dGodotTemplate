extends EnemyState
## Atordoado após levar dano: o knockback desacelera e o ataque é cancelado.

var _time_left := 0.0


func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	_time_left = enemy.stats.hurt_time


func physics_update(delta: float) -> void:
	enemy.move_toward_direction(Vector2.ZERO, 0.0, delta)
	_time_left -= delta
	if _time_left <= 0.0:
		resume()
