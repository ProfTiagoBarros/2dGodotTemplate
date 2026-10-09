extends Node
## Ferramentas de desenvolvimento. Só existem em DEBUG BUILDS (editor e exports
## debug); em release este autoload não faz nada e nada é carregado.
##
##   F3 ............ overlay de performance + "watches"
##   F1 ou ` ....... console de comandos (pausa o jogo enquanto aberto)
##   3 dedos ....... abre o console no celular
##
## Cada sistema registra seus próprios comandos/watches (o core não conhece o jogo):
##   DebugTools.register_command("gold", _cmd_gold, "gold <n> - define o ouro")
##   DebugTools.watch("Inimigos", func() -> String: return str(enemies.size()))
## Arquivos em COMMAND_PROVIDERS são carregados automaticamente se existirem.

signal command_executed(line: String, output: String)

const OVERLAY_SCENE := "res://ui/debug/debug_overlay.tscn"
const CONSOLE_SCENE := "res://ui/debug/debug_console.tscn"
## Scripts com `func register() -> void` que registram comandos/watches do jogo.
const COMMAND_PROVIDERS: Array[String] = ["res://game/game_debug_commands.gd"]

var enabled := OS.is_debug_build()

var _commands: Dictionary[String, Dictionary] = {}
var _watches: Dictionary[String, Callable] = {}
var _providers: Array[Object] = []
var _logger: ConsoleLogger
var _overlay: DebugOverlay
var _console: DebugConsole
var _paused_before_console := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not enabled:
		set_process(false)
		set_process_input(false)
		return

	_logger = ConsoleLogger.new()
	OS.add_logger(_logger)

	_overlay = (load(OVERLAY_SCENE) as PackedScene).instantiate()
	add_child(_overlay)
	_console = (load(CONSOLE_SCENE) as PackedScene).instantiate()
	add_child(_console)

	_register_core_commands()
	for path: String in COMMAND_PROVIDERS:
		if ResourceLoader.exists(path):
			var provider: Object = (load(path) as GDScript).new()
			provider.call(&"register")
			_providers.append(provider)


func _exit_tree() -> void:
	if _logger != null:
		OS.remove_logger(_logger)


func _process(_delta: float) -> void:
	for entry: Dictionary in _logger.drain():
		_console.print_line(entry["text"], entry["color"])


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match (event as InputEventKey).physical_keycode:
			KEY_F3:
				toggle_overlay()
			KEY_F1, KEY_QUOTELEFT:
				toggle_console()
			KEY_ESCAPE:
				if not is_console_open():
					return
				close_console()
			_:
				return
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.is_pressed() and (event as InputEventScreenTouch).index == 2:
		toggle_console()
		get_viewport().set_input_as_handled()


#region API

func register_command(command_name: String, callable: Callable, help: String = "") -> void:
	_commands[command_name.to_lower()] = {"callable": callable, "help": help}


func unregister_command(command_name: String) -> void:
	_commands.erase(command_name.to_lower())


func get_command_names() -> Array[String]:
	var names: Array[String] = []
	names.assign(_commands.keys())
	names.sort()
	return names


## Executa uma linha ("comando arg1 arg2") e devolve a saída em texto.
## Callables recebem `args: PackedStringArray` e devolvem String.
func execute(line: String) -> String:
	var parts := line.strip_edges().split(" ", false)
	if parts.is_empty():
		return ""
	var command_name := parts[0].to_lower()
	if not _commands.has(command_name):
		return "Comando desconhecido: '%s'. Digite help." % command_name
	var callable: Callable = _commands[command_name]["callable"]
	var output := str(callable.call(parts.slice(1)))
	command_executed.emit(line, output)
	return output


## Valor exibido no overlay F3, reavaliado a cada atualização.
func watch(label: String, getter: Callable) -> void:
	_watches[label] = getter


func unwatch(label: String) -> void:
	_watches.erase(label)


func get_watch_lines() -> Array[String]:
	var lines: Array[String] = []
	for label: String in _watches:
		var getter := _watches[label]
		if getter.is_valid():
			var value := str(getter.call())
			if not value.is_empty():
				lines.append("%s: %s" % [label, value])
	return lines


func toggle_overlay() -> void:
	if enabled:
		_overlay.visible = not _overlay.visible


func is_overlay_visible() -> bool:
	return enabled and _overlay.visible


func is_console_open() -> bool:
	return enabled and _console.visible


func toggle_console() -> void:
	if is_console_open():
		close_console()
	else:
		open_console()


func open_console() -> void:
	if not enabled or is_console_open():
		return
	_paused_before_console = get_tree().paused
	get_tree().paused = true
	_console.open()


func close_console() -> void:
	if not is_console_open():
		return
	_console.close()
	get_tree().paused = _paused_before_console


func print_console(text: String, color: Color = Color.WHITE) -> void:
	if enabled:
		_console.print_line(text, color)


## Executa como se o jogador tivesse digitado no console (eco + saída visíveis).
func submit_console(line: String) -> void:
	if enabled:
		_console.submit(line)


## Texto puro do console (útil em testes e para anexar a relatórios de bug).
func get_console_text() -> String:
	return _console.get_text() if enabled else ""

#endregion


#region Comandos genéricos (não dependem do jogo)

func _register_core_commands() -> void:
	register_command("help", _cmd_help, "help [comando] - lista os comandos")
	register_command("clear", _cmd_clear, "clear - limpa o console")
	register_command("overlay", _cmd_overlay, "overlay - mostra/esconde o overlay (F3)")
	register_command("fps", _cmd_fps, "fps <n> - limita o FPS (0 = sem limite)")
	register_command("timescale", _cmd_timescale, "timescale <x> - câmera lenta/acelerada (1 = normal)")
	register_command("collisions", _cmd_collisions, "collisions - mostra formas de colisão (recarrega a cena)")
	register_command("log", _cmd_log, "log <debug|info|warn|error> - nível mínimo do Log")
	register_command("lang", _cmd_lang, "lang <en|pt_BR|auto> - troca o idioma")
	register_command("quit", _cmd_quit, "quit - fecha o jogo")


func _cmd_help(args: PackedStringArray) -> String:
	if not args.is_empty():
		var info: Dictionary = _commands.get(args[0].to_lower(), {})
		return str(info.get("help", "Comando desconhecido: %s" % args[0]))
	var lines: Array[String] = ["Comandos (Tab completa, ↑/↓ histórico, Esc fecha):"]
	for command_name: String in get_command_names():
		lines.append("  " + str(_commands[command_name]["help"]))
	return "\n".join(lines)


func _cmd_clear(_args: PackedStringArray) -> String:
	_console.clear()
	return ""


func _cmd_overlay(_args: PackedStringArray) -> String:
	toggle_overlay()
	return "Overlay %s" % ("ligado" if is_overlay_visible() else "desligado")


func _cmd_fps(args: PackedStringArray) -> String:
	if not args.is_empty():
		Engine.max_fps = maxi(args[0].to_int(), 0)
	return "max_fps = %d" % Engine.max_fps


func _cmd_timescale(args: PackedStringArray) -> String:
	if not args.is_empty():
		Engine.time_scale = clampf(args[0].to_float(), 0.0, 10.0)
	return "time_scale = %.2f" % Engine.time_scale


func _cmd_collisions(_args: PackedStringArray) -> String:
	var tree := get_tree()
	tree.debug_collisions_hint = not tree.debug_collisions_hint
	close_console()
	SceneLoader.reload_current_scene(0.0)
	return "Colisões %s" % ("visíveis" if tree.debug_collisions_hint else "ocultas")


func _cmd_log(args: PackedStringArray) -> String:
	if not args.is_empty():
		var level := Log.level_from_name(args[0])
		if level == -1:
			return "Nível inválido. Use: debug, info, warn, error."
		Log.min_level = level as Log.LogLevel
	return "Log.min_level = %s" % Log.LEVEL_NAMES[Log.min_level]


func _cmd_lang(args: PackedStringArray) -> String:
	if not args.is_empty():
		Settings.set_value("game", "locale", "" if args[0] == "auto" else args[0], true)
	return "Idioma: %s" % TranslationServer.get_locale()


func _cmd_quit(_args: PackedStringArray) -> String:
	get_tree().quit()
	return ""

#endregion
