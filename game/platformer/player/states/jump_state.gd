extends PlatformerState


func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	player.jump()


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_horizontal(delta, false)
	player.move_and_slide()

	if try_actions():
		return
	if player.wants_to_jump() and player.can_any_jump():
		# Pulo duplo ainda subindo: reaplica o impulso sem trocar de estado.
		player.jump()
	elif player.velocity.y >= 0.0:
		transition_to(FALL)
