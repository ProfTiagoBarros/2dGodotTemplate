class_name SmokeTest
extends Node
## Smoke test headless. Roda os testes gerais (save) e as suítes de cada
## módulo de gênero que existir no projeto. Sai com código != 0 em falha.
##
##   godot --headless --path . res://tests/smoke_test.tscn
##
## Suítes de gênero ficam DENTRO do módulo (game/<gênero>/tests/), então
## apagar um módulo no setup apaga junto os testes dele.

const GAME_SCENE := preload("res://game/game.tscn")
const GENRE_SUITES: Array[String] = [
	"res://game/platformer/tests/platformer_smoke_test.gd",
	"res://game/topdown/tests/topdown_smoke_test.gd",
]

var _failures := 0
var _checks := 0


func _ready() -> void:
	_test_save_system()
	await _test_input_bindings()
	await _test_debug_tools()

	var suites_run := 0
	for path: String in GENRE_SUITES:
		if not ResourceLoader.exists(path):
			continue
		print("\n== %s ==" % path.get_file().get_basename())
		var suite: Object = (load(path) as GDScript).new()
		await suite.call(&"run", self)
		release_all_actions()
		suites_run += 1
	check(suites_run > 0, "Ao menos um módulo de gênero presente")

	print("\nSmoke test: %s (%d verificações)" % [
		"PASSOU" if _failures == 0 else "%d FALHA(S)" % _failures, _checks])
	get_tree().quit(1 if _failures > 0 else 0)


## Instancia game.tscn com a fase indicada e espera a física assentar.
func spawn_game(level_path: String) -> Game:
	var game: Game = GAME_SCENE.instantiate()
	game.level_path = level_path
	add_child(game)
	await frames(30)
	return game


func despawn(game: Game) -> void:
	game.queue_free()
	await frames(2)


func check(condition: bool, description: String) -> void:
	_checks += 1
	print(("  [OK]   " if condition else "  [FAIL] ") + description)
	if not condition:
		_failures += 1


func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


## Simula um toque rápido numa ação (pressiona por 1 frame de física).
func tap(action: StringName) -> void:
	Input.action_press(action)
	await frames(1)
	Input.action_release(action)


func hold(action: StringName, frame_count: int) -> void:
	Input.action_press(action)
	await frames(frame_count)
	Input.action_release(action)


func release_all_actions() -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)


func _test_input_bindings() -> void:
	print("\n== input_bindings ==")
	# Isola o teste: guarda os atalhos do jogador e restaura no final.
	var snapshot := InputBindings.get_snapshot()
	InputBindings.reset_all()
	var kb := InputBindings.Kind.KEYBOARD_MOUSE
	var pad := InputBindings.Kind.GAMEPAD

	InputBindings.rebind(&"pause", kb, key_event(KEY_F10))
	check(InputMap.event_is_action(key_event(KEY_F10), &"pause"), "Remapear: nova tecla dispara a ação")
	check(not InputMap.event_is_action(key_event(KEY_ESCAPE), &"pause"), "Remapear: tecla antiga deixa de disparar")
	check(Settings.get_value("input", "pause") is Array, "Remapeamento persistido no settings.cfg")
	check(InputBindings.get_event_label(key_event(KEY_F10)) == "F10", "Nome legível da tecla")

	# Conflito: F10 vai para `interact`, e `pause` recebe a tecla antiga de interact (E).
	InputBindings.rebind(&"interact", kb, key_event(KEY_F10))
	check(InputMap.event_is_action(key_event(KEY_F10), &"interact")
			and not InputMap.event_is_action(key_event(KEY_F10), &"pause"), "Conflito: tecla sai da outra ação")
	check(InputMap.event_is_action(key_event(KEY_E), &"pause"), "Conflito: a outra ação recebe a tecla antiga (troca)")

	# Mouse: só o mouse real dispara; clique emulado pelo toque é ignorado.
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputBindings.rebind(&"interact", kb, click)
	check(InputMap.event_is_action(mouse_event(InputEvent.DEVICE_ID_MOUSE), &"interact"), "Clique do mouse real dispara a ação")
	check(not InputMap.event_is_action(mouse_event(InputEvent.DEVICE_ID_EMULATION), &"interact"),
			"Clique emulado pelo toque não dispara a ação")

	var shoulder := InputEventJoypadButton.new()
	shoulder.button_index = JOY_BUTTON_RIGHT_SHOULDER
	InputBindings.rebind(&"pause", pad, shoulder)
	check(InputBindings.get_event_label(InputBindings.get_binding(&"pause", pad)) == "RB", "Nome do botão do controle")

	# "Reinício": apaga do InputMap e reaplica o que está salvo.
	InputMap.action_erase_events(&"interact")
	InputBindings.reload_saved()
	check(InputMap.event_is_action(mouse_event(InputEvent.DEVICE_ID_MOUSE), &"interact"), "Atalhos salvos voltam ao reiniciar")

	# Tela de Controles: captura a próxima tecla para a ação escolhida.
	var menu: ControlsMenu = preload("res://ui/controls_menu/controls_menu.tscn").instantiate()
	add_child(menu)
	await frames(2)
	menu.call(&"_start_listening", &"pause", kb)
	Input.parse_input_event(key_event(KEY_F9))
	# Eventos de parse_input_event são entregues no frame de PROCESSO (não de física).
	for i in 3:
		await get_tree().process_frame
	check(InputMap.event_is_action(key_event(KEY_F9), &"pause"), "Tela de Controles captura a tecla pressionada")
	menu.close()
	await frames(1)

	InputBindings.reset_all()
	check(InputMap.event_is_action(key_event(KEY_ESCAPE), &"pause")
			and Settings.get_value("input", "pause") == null, "Restaurar padrões")
	InputBindings.apply_snapshot(snapshot)


func _test_debug_tools() -> void:
	print("\n== debug_tools ==")
	if not DebugTools.enabled:
		print("  (release build: DebugTools desativado, testes pulados)")
		return

	# Log + captura da saída do engine pelo console.
	Log.info("smoke-marker-info")
	push_warning("smoke-marker-warning")
	# process_frame é emitido ANTES dos _process: espere alguns frames para o DebugTools drenar.
	for i in 3:
		await get_tree().process_frame
	var console_text := DebugTools.get_console_text()
	check("INFO: smoke-marker-info" in console_text, "Console captura o Log")
	check("AVISO: smoke-marker-warning" in console_text, "Console captura avisos do engine")
	var previous_level := Log.min_level
	Log.min_level = Log.LogLevel.WARN
	Log.info("smoke-marker-filtered")
	for i in 3:
		await get_tree().process_frame
	check(not "smoke-marker-filtered" in DebugTools.get_console_text(), "Log filtra abaixo do nível mínimo")
	Log.min_level = previous_level

	# Comandos genéricos.
	check("god" in DebugTools.execute("help"), "help lista também os comandos do jogo")
	check("desconhecido" in DebugTools.execute("comando_que_nao_existe"), "Comando desconhecido é avisado")
	DebugTools.execute("timescale 0.5")
	check(is_equal_approx(Engine.time_scale, 0.5), "timescale altera Engine.time_scale")
	DebugTools.execute("timescale 1")

	# Teclas: F3 (overlay) e F1 (console, que pausa o jogo).
	var game := await spawn_game(ScenePaths.FIRST_LEVEL)
	Input.parse_input_event(key_event(KEY_F3))
	for i in 20:
		await get_tree().process_frame
	check(DebugTools.is_overlay_visible(), "F3 abre o overlay")
	var overlay_text := ((DebugTools.get("_overlay") as Node).find_child("StatsLabel") as Label).text
	check("FPS" in overlay_text and "Vida:" in overlay_text and "Estado:" in overlay_text,
			"Overlay mostra métricas e watches do jogo")
	DebugTools.toggle_overlay()

	Input.parse_input_event(key_event(KEY_F1))
	await get_tree().process_frame
	await get_tree().process_frame
	check(DebugTools.is_console_open() and get_tree().paused, "F1 abre o console e pausa o jogo")
	DebugTools.submit_console("fps 30")
	check(Engine.max_fps == 30 and "> fps 30" in DebugTools.get_console_text(), "Console executa o que é digitado")
	DebugTools.execute("fps 0")
	DebugTools.close_console()
	check(not get_tree().paused, "Fechar o console despausa")

	# Comandos de gameplay (genéricos entre gêneros).
	var health := get_tree().get_first_node_in_group(&"player").get(&"health") as HealthComponent
	DebugTools.execute("god")
	check(health.god_mode and not health.take_damage(1), "god: player não leva dano")
	DebugTools.execute("god")
	check(not health.god_mode, "god de novo desliga")
	DebugTools.execute("tp 123 45")
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	check(player.global_position.is_equal_approx(Vector2(123, 45)), "tp teleporta o player")
	check(ScenePaths.FIRST_LEVEL.get_file().get_basename() in DebugTools.execute("level"), "level lista as fases")
	check("não encontrada" in DebugTools.execute("level fase_inexistente"), "level avisa fase inexistente")
	await despawn(game)


func key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = true
	return event


func mouse_event(device: int) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.device = device
	return event


func _test_save_system() -> void:
	print("== save_system ==")
	SaveSystem.data = {"smoke": 42}
	check(SaveSystem.save_game(99), "Save grava o slot")
	SaveSystem.data = {}
	check(SaveSystem.load_game(99), "Save carrega o slot")
	check(int(SaveSystem.data.get("smoke", 0)) == 42, "Dados do save preservados")
	SaveSystem.delete_save(99)
