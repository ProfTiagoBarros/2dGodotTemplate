extends RefCounted
## Lógica do setup de gênero, compartilhada pelo EditorScript (setup_genre.gd),
## pela linha de comando (setup_genre_cli.gd) e pelo assistente de projeto
## (project_setup.gd). Sem dependência de autoloads (roda em modo `-s`).
##
## O que faz:
##   1. Aponta ScenePaths.FIRST_LEVEL para a fase do gênero escolhido.
##   2. Move os módulos dos outros gêneros para a LIXEIRA do sistema (recuperável).
##   3. Remove do InputMap as ações que só os outros gêneros usam.
##   4. Tira do CLAUDE.md os trechos dos outros gêneros (<!-- genre:x -->), para
##      o assistente de IA não gastar contexto com código que não existe mais.
##
## BASE = nenhum módulo: apaga todos e cria uma fase vazia em game/levels/.

const SCENE_PATHS_FILE := "res://core/constants/scene_paths.gd"
const CLAUDE_FILE := "res://CLAUDE.md"

const BASE := "base"
const MODULES_TAG := "modules"
const BASE_LEVEL := "res://game/levels/level_01.tscn"
## Fase vazia da opção BASE. LEVEL_PLACEHOLDER é uma chave de tradução.
const BASE_LEVEL_SCENE := """[gd_scene format=3]

[ext_resource type="Script" path="res://game/level.gd" id="1_level"]

[node name="Level01" type="Node2D"]
script = ExtResource("1_level")
level_id = &"level_01"
touch_actions = Array[StringName]([])
hud_hint_actions = Array[StringName]([&"pause"])

[node name="Placeholder" type="Label" parent="."]
offset_left = 40.0
offset_top = 40.0
offset_right = 600.0
offset_bottom = 80.0
text = "LEVEL_PLACEHOLDER"
"""

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


## Gêneros que ainda existem no projeto (+ BASE, sempre disponível).
static func available_genres() -> PackedStringArray:
	var result := PackedStringArray()
	for genre: String in GENRES:
		if FileAccess.file_exists(GENRES[genre]["level"]):
			result.append(genre)
	result.append(BASE)
	return result


static func apply(genre: String) -> Error:
	if genre == BASE:
		return _apply_base()
	if not GENRES.has(genre):
		push_error("GenreSetup: gênero inválido '%s'. Use um de: %s, %s" % [genre, ", ".join(GENRES.keys()), BASE])
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

	strip_genre_blocks(CLAUDE_FILE, genre)
	print("GenreSetup: projeto configurado como '%s'." % genre)
	return OK


## Mantém só os blocos <!-- genre:keep -->…<!-- /genre:keep --> (sem os
## marcadores) e apaga os dos outros gêneros. keep = BASE apaga todos.
## <!-- genre:modules --> marca texto que vale para qualquer módulo (sai só no
## BASE). Blocos podem ser aninhados.
static func strip_genre_blocks(path: String, keep: String) -> Error:
	if not FileAccess.file_exists(path):
		return OK
	return write_text(path, strip_genre_text(FileAccess.get_file_as_string(path), keep))


static func strip_genre_text(text: String, keep: String) -> String:
	var regex := RegEx.create_from_string("(?s)<!-- genre:(\\w+) -->\\n?(.*?)<!-- /genre:\\1 -->\\n?")
	var result := ""
	var last := 0
	for found: RegExMatch in regex.search_all(text):
		result += text.substr(last, found.get_start() - last)
		var tag := found.get_string(1)
		var content := ""
		if tag == keep or (tag == MODULES_TAG and keep != BASE):
			content = strip_genre_text(found.get_string(2), keep)
		result += content
		# Bloco no meio de uma linha: preserva a quebra de linha que o fechava.
		var inline := found.get_start() > 0 and text[found.get_start() - 1] != "\n"
		if found.get_string().ends_with("\n") and not content.ends_with("\n") and (inline or not content.is_empty()):
			result += "\n"
		last = found.get_end()
	return result + text.substr(last)


static func _apply_base() -> Error:
	DirAccess.make_dir_recursive_absolute(BASE_LEVEL.get_base_dir())
	if not FileAccess.file_exists(BASE_LEVEL):
		var err := write_text(BASE_LEVEL, BASE_LEVEL_SCENE)
		if err != OK:
			return err
	var err := _set_first_level(BASE_LEVEL)
	if err != OK:
		return err
	for genre: String in GENRES:
		_trash_module(genre)
	strip_genre_blocks(CLAUDE_FILE, BASE)
	print("GenreSetup: projeto configurado só com a base (fase vazia em %s)." % BASE_LEVEL)
	return OK


static func _set_first_level(level_path: String) -> Error:
	var source := FileAccess.get_file_as_string(SCENE_PATHS_FILE)
	var regex := RegEx.create_from_string('const FIRST_LEVEL := "[^"]*"')
	if regex.search(source) == null:
		push_error("GenreSetup: constante FIRST_LEVEL não encontrada em %s" % SCENE_PATHS_FILE)
		return ERR_PARSE_ERROR
	return write_text(SCENE_PATHS_FILE, regex.sub(source, 'const FIRST_LEVEL := "%s"' % level_path))


static func _trash_module(genre: String) -> void:
	var dir := "res://game/%s" % genre
	if not DirAccess.dir_exists_absolute(dir):
		return
	var err := OS.move_to_trash(ProjectSettings.globalize_path(dir))
	if err == OK:
		print("GenreSetup: '%s' movido para a lixeira." % dir)
	else:
		push_warning("GenreSetup: não foi possível remover %s (%s). Apague manualmente." % [dir, error_string(err)])


static func write_text(path: String, text: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	return OK
