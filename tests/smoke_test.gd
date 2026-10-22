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

const TEST_SLOT := 98

## Nomes das cenas de efeito (OneShotEffect) criadas desde o último clear().
var spawned_effects: Array[String] = []
## Quantos hitstops começaram desde o último reset.
var hitstop_count := 0

var _failures := 0
var _checks := 0


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	GameFeel.hitstop_started.connect(func(_duration: float) -> void: hitstop_count += 1)

	_test_save_system()
	# Slot de teste: autosaves (ex.: AbilityPickup) não tocam o save real do jogador.
	SaveSystem.new_game(TEST_SLOT)
	await _test_input_bindings()
	await _test_debug_tools()
	await _test_game_feel()
	_test_security()
	await _test_review_regressions()
	_test_constants()

	var suites_run := 0
	for path: String in GENRE_SUITES:
		if not ResourceLoader.exists(path):
			continue
		print("\n== %s ==" % path.get_file().get_basename())
		var script := load(path) as GDScript
		# Suíte com erro de compilação deve FALHAR, não travar o runner (CI).
		if script == null or not script.can_instantiate():
			check(false, "Suíte compila: %s" % path)
			continue
		var suite: Object = script.new()
		await suite.call(&"run", self)
		release_all_actions()
		suites_run += 1
	check(suites_run > 0, "Ao menos um módulo de gênero presente")
	SaveSystem.delete_save(TEST_SLOT)

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

	InputBindings.rebind(Actions.PAUSE, kb, key_event(KEY_F10))
	check(InputMap.event_is_action(key_event(KEY_F10), Actions.PAUSE), "Remapear: nova tecla dispara a ação")
	check(not InputMap.event_is_action(key_event(KEY_ESCAPE), Actions.PAUSE), "Remapear: tecla antiga deixa de disparar")
	check(Settings.get_value(Settings.INPUT, Actions.PAUSE) is Array, "Remapeamento persistido no settings.cfg")
	check(InputBindings.get_event_label(key_event(KEY_F10)) == "F10", "Nome legível da tecla")

	# Conflito: F10 vai para `interact`, e `pause` recebe a tecla antiga de interact (E).
	InputBindings.rebind(Actions.INTERACT, kb, key_event(KEY_F10))
	check(InputMap.event_is_action(key_event(KEY_F10), Actions.INTERACT)
			and not InputMap.event_is_action(key_event(KEY_F10), Actions.PAUSE), "Conflito: tecla sai da outra ação")
	check(InputMap.event_is_action(key_event(KEY_E), Actions.PAUSE), "Conflito: a outra ação recebe a tecla antiga (troca)")

	# Mouse: só o mouse real dispara; clique emulado pelo toque é ignorado.
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputBindings.rebind(Actions.INTERACT, kb, click)
	check(InputMap.event_is_action(mouse_event(InputEvent.DEVICE_ID_MOUSE), Actions.INTERACT), "Clique do mouse real dispara a ação")
	check(not InputMap.event_is_action(mouse_event(InputEvent.DEVICE_ID_EMULATION), Actions.INTERACT),
			"Clique emulado pelo toque não dispara a ação")

	var shoulder := InputEventJoypadButton.new()
	shoulder.button_index = JOY_BUTTON_RIGHT_SHOULDER
	InputBindings.rebind(Actions.PAUSE, pad, shoulder)
	check(InputBindings.get_event_label(InputBindings.get_binding(Actions.PAUSE, pad)) == "RB", "Nome do botão do controle")

	# "Reinício": apaga do InputMap e reaplica o que está salvo.
	InputMap.action_erase_events(Actions.INTERACT)
	InputBindings.reload_saved()
	check(InputMap.event_is_action(mouse_event(InputEvent.DEVICE_ID_MOUSE), Actions.INTERACT), "Atalhos salvos voltam ao reiniciar")

	# Tela de Controles: captura a próxima tecla para a ação escolhida.
	var menu: ControlsMenu = preload("res://ui/controls_menu/controls_menu.tscn").instantiate()
	add_child(menu)
	await frames(2)
	menu.call(&"_start_listening", Actions.PAUSE, kb)
	Input.parse_input_event(key_event(KEY_F9))
	# Eventos de parse_input_event são entregues no frame de PROCESSO (não de física).
	for i in 3:
		await get_tree().process_frame
	check(InputMap.event_is_action(key_event(KEY_F9), Actions.PAUSE), "Tela de Controles captura a tecla pressionada")
	menu.close()
	await frames(1)

	InputBindings.reset_all()
	check(InputMap.event_is_action(key_event(KEY_ESCAPE), Actions.PAUSE)
			and Settings.get_value(Settings.INPUT, Actions.PAUSE) == null, "Restaurar padrões")
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
	var health := get_tree().get_first_node_in_group(Groups.PLAYER).get(&"health") as HealthComponent
	DebugTools.execute("god")
	check(health.god_mode and not health.take_damage(1), "god: player não leva dano")
	DebugTools.execute("god")
	check(not health.god_mode, "god de novo desliga")
	DebugTools.execute("tp 123 45")
	var player := get_tree().get_first_node_in_group(Groups.PLAYER) as Node2D
	check(player.global_position.is_equal_approx(Vector2(123, 45)), "tp teleporta o player")
	check(ScenePaths.FIRST_LEVEL.get_file().get_basename() in DebugTools.execute("level"), "level lista as fases")
	check("não encontrada" in DebugTools.execute("level fase_inexistente"), "level avisa fase inexistente")
	await despawn(game)


func _test_game_feel() -> void:
	print("\n== game_feel ==")
	var hitstop_setting: Variant = Settings.get_value(Settings.GAME, Settings.HITSTOP)

	# Hitstop: desacelera e restaura sozinho (tempo real).
	Settings.set_value(Settings.GAME, Settings.HITSTOP, true)
	GameFeel.hitstop(0.1)
	check(GameFeel.is_hitstop_active() and Engine.time_scale < 0.2, "Hitstop desacelera o jogo")
	await real_seconds(0.2)
	check(not GameFeel.is_hitstop_active() and is_equal_approx(Engine.time_scale, 1.0), "Hitstop restaura o time_scale")
	Settings.set_value(Settings.GAME, Settings.HITSTOP, false)
	GameFeel.hitstop(0.1)
	check(is_equal_approx(Engine.time_scale, 1.0), "Opção 'Pausa de Impacto' desligada ignora o hitstop")
	Settings.set_value(Settings.GAME, Settings.HITSTOP, hitstop_setting)

	# Squash & stretch: conserva a área e volta ao normal.
	var squash := SquashStretch.new()
	add_child(squash)
	squash.stretch_vertical(1.3)
	check(squash.scale.y > 1.25 and is_equal_approx(squash.scale.x * squash.scale.y, 1.0),
			"Squash & stretch conserva a área (sx·sy = 1)")
	await real_seconds(0.3)
	check(squash.scale.is_equal_approx(Vector2.ONE), "Squash volta ao normal")
	squash.queue_free()

	# Hit flash: material no alvo, filhos herdam, pisca e apaga.
	var target := Node2D.new()
	var body := Polygon2D.new()
	target.add_child(body)
	add_child(target)
	var flash := HitFlashComponent.new()
	flash.target = target
	add_child(flash)
	check(target.material is ShaderMaterial and body.use_parent_material, "Hit flash aplica o shader no visual")
	flash.flash()
	check(is_equal_approx(flash.get_amount(), 1.0), "Hit flash acende no frame do impacto")
	await real_seconds(0.25)
	check(is_zero_approx(flash.get_amount()), "Hit flash apaga sozinho")
	target.queue_free()
	flash.queue_free()

	# Efeitos de partícula: surgem na cena e se liberam sozinhos.
	var effect := GameFeel.spawn_effect(GameFeel.DUST, Vector2(10.0, 10.0))
	check(effect is OneShotEffect and effect.is_inside_tree(), "Efeito de partícula surge na cena")
	await real_seconds(0.7)
	check(not is_instance_valid(effect), "Efeito se libera ao terminar")


func _test_security() -> void:
	print("\n== security ==")
	# settings.cfg adulterado: ConfigFile criaria objetos e rodaria scripts.
	var evil := '[game]\nlocale=Object(RefCounted,"script":Resource("res://tests/smoke_test.gd"))\n'
	check(SafeConfig.parse(evil) == null, "Config com Object(...)/Resource(...) é recusada")
	check(SafeConfig.parse('[game]\nx = ExtResource ("1")\n') == null, "Variações com espaço também são recusadas")
	var valid := SafeConfig.parse('[audio]\nMusic=0.5\n[game]\nlocale="pt_BR"\n')
	check(valid != null and is_equal_approx(float(valid.get_value("audio", "Music")), 0.5), "Config válida carrega normalmente")
	check(Settings.is_valid_value(Settings.AUDIO, "Music", 1) and not Settings.is_valid_value(Settings.VIDEO, Settings.FULLSCREEN, "sim")
			and not Settings.is_valid_value(Settings.GAME, "chave_desconhecida", true), "Settings só aceita chaves conhecidas com o tipo certo")

	# Save adulterado/corrompido: tipos errados não podem derrubar o jogo.
	var slot := TEST_SLOT + 1
	var path := "%s/slot_%d.json" % [SaveSystem.SAVE_DIR, slot]
	_write_text(path, '{"version": 1, "data": [1, 2, 3]}')
	check(not SaveSystem.load_game(slot), "Save com 'data' de tipo errado é recusado")
	_write_text(path, '{"version": 1, "data": {"deaths": "muitas"}}')
	check(SaveSystem.load_game(slot) and SaveSystem.get_int("deaths") == 0, "Campo numérico adulterado vira o padrão")
	SaveSystem.delete_save(slot)
	SaveSystem.new_game(TEST_SLOT)


## Regressões dos bugs encontrados na revisão de arquitetura (cada um foi
## reproduzido antes da correção).
func _test_review_regressions() -> void:
	print("\n== review_regressions ==")

	# Pausa coordenada: fechar o console não pode despausar com o menu aberto.
	var game := await spawn_game(ScenePaths.FIRST_LEVEL)
	var pause_menu := game.get_node("PauseMenu")
	DebugTools.open_console()
	pause_menu.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	DebugTools.close_console()
	check(get_tree().paused and (pause_menu.get_node("%Root") as Control).visible,
			"Fechar o console mantém o jogo pausado se o menu de pausa abriu")
	pause_menu.call(&"set_paused", false)
	check(not get_tree().paused, "Fechar o menu de pausa despausa (nenhum outro motivo)")
	await despawn(game)
	check(not PauseController.is_paused(), "Cena destruída não deixa motivo de pausa preso")

	# TouchButton removido com o dedo na tela solta a ação.
	var button := TouchButton.new()
	button.action = Actions.INTERACT
	add_child(button)
	await get_tree().process_frame
	button.set("_finger", 0)
	button.call("_send", true)
	button.queue_free()
	for i in 3:
		await get_tree().process_frame
	check(not Input.is_action_pressed(Actions.INTERACT), "TouchButton removido não deixa a ação presa")

	# StateMachine: transição antes de inicializar não quebra; vira o estado inicial.
	var machine := StateMachine.new()
	var idle := State.new()
	idle.name = "Idle"
	var hurt := State.new()
	hurt.name = "Hurt"
	machine.add_child(idle)
	machine.add_child(hurt)
	machine.initial_state = idle
	machine.transition_to(&"Hurt")
	add_child(machine)
	await get_tree().process_frame
	check(machine.current_state == hurt, "StateMachine aceita transição antes de inicializar")
	machine.queue_free()

	# HitFlash preserva o shader próprio de um filho.
	var target := Node2D.new()
	var plain := Polygon2D.new()
	var custom := Polygon2D.new()
	var own_material := ShaderMaterial.new()
	custom.material = own_material
	target.add_child(plain)
	target.add_child(custom)
	add_child(target)
	var flash := HitFlashComponent.new()
	flash.target = target
	add_child(flash)
	check(plain.use_parent_material and custom.material == own_material and not custom.use_parent_material,
			"HitFlash não sobrescreve material próprio dos filhos")
	target.queue_free()
	flash.queue_free()

	# Crossfade: A -> B -> A em sequência rápida termina tocando A.
	var a := _test_stream()
	var b := _test_stream()
	AudioManager.play_music(a, 0.5)
	await real_seconds(0.1)
	AudioManager.play_music(b, 0.5)
	await real_seconds(0.1)
	AudioManager.play_music(a, 0.5)
	await real_seconds(0.9)
	var music_ok := false
	for player: AudioStreamPlayer in AudioManager.get("_music_players"):
		music_ok = music_ok or (player.stream == a and player.playing)
	check(music_ok, "Crossfade rápido A→B→A termina tocando A")
	AudioManager.stop_music(0.0)

	# Save com 'version' adulterada não quebra a migração.
	var slot := TEST_SLOT + 2
	_write_text("%s/slot_%d.json" % [SaveSystem.SAVE_DIR, slot], '{"version": [1], "data": {}}')
	check(SaveSystem.load_game(slot), "Save com 'version' adulterada carrega sem erro")
	SaveSystem.delete_save(slot)

	# Migração v1 -> v2: "platformer_abilities" vira PlayerCharacter.ABILITIES_SAVE_KEY.
	_write_text("%s/slot_%d.json" % [SaveSystem.SAVE_DIR, slot],
			'{"version": 1, "data": {"platformer_abilities": ["dash"]}}')
	SaveSystem.load_game(slot)
	var migrated: Variant = SaveSystem.data.get(PlayerCharacter.ABILITIES_SAVE_KEY)
	check(migrated is Array and "dash" in migrated and not SaveSystem.data.has("platformer_abilities"),
			"Migração v1→v2 move as habilidades para a chave nova")
	SaveSystem.delete_save(slot)
	SaveSystem.new_game(TEST_SLOT)


## Actions/Groups são a única fonte dos nomes: garante que não divergem do
## InputMap nem das listas que dependem deles.
func _test_constants() -> void:
	print("
== constants ==")
	var undeclared: Array[StringName] = []
	for action: StringName in InputMap.get_actions():
		if not String(action).begins_with("ui_") and action not in Actions.ALL:
			undeclared.append(action)
	check(undeclared.is_empty(), "Toda ação do InputMap está em Actions.ALL %s" % [undeclared])
	var unique := {}
	for action: StringName in Actions.ALL:
		unique[action] = true
	check(unique.size() == Actions.ALL.size(), "Actions.ALL sem duplicatas")
	var remappable_ok := true
	for action: StringName in InputBindings.REMAPPABLE:
		remappable_ok = remappable_ok and action in Actions.ALL
	check(remappable_ok, "InputBindings.REMAPPABLE só usa ações de Actions.ALL")


## Stream curto e real (onda quadrada) para testar o AudioManager.
func _test_stream() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 8000
	var bytes := PackedByteArray()
	bytes.resize(8000 * 3)
	for i in bytes.size():
		bytes[i] = 100 if (i / 20) % 2 == 0 else 156
	wav.data = bytes
	return wav


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func real_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _on_node_added(node: Node) -> void:
	if node is OneShotEffect:
		spawned_effects.append(node.scene_file_path.get_file().get_basename())


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
