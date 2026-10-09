extends EnemyState
## Pausa após o bote: a janela de contra-ataque do jogador.

var _time_left := 0.0


func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	_time_left = enemy.stats.recover_time


func physics_update(delta: float) -> void:
	enemy.move_toward_direction(Vector2.ZERO, 0.0, delta)
	_time_left -= delta
	if _time_left <= 0.0:
		resume()
