extends RefCounted
## Suíte do módulo platformer (executada por tests/smoke_test.tscn).

const LEVEL := "res://game/platformer/levels/platformer_level_01.tscn"


func run(t: SmokeTest) -> void:
	var game := await t.spawn_game(LEVEL)
	var player := game.get_tree().get_first_node_in_group(&"player") as PlatformerPlayer
	t.check(player != null, "PlatformerPlayer instanciado")
	if player == null:
		await t.despawn(game)
		return

	await _test_movement(t, game, player)
	await _test_ui(t, game)
	await _test_attacks(t, game, player)
	await _test_dash(t, player)
	await _test_abilities(t, game, player)
	await t.despawn(game)


func _test_movement(t: SmokeTest, game: Game, player: PlatformerPlayer) -> void:
	t.check(player.is_on_floor(), "Player cai e para no chão")
	t.check(player.state_machine.current_state.name == &"Idle", "Estado inicial é Idle")

	var ground_y := player.global_position.y
	await t.hold(&"jump", 12)
	t.check(player.global_position.y < ground_y - 10.0, "Pulo eleva o player")
	await t.frames(60)
	t.check(player.is_on_floor(), "Player volta ao chão após o pulo")

	var start_x := player.global_position.x
	await t.hold(&"move_right", 20)
	t.check(player.global_position.x > start_x + 5.0, "Player anda para a direita")

	var health_before := player.health.current
	var spikes := game.find_child("Spikes", true, false) as Node2D
	await _place(t, player, spikes.global_position + Vector2(0.0, -2.0))
	t.check(player.health.current < health_before, "Espinhos causam dano")
	await t.frames(50) # i-frames + knockback


func _test_ui(t: SmokeTest, game: Game) -> void:
	var hud := game.find_child("HUD", true, false) as GameHUD
	var expected: Array[StringName] = [&"jump", &"attack", &"dash", &"pause"]
	t.check(hud.get_hint_actions() == expected,
			"HUD mostra as dicas definidas pela fase")
	var tertiary := game.find_child("TertiaryButton", true, false) as TouchButton
	t.check(tertiary.visible and tertiary.action == &"dash", "Toque: botão C = dash no platformer")


func _test_attacks(t: SmokeTest, game: Game, player: PlatformerPlayer) -> void:
	var dummy := game.find_child("TrainingDummy", true, false) as Node2D
	var dummy_health := dummy.get_node("HealthComponent") as HealthComponent

	# Ataque lateral.
	await _place(t, player, dummy.global_position + Vector2(-16.0, 0.0))
	player.face(1.0)
	var before := dummy_health.current
	await t.tap(&"attack")
	await t.frames(6)
	t.check(dummy_health.current < before, "Ataque lateral acerta o alvo")
	await t.frames(20)
	t.check(not player.is_attacking() and player.state_machine.current_state.name != &"Attack",
			"Ataque termina e volta ao estado livre")

	# Ataque para cima (segurando ↑).
	Input.action_press(&"move_up")
	await t.tap(&"attack")
	await t.frames(2)
	t.check(player.attack_direction == Vector2.UP and is_equal_approx(player.attack_pivot.rotation, -PI / 2.0),
			"Segurando ↑ o ataque vai para cima")
	Input.action_release(&"move_up")
	await t.frames(30)

	# Pogo: ataque para baixo no ar acertando o alvo quica o player.
	await _place(t, player, dummy.global_position + Vector2(0.0, -28.0))
	before = dummy_health.current
	Input.action_press(&"move_down")
	await t.tap(&"attack")
	await t.frames(4)
	Input.action_release(&"move_down")
	t.check(player.attack_direction == Vector2.DOWN, "No ar segurando ↓ o ataque vai para baixo")
	t.check(dummy_health.current < before and player.velocity.y < 0.0, "Pogo: acertar para baixo quica o player")
	await t.frames(60)


func _test_dash(t: SmokeTest, player: PlatformerPlayer) -> void:
	await _place(t, player, Vector2(150.0, 280.0))
	player.face(1.0)
	var start_x := player.global_position.x
	await t.tap(&"dash")
	await t.frames(2)
	t.check(player.state_machine.current_state.name == &"Dash", "Dash no chão")
	await t.frames(10)
	t.check(player.global_position.x > start_x + 40.0, "Dash desloca o player")
	t.check(not player.can_dash(), "Dash entra em cooldown")
	await t.frames(30)

	# Dash no ar: sem gravidade durante o dash e só 1 por pulo.
	await _place(t, player, Vector2(150.0, 150.0))
	await t.tap(&"dash")
	await t.frames(2)
	var dash_y := player.global_position.y
	await t.frames(4)
	t.check(is_equal_approx(player.global_position.y, dash_y), "Dash no ar ignora a gravidade")
	await t.frames(6)
	t.check(player.air_dashes_left == 0 and not player.can_dash(), "Só 1 dash por tempo no ar")
	await t.frames(60)


func _test_abilities(t: SmokeTest, game: Game, player: PlatformerPlayer) -> void:
	t.check(not player.has_ability(PlatformerPlayer.ABILITY_DOUBLE_JUMP), "Pulo duplo começa bloqueado")
	await _place(t, player, Vector2(150.0, 280.0))
	t.check(not await _try_double_jump(t, player), "Sem a habilidade, não há pulo duplo")

	var pickup := game.find_child("DoubleJumpPickup", true, false)
	await _place(t, player, (pickup as Node2D).global_position)
	await t.frames(2)
	t.check(player.has_ability(PlatformerPlayer.ABILITY_DOUBLE_JUMP) and not is_instance_valid(pickup),
			"Item coletável destrava o pulo duplo")
	var saved: Array = SaveSystem.data.get(PlatformerPlayer.SAVE_KEY, [])
	t.check("double_jump" in saved, "Habilidade salva no SaveSystem (autosave)")
	t.check((game.find_child("Toast", true, false) as Label).visible, "HUD avisa a habilidade nova")

	await t.frames(40)
	t.check(await _try_double_jump(t, player), "Com a habilidade, o pulo duplo funciona")

	player.lock_ability(PlatformerPlayer.ABILITY_DASH)
	await _place(t, player, Vector2(150.0, 280.0))
	await t.tap(&"dash")
	await t.frames(2)
	t.check(player.state_machine.current_state.name != &"Dash", "Habilidade bloqueada não é usada")
	player.unlock_ability(PlatformerPlayer.ABILITY_DASH)


## Pula do chão, espera começar a cair e tenta pular de novo no ar.
func _try_double_jump(t: SmokeTest, player: PlatformerPlayer) -> bool:
	await t.hold(&"jump", 6)
	for i in 60:
		await t.frames(1)
		if player.velocity.y > 0.0:
			break
	await t.tap(&"jump")
	await t.frames(2)
	var jumped := player.velocity.y < 0.0
	await t.frames(80)
	return jumped


func _place(t: SmokeTest, player: PlatformerPlayer, position: Vector2) -> void:
	player.global_position = position
	player.velocity = Vector2.ZERO
	await t.frames(3)
