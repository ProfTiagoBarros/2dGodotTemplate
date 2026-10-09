extends RefCounted
## Suíte do módulo top-down (executada por tests/smoke_test.tscn).

const LEVEL := "res://game/topdown/levels/topdown_level_01.tscn"
const ENEMY_SCENE := preload("res://game/topdown/enemies/topdown_enemy.tscn")


func run(t: SmokeTest) -> void:
	var game := await t.spawn_game(LEVEL)
	var player := game.get_tree().get_first_node_in_group(&"player") as TopDownPlayer
	t.check(player != null, "TopDownPlayer instanciado")
	if player == null:
		await t.despawn(game)
		return

	# Inimigos da fase: confere e tira de cena (os testes de inimigo criam os seus).
	var level_enemies := game.get_tree().get_nodes_in_group(&"enemy")
	t.check(level_enemies.size() >= 2, "Fase tem inimigos")
	for enemy: Node in level_enemies:
		enemy.queue_free()
	await t.frames(1)

	t.check(player.state_machine.current_state.name == &"Idle", "Estado inicial é Idle")
	var hud := game.find_child("HUD", true, false) as GameHUD
	var expected_hints: Array[StringName] = [&"attack", &"dash", &"pause"]
	t.check(hud.get_hint_actions() == expected_hints,
			"HUD mostra as dicas da fase (sem pular)")
	t.check(not (game.find_child("TertiaryButton", true, false) as TouchButton).visible,
			"Toque: botão C escondido no top-down")
	var spawn := player.global_position
	await t.frames(20)
	t.check(player.global_position.distance_to(spawn) < 0.5, "Sem gravidade: player parado fica parado")

	# Diagonal: Input.get_vector normaliza, então a velocidade não passa de max_speed.
	Input.action_press(&"move_right")
	Input.action_press(&"move_down")
	await t.frames(40)
	var diagonal_speed := player.velocity.length()
	t.check(player.state_machine.current_state.name == &"Walk", "Estado Walk ao mover")
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	t.check(diagonal_speed <= player.stats.max_speed + 1.0, "Diagonal normalizada (%.0f px/s)" % diagonal_speed)
	t.check(player.global_position.x > spawn.x + 20.0 and player.global_position.y > spawn.y + 20.0,
			"Player anda na diagonal")
	await t.frames(30)

	# Dash: desloca rápido e concede i-frames.
	player.face(Vector2.LEFT)
	var before_dash := player.global_position
	t.spawned_effects.clear()
	await t.tap(&"dash")
	await t.frames(2) # o sinal physics_frame vem ANTES dos nós processarem
	t.check(player.state_machine.current_state.name == &"Dash", "Estado Dash ativo")
	t.check(player.health.is_invulnerable(), "Dash concede invencibilidade")
	t.check(not player.squash.scale.is_equal_approx(Vector2.ONE) and "dust_puff" in t.spawned_effects,
			"Dash estica o personagem e solta poeira")
	await t.frames(13)
	t.check(before_dash.x - player.global_position.x > 30.0, "Dash desloca o player")
	t.check(not player.can_dash(), "Dash entra em cooldown")
	await t.frames(40)

	# Ataque acerta o dummy e não fere o próprio player.
	var dummy := game.find_child("Dummy1", true, false) as Node2D
	var dummy_health := dummy.get_node("HealthComponent") as HealthComponent
	player.global_position = dummy.global_position + Vector2(-16.0, 0.0)
	player.velocity = Vector2.ZERO
	player.face(Vector2.RIGHT)
	var player_health := player.health.current
	var dummy_before := dummy_health.current
	await t.frames(2)
	t.spawned_effects.clear()
	await t.tap(&"attack")
	await t.frames(8)
	t.check(dummy_health.current < dummy_before, "Ataque causa dano no dummy")
	t.check("hit_sparks" in t.spawned_effects, "Golpe que acerta solta faíscas")
	t.check(player.health.current == player_health, "Ataque não fere o próprio player")
	await t.frames(15)
	t.check(player.state_machine.current_state.name == &"Idle", "Volta a Idle após o ataque")

	# Mira com analógico direito (twin-stick): o ataque sai na direção da mira.
	Input.action_press(&"aim_up", 1.0)
	await t.frames(3)
	t.check(player.aim_source == TopDownPlayer.AimSource.STICK and player.aim_direction.dot(Vector2.UP) > 0.99,
			"Analógico direito controla a mira")
	await t.tap(&"attack")
	await t.frames(2)
	t.check(is_equal_approx(player.attack_pivot.rotation, Vector2.UP.angle()), "Ataque sai na direção da mira")
	Input.action_release(&"aim_up")
	await t.frames(20)

	# Mira com mouse: mexer o mouse de verdade passa a mira para o cursor.
	var motion := InputEventMouseMotion.new()
	motion.device = InputEvent.DEVICE_ID_MOUSE
	motion.relative = Vector2(12.0, 0.0)
	motion.position = Vector2(500.0, 120.0)
	Input.parse_input_event(motion)
	await t.frames(3)
	t.check(InputManager.using_mouse and player.aim_source == TopDownPlayer.AimSource.MOUSE, "Mouse em uso assume a mira")
	var to_cursor := (player.get_global_mouse_position() - player.attack_pivot.global_position).normalized()
	t.check(player.aim_direction.dot(to_cursor) > 0.99, "Mira aponta para o cursor")

	var touch_click := InputEventMouseButton.new()
	touch_click.button_index = MOUSE_BUTTON_LEFT
	touch_click.pressed = true
	touch_click.device = InputEvent.DEVICE_ID_EMULATION
	t.check(not InputMap.event_is_action(touch_click, &"attack"), "Toque na tela (clique emulado) não dispara ataque")

	# Usar o gamepad devolve a mira ao movimento/analógico.
	var pad_button := InputEventJoypadButton.new()
	pad_button.button_index = JOY_BUTTON_LEFT_STICK
	pad_button.pressed = true
	Input.parse_input_event(pad_button)
	pad_button = pad_button.duplicate() as InputEventJoypadButton
	pad_button.pressed = false
	Input.parse_input_event(pad_button)
	await t.frames(3)
	t.check(not InputManager.using_mouse and player.aim_source == TopDownPlayer.AimSource.MOVEMENT,
			"Gamepad desativa a mira por mouse")

	await _test_enemies(t, game, player)
	await t.despawn(game)


func _test_enemies(t: SmokeTest, game: Game, player: TopDownPlayer) -> void:
	player.health.revive()
	player.global_position = Vector2(560.0, 300.0)
	player.velocity = Vector2.ZERO
	var slime: TopDownEnemy = ENEMY_SCENE.instantiate()
	(game.get_node("%World") as Node).get_child(0).get_node("Entities").add_child(slime)
	slime.global_position = Vector2(480.0, 250.0)
	var states: Array[StringName] = []
	slime.state_machine.state_changed.connect(func(_from: StringName, to: StringName) -> void: states.append(to))
	await t.frames(5)

	# Persegue em 2D (nos dois eixos) e ataca com aviso.
	t.check(slime.state_machine.current_state.name == &"Chase", "Slime vê o player e persegue")
	var to_player := slime.global_position.direction_to(player.global_position)
	t.check(slime.velocity.normalized().dot(to_player) > 0.9, "Perseguição vai direto ao player (2D)")
	var health_before := player.health.current
	for i in 150:
		await t.frames(1)
		if player.health.current < health_before:
			break
	t.check(&"Windup" in states and &"Attack" in states, "Slime avisa (windup) antes do bote")
	t.check(player.health.current < health_before, "Slime causa dano no player")

	# Matar: 3 golpes mirando no slime.
	player.health.revive()
	player.health.god_mode = true
	var killed: Array[int] = [0]
	EventBus.enemy_died.connect(func(_enemy: Node) -> void: killed[0] += 1, CONNECT_ONE_SHOT)
	for hit in 3:
		if not is_instance_valid(slime) or slime.health.is_dead():
			break
		player.global_position = slime.global_position + Vector2(-16.0, 0.0)
		player.velocity = Vector2.ZERO
		player.face(Vector2.RIGHT)
		await t.frames(2)
		await t.tap(&"attack")
		await t.frames(25)
	t.check(&"Hurt" in states, "Golpe atordoa o slime (Hurt)")
	t.check(killed[0] == 1, "3 golpes matam o slime (EventBus.enemy_died)")
	await t.frames(30)
	t.check(not is_instance_valid(slime), "Slime morto sai da cena")
	player.health.god_mode = false
