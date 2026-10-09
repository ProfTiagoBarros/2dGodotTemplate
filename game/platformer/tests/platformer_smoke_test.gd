extends RefCounted
## Suíte do módulo platformer (executada por tests/smoke_test.tscn).

const LEVEL := "res://game/platformer/levels/platformer_level_01.tscn"
const ENEMY_SCENE := preload("res://game/platformer/enemies/platformer_enemy.tscn")


func run(t: SmokeTest) -> void:
	var game := await t.spawn_game(LEVEL)
	var player := game.get_tree().get_first_node_in_group(&"player") as PlatformerPlayer
	t.check(player != null, "PlatformerPlayer instanciado")
	if player == null:
		await t.despawn(game)
		return

	# Inimigos da fase: confere que existem e tira de cena para os testes de
	# movimento serem determinísticos (os de inimigo criam os seus).
	var level_enemies := game.get_tree().get_nodes_in_group(&"enemy")
	t.check(level_enemies.size() >= 2, "Fase tem inimigos")
	for enemy: Node in level_enemies:
		enemy.queue_free()
	await t.frames(1)

	await _test_movement(t, game, player)
	await _test_ui(t, game)
	await _test_attacks(t, game, player)
	await _test_dash(t, player)
	await _test_abilities(t, game, player)
	await _test_game_feel(t, game, player)
	await _test_enemies(t, game, player)
	await t.despawn(game)


func _spawn_enemy(game: Game, position: Vector2) -> PlatformerEnemy:
	var enemy: PlatformerEnemy = ENEMY_SCENE.instantiate()
	(game.get_node("%World") as Node).get_child(0).add_child(enemy)
	enemy.global_position = position
	return enemy


func _test_enemies(t: SmokeTest, game: Game, player: PlatformerPlayer) -> void:
	player.health.revive()
	await _place(t, player, Vector2(470.0, 280.0))

	# Patrulha: anda no chão e vira na beirada de uma plataforma pequena.
	var walker := _spawn_enemy(game, Vector2(200.0, 280.0))
	var ledge_walker := _spawn_enemy(game, Vector2(260.0, 234.0))
	await t.frames(5)
	var start_x := walker.global_position.x
	t.check(walker.state_machine.current_state.name == &"Patrol", "Inimigo começa patrulhando")
	await t.frames(240)
	t.check(absf(walker.global_position.x - start_x) > 5.0, "Patrulha move o inimigo")
	t.check(ledge_walker.is_on_floor() and absf(ledge_walker.global_position.y - 234.0) < 2.0,
			"Patrulha vira na beirada (não cai da plataforma)")
	ledge_walker.queue_free()

	# Perseguição e ataque (com aviso antes do bote).
	var states: Array[StringName] = []
	walker.state_machine.state_changed.connect(func(_from: StringName, to: StringName) -> void: states.append(to))
	await _place(t, player, walker.global_position + Vector2(90.0, 0.0))
	# Percepção roda a ~10 Hz: até 0,1 s de "tempo de reação".
	var is_chasing := func() -> bool: return walker.state_machine.current_state.name == &"Chase" and walker.velocity.x > 0.0
	t.check(await _wait_for(t, is_chasing, 20), "Ver o player faz o inimigo perseguir")
	var health_before := player.health.current
	for i in 150:
		await t.frames(1)
		if player.health.current < health_before:
			break
	t.check(&"Windup" in states and &"Attack" in states, "Inimigo avisa (windup) antes do bote")
	t.check(player.health.current < health_before, "Inimigo causa dano no player")
	player.health.revive()

	# Matar o inimigo: dano → atordoado (Hurt) → morte → some da cena.
	player.health.god_mode = true
	var killed: Array[Node] = []
	EventBus.enemy_died.connect(func(enemy: Node) -> void: killed.append(enemy), CONNECT_ONE_SHOT)
	for hit in 3:
		if not is_instance_valid(walker) or walker.health.is_dead():
			break
		await _place(t, player, walker.global_position + Vector2(-16.0, 0.0))
		player.face(1.0)
		await t.tap(&"attack")
		await t.frames(25)
		if hit == 0:
			t.check(&"Hurt" in states, "Golpe atordoa o inimigo (Hurt)")
	t.check(killed.size() == 1, "3 golpes matam o inimigo (EventBus.enemy_died)")
	await t.frames(30)
	t.check(not is_instance_valid(walker), "Inimigo morto sai da cena")

	# Times: inimigos não se ferem entre si nem ferem o alvo de treino.
	await _place(t, player, Vector2(950.0, 280.0))
	var dummy := game.find_child("TrainingDummy", true, false) as Node2D
	var dummy_health := dummy.get_node("HealthComponent") as HealthComponent
	dummy_health.revive()
	var a := _spawn_enemy(game, dummy.global_position + Vector2(-12.0, 0.0))
	var b := _spawn_enemy(game, dummy.global_position + Vector2(-14.0, 0.0))
	await t.frames(3)
	a.set_attack_active(true)
	await t.frames(15)
	t.check(a.health.current == a.health.max_health and b.health.current == b.health.max_health,
			"Inimigos não se ferem entre si (time 'enemy')")
	t.check(dummy_health.current == dummy_health.max_health, "Inimigos não ferem o alvo de treino")
	a.queue_free()
	b.queue_free()
	player.health.god_mode = false
	await t.frames(2)


func _test_game_feel(t: SmokeTest, game: Game, player: PlatformerPlayer) -> void:
	# Pulo: estica e solta poeira.
	await _place(t, player, Vector2(150.0, 280.0))
	t.spawned_effects.clear()
	await t.tap(&"jump")
	t.check(await _wait_for(t, func() -> bool: return player.squash.scale.y > 1.05),
			"Pulo estica o personagem (stretch)")
	t.check("dust_puff" in t.spawned_effects, "Pulo solta poeira")
	await t.frames(80)

	# Aterrissagem de uma queda alta: achata proporcional ao impacto.
	await _place(t, player, Vector2(150.0, 100.0))
	for i in 120:
		await t.frames(1)
		if player.is_on_floor():
			break
	t.spawned_effects.clear()
	t.check(await _wait_for(t, func() -> bool: return player.squash.scale.x > 1.05),
			"Aterrissagem achata o personagem (squash)")
	t.check("dust_puff" in t.spawned_effects, "Aterrissagem solta poeira")
	await t.frames(30)

	# Golpe acertando: hitstop + faíscas + flash no alvo.
	var dummy := game.find_child("TrainingDummy", true, false) as Node2D
	var dummy_flash := dummy.get_node("HitFlash") as HitFlashComponent
	await _place(t, player, dummy.global_position + Vector2(-16.0, 0.0))
	player.face(1.0)
	t.spawned_effects.clear()
	var hitstops_before := t.hitstop_count
	await t.tap(&"attack")
	for i in 6:
		await t.frames(1)
		if t.hitstop_count > hitstops_before:
			break
	t.check(t.hitstop_count > hitstops_before, "Golpe que acerta causa hitstop")
	t.check(dummy_flash.get_amount() > 0.5, "Alvo pisca branco ao levar o golpe")
	await t.frames(3)
	t.check("hit_sparks" in t.spawned_effects, "Golpe que acerta solta faíscas")
	await t.frames(30)


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
	var hurtbox := player.get_node("Hurtbox") as HurtboxComponent
	t.check(not hurtbox.is_physics_processing(), "Hurtbox dorme sem contato (performance)")
	var spikes := game.find_child("Spikes", true, false) as Node2D
	await _place(t, player, spikes.global_position + Vector2(0.0, -2.0))
	t.check(player.health.current < health_before, "Espinhos causam dano")
	t.check(hurtbox.is_physics_processing(), "Hurtbox acorda ao entrar em contato")
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


## Espera até `condition` ficar verdadeira (no máximo `max_frames`). Eventos
## disparados por input podem cair 1-2 frames depois; checar num frame exato
## deixa o teste intermitente.
func _wait_for(t: SmokeTest, condition: Callable, max_frames: int = 8) -> bool:
	for i in max_frames:
		await t.frames(1)
		if condition.call():
			return true
	return false
