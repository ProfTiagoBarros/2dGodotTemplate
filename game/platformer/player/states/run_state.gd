extends PlatformerState


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_horizontal(delta, true)
	player.move_and_slide()

	if try_actions():
		return
	if not player.is_on_floor():
		transition_to(FALL)
	elif player.wants_to_jump() and player.can_any_jump():
		transition_to(JUMP)
	elif is_zero_approx(player.get_input_axis()):
		transition_to(IDLE)
