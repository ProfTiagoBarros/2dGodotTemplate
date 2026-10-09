extends PlatformerState
## Dash horizontal: velocidade fixa e SEM gravidade (atravessa buracos no ar).
## Limitado por `air_dashes` enquanto no ar; termina antes ao bater numa parede.

var _direction := 1.0
var _time_left := 0.0


func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	_direction = player.start_dash()
	_time_left = player.stats.dash_duration


func exit() -> void:
	player.end_dash()


func physics_update(delta: float) -> void:
	player.velocity = Vector2(_direction * player.stats.dash_speed, 0.0)
	player.move_and_slide()
	_time_left -= delta
	if _time_left <= 0.0 or player.is_on_wall():
		transition_to_free_state()
