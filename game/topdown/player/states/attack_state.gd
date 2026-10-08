extends TopDownState
## Ataque corpo a corpo: ativa a hitbox na direção da MIRA (mouse, analógico
## direito ou movimento) por um instante. O player desacelera durante o golpe.

var _time_left := 0.0


func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	player.face(player.get_input_vector())
	player.set_attack_active(true)
	_time_left = player.stats.attack_duration


func exit() -> void:
	player.set_attack_active(false)


func physics_update(delta: float) -> void:
	player.apply_movement(delta, Vector2.ZERO)
	player.move_and_slide()
	_time_left -= delta
	if _time_left <= 0.0:
		transition_to(IDLE)
