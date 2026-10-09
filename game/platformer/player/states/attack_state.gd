extends PlatformerState
## Ataque corpo a corpo para o lado, para cima (↑) ou para baixo no ar (↓, pogo).
## O player continua se movendo e caindo normalmente durante o golpe
## (estilo Hollow Knight); pular no chão cancela o ataque.

var _time_left := 0.0


func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	player.start_attack()
	_time_left = player.stats.attack_duration


func exit() -> void:
	player.end_attack()


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_horizontal(delta, player.is_on_floor())
	player.move_and_slide()

	if player.is_on_floor() and player.wants_to_jump() and player.can_jump():
		transition_to(JUMP)
		return
	_time_left -= delta
	if _time_left <= 0.0:
		transition_to_free_state()
