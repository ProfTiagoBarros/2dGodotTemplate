extends PlatformerState


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_horizontal(delta, false)
	player.move_and_slide()

	if try_actions():
		return
	if player.is_on_floor():
		transition_to_free_state()
	elif player.wants_to_jump() and player.can_any_jump():
		# Coyote time (logo após sair da borda) ou pulo duplo.
		transition_to(JUMP)
