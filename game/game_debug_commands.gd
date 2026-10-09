extends RefCounted
## Comandos de console e watches do overlay ligados ao gameplay.
## Carregado automaticamente pelo DebugTools (só em debug builds).
## Genérico entre gêneros: acha o player pelo grupo "player" e usa duck typing
## (`health`, `state_machine`, `velocity`), então funciona em qualquer módulo.

const LEVELS_ROOT := "res://game"


func register() -> void:
	DebugTools.register_command("god", _cmd_god, "god - liga/desliga invencibilidade do player")
	DebugTools.register_command("heal", _cmd_heal, "heal [n] - cura n (ou tudo); revive se morto")
	DebugTools.register_command("kill", _cmd_kill, "kill - mata o player")
	DebugTools.register_command("tp", _cmd_tp, "tp <x> <y> - teleporta o player (sem args: até o mouse)")
	DebugTools.register_command("level", _cmd_level, "level [nome] - lista as fases ou carrega uma")
	DebugTools.register_command("reload", _cmd_reload, "reload - recarrega a cena atual")
	DebugTools.register_command("save", _cmd_save, "save [slot] - salva o jogo")
	DebugTools.register_command("load", _cmd_load, "load [slot] - carrega o save")

	DebugTools.watch("Player", _watch_player)
	DebugTools.watch("Estado", _watch_state)
	DebugTools.watch("Vida", _watch_health)


#region Helpers

func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _player() -> CharacterBody2D:
	return _tree().get_first_node_in_group(&"player") as CharacterBody2D


func _health() -> HealthComponent:
	var player := _player()
	return player.get(&"health") as HealthComponent if player != null else null


## Fases = cenas .tscn dentro de qualquer pasta "levels" em res://game.
func _find_levels(dir_path: String = LEVELS_ROOT) -> Array[String]:
	var levels: Array[String] = []
	for subdir: String in DirAccess.get_directories_at(dir_path):
		levels.append_array(_find_levels(dir_path.path_join(subdir)))
	if dir_path.get_file() == "levels":
		for file: String in DirAccess.get_files_at(dir_path):
			# Em builds exportados as cenas aparecem como "x.tscn.remap".
			file = file.trim_suffix(".remap")
			if file.ends_with(".tscn") and not levels.has(dir_path.path_join(file)):
				levels.append(dir_path.path_join(file))
	return levels

#endregion


#region Comandos

func _cmd_god(_args: PackedStringArray) -> String:
	var health := _health()
	if health == null:
		return "Nenhum player na cena."
	health.god_mode = not health.god_mode
	return "God mode %s" % ("ligado" if health.god_mode else "desligado")


func _cmd_heal(args: PackedStringArray) -> String:
	var health := _health()
	if health == null:
		return "Nenhum player na cena."
	if health.is_dead():
		health.revive()
	else:
		health.heal(args[0].to_int() if not args.is_empty() else health.max_health)
	return "Vida: %d/%d" % [health.current, health.max_health]


func _cmd_kill(_args: PackedStringArray) -> String:
	var health := _health()
	if health == null:
		return "Nenhum player na cena."
	DebugTools.close_console()
	health.kill()
	return "Player morto."


func _cmd_tp(args: PackedStringArray) -> String:
	var player := _player()
	if player == null:
		return "Nenhum player na cena."
	if args.size() >= 2:
		player.global_position = Vector2(args[0].to_float(), args[1].to_float())
	else:
		player.global_position = player.get_global_mouse_position()
	player.velocity = Vector2.ZERO
	return "Player em %s" % player.global_position.round()


func _cmd_level(args: PackedStringArray) -> String:
	var levels := _find_levels()
	if args.is_empty():
		var names: Array[String] = []
		for path: String in levels:
			names.append(path.get_file().get_basename())
		return "Fases: %s\nAtual: %s" % [", ".join(names), Game.level_override if not Game.level_override.is_empty() else "padrão"]
	for path: String in levels:
		if path.get_file().get_basename() == args[0]:
			Game.level_override = path
			DebugTools.close_console()
			SceneLoader.change_scene(ScenePaths.GAME)
			return "Carregando %s..." % args[0]
	return "Fase '%s' não encontrada. Use 'level' para listar." % args[0]


func _cmd_reload(_args: PackedStringArray) -> String:
	DebugTools.close_console()
	SceneLoader.reload_current_scene()
	return "Recarregando..."


func _cmd_save(args: PackedStringArray) -> String:
	var slot := args[0].to_int() if not args.is_empty() else SaveSystem.current_slot
	return "Salvo no slot %d." % slot if SaveSystem.save_game(slot) else "Falha ao salvar."


func _cmd_load(args: PackedStringArray) -> String:
	var slot := args[0].to_int() if not args.is_empty() else SaveSystem.current_slot
	return "Slot %d carregado: %s" % [slot, SaveSystem.data] if SaveSystem.load_game(slot) else "Sem save no slot %d." % slot

#endregion


#region Watches (overlay F3)

func _watch_player() -> String:
	var player := _player()
	if player == null:
		return ""
	return "pos %s  vel %s" % [player.global_position.round(), player.velocity.round()]


func _watch_state() -> String:
	var player := _player()
	var machine := player.get(&"state_machine") as StateMachine if player != null else null
	if machine == null or machine.current_state == null:
		return ""
	return String(machine.current_state.name)


func _watch_health() -> String:
	var health := _health()
	if health == null:
		return ""
	return "%d/%d%s" % [health.current, health.max_health, "  [GOD]" if health.god_mode else ""]

#endregion
