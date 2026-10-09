extends RefCounted
## Lógica do setup de gênero, compartilhada pelo EditorScript (setup_genre.gd)
## e pela linha de comando (setup_genre_cli.gd). Sem dependência de autoloads.
##
## O que faz:
##   1. Aponta ScenePaths.FIRST_LEVEL para a fase do gênero escolhido.
##   2. Move os módulos dos outros gêneros para a LIXEIRA do sistema (recuperável).
##   3. Remove do InputMap as ações que só os outros gêneros usam.

const SCENE_PATHS_FILE := "res://core/constants/scene_paths.gd"

const GENRES := {
	"platformer": {
		"level": "res://game/platformer/levels/platformer_level_01.tscn",
		"unused_actions": ["aim_left", "aim_right", "aim_up", "aim_down"],
	},
	"topdown": {
		"level": "res://game/topdown/levels/topdown_level_01.tscn",
		"unused_actions": ["jump"],
	},
}


static func apply(genre: String) -> Error:
	if not GENRES.has(genre):
		push_error("GenreSetup: gênero inválido '%s'. Use um de: %s" % [genre, ", ".join(GENRES.keys())])
		return ERR_INVALID_PARAMETER
	var config: Dictionary = GENRES[genre]
	var level_path: String = config["level"]
	if not FileAccess.file_exists(level_path):
		push_error("GenreSetup: módulo '%s' não existe mais neste projeto." % genre)
		return ERR_FILE_NOT_FOUND

	var err := _set_first_level(level_path)
	if err != OK:
		return err

	for other: String in GENRES:
		if other != genre:
			_trash_module(other)

	for action: String in config["unused_actions"]:
		var key := "input/" + action
		if ProjectSettings.has_setting(key):
			ProjectSettings.clear(key)
	err = ProjectSettings.save()
	if err != OK:
		push_error("GenreSetup: falha ao salvar project.godot (%s)" % error_string(err))
		return err

	print("GenreSetup: projeto configurado como '%s'." % genre)
	return OK


static func _set_first_level(level_path: String) -> Error:
	var source := FileAccess.get_file_as_string(SCENE_PATHS_FILE)
	var regex := RegEx.create_from_string('const FIRST_LEVEL := "[^"]*"')
	if regex.search(source) == null:
		push_error("GenreSetup: constante FIRST_LEVEL não encontrada em %s" % SCENE_PATHS_FILE)
		return ERR_PARSE_ERROR
	var file := FileAccess.open(SCENE_PATHS_FILE, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(regex.sub(source, 'const FIRST_LEVEL := "%s"' % level_path))
	return OK


static func _trash_module(genre: String) -> void:
	var dir := "res://game/%s" % genre
	if not DirAccess.dir_exists_absolute(dir):
		return
	var err := OS.move_to_trash(ProjectSettings.globalize_path(dir))
	if err == OK:
		print("GenreSetup: '%s' movido para a lixeira." % dir)
	else:
		push_warning("GenreSetup: não foi possível remover %s (%s). Apague manualmente." % [dir, error_string(err)])
