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
	player.global_position = spikes.global_position + Vector2(0.0, -2.0)
	player.velocity = Vector2.ZERO
	await t.frames(5)
	t.check(player.health.current < health_before, "Espinhos causam dano")

	await t.despawn(game)
