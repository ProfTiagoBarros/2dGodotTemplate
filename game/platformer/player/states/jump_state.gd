extends PlatformerState


func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	player.jump()


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_horizontal(delta, false)
	player.move_and_slide()

	if player.velocity.y >= 0.0:
		transition_to(FALL)
