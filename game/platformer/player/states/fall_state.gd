extends PlatformerState


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_horizontal(delta, false)
	player.move_and_slide()

	if player.is_on_floor():
		transition_to(IDLE if is_zero_approx(player.get_input_axis()) else RUN)
	elif player.wants_to_jump() and player.can_jump():
		# Coyote time: ainda pode pular logo após sair da borda.
		transition_to(JUMP)
