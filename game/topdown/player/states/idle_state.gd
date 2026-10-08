extends TopDownState


func physics_update(delta: float) -> void:
	var direction := player.get_input_vector()
	player.apply_movement(delta, direction)
	player.move_and_slide()

	if try_actions():
		return
	if not direction.is_zero_approx():
		transition_to(WALK)
