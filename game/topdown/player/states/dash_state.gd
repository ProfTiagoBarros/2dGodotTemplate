extends TopDownState
## Dash: velocidade fixa por um curto período, com i-frames.

var _time_left := 0.0


func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	# Dash na direção do movimento; parado, vai na direção da mira (twin-stick).
	var direction := player.get_input_vector()
	if direction.is_zero_approx():
		direction = player.aim_direction
	player.face(direction)
	player.velocity = direction.normalized() * player.stats.dash_speed
	player.health.grant_invulnerability(player.stats.dash_duration)
	_time_left = player.stats.dash_duration


func exit() -> void:
	# Sai do dash sem "patinar": limita à velocidade normal de caminhada.
	player.velocity = player.velocity.limit_length(player.stats.max_speed)
	player.start_dash_cooldown()


func physics_update(delta: float) -> void:
	player.move_and_slide()
	_time_left -= delta
	if _time_left <= 0.0:
		transition_to(IDLE)
