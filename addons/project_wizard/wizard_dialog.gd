@tool
extends ConfirmationDialog
## Janela do assistente: faz as perguntas sobre o jogo, mostra a prévia do que
## vai mudar e aplica com tools/project_setup.gd.

const ProjectSetup := preload("res://tools/project_setup.gd")

var _name_edit: LineEdit
var _genre_option: OptionButton
var _platform_checks := {}
var _game_docs_check: CheckBox
var _english_check: CheckBox
var _community_check: CheckBox
var _remove_tools_check: CheckBox
var _plan_label: Label
## git_state() consultado ao abrir a janela (não a cada tecla).
var _git_state := ""


func _init() -> void:
	title = "Configurar novo jogo"
	ok_button_text = "Configurar"
	cancel_button_text = "Agora não"
	min_size = Vector2i(640, 560)
	confirmed.connect(_on_confirmed)
	_build()


## Relê o estado do projeto (gêneros disponíveis) e reseta as respostas.
func refresh() -> void:
	var defaults := ProjectSetup.default_options()
	_git_state = ProjectSetup.git_state()
	var current_name := str(ProjectSettings.get_setting("application/config/name", ""))
	_name_edit.text = current_name if current_name != ProjectSetup.TEMPLATE_NAME else ""
	_genre_option.clear()
	for genre: String in ProjectSetup.GenreSetup.available_genres():
		_genre_option.add_item(str(ProjectSetup.GENRE_LABELS.get(genre, genre)))
		_genre_option.set_item_metadata(_genre_option.item_count - 1, genre)
	for platform: String in _platform_checks:
		(_platform_checks[platform] as CheckBox).button_pressed = platform in defaults[ProjectSetup.OPT_PLATFORMS]
	_game_docs_check.button_pressed = defaults[ProjectSetup.OPT_GAME_DOCS]
	_english_check.button_pressed = defaults[ProjectSetup.OPT_ENGLISH_DOCS]
	_community_check.button_pressed = defaults[ProjectSetup.OPT_COMMUNITY]
	_remove_tools_check.button_pressed = defaults[ProjectSetup.OPT_REMOVE_TOOLS]
	_update_plan()


func _build() -> void:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override(&"separation", 8)
	scroll.add_child(box)

	_add_text(box, "Responda as perguntas abaixo. O assistente deixa o template no formato do seu jogo, "
			+ "removendo o que não será usado (menos código para manter e menos contexto para a IA ler).")

	_add_title(box, "1. Qual o nome do jogo?")
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Ex.: Aventura do Gato"
	_name_edit.text_changed.connect(_update_plan.unbind(1))
	box.add_child(_name_edit)

	_add_title(box, "2. Que tipo de jogo?")
	_add_text(box, "Platformer: plataforma/metroidvania. Top-down: visão de cima (zelda-like, twin-stick). "
			+ "Só a base: outros gêneros (puzzle, cartas, narrativo…); mantém menus, save, controles e CI.")
	_genre_option = OptionButton.new()
	_genre_option.item_selected.connect(_update_plan.unbind(1))
	box.add_child(_genre_option)

	_add_title(box, "3. Para quais plataformas?")
	var row := HBoxContainer.new()
	box.add_child(row)
	for platform: String in [ProjectSetup.PLATFORM_PC, ProjectSetup.PLATFORM_WEB, ProjectSetup.PLATFORM_MOBILE]:
		var check := CheckBox.new()
		check.text = {ProjectSetup.PLATFORM_PC: "PC (Windows/Linux)", ProjectSetup.PLATFORM_WEB: "Web",
				ProjectSetup.PLATFORM_MOBILE: "Celular (Android)"}[platform]
		check.toggled.connect(_update_plan.unbind(1))
		row.add_child(check)
		_platform_checks[platform] = check

	_add_title(box, "4. Documentação")
	_game_docs_check = _add_check(box, "Este repositório vai ser um JOGO (README do jogo, CLAUDE.md enxuto)",
			"Desmarque só se você estiver criando outro template.")
	_english_check = _add_check(box, "Manter as docs em inglês (*.en.md)", "")
	_community_check = _add_check(box, "Manter arquivos de comunidade (projeto open source com contribuidores)",
			"CONTRIBUTING, SECURITY, modelos de issue/PR e CODEOWNERS.")

	_add_title(box, "5. Ao final")
	_remove_tools_check = _add_check(box, "Remover as ferramentas de setup (tools/ e este assistente)",
			"Depois de configurado, elas não têm mais uso.")

	_add_title(box, "O que vai acontecer")
	_plan_label = Label.new()
	_plan_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_plan_label)


func _options() -> Dictionary:
	var platforms: Array = []
	for platform: String in _platform_checks:
		if (_platform_checks[platform] as CheckBox).button_pressed:
			platforms.append(platform)
	var genre := ""
	if _genre_option.selected != -1:
		genre = str(_genre_option.get_item_metadata(_genre_option.selected))
	return {
		ProjectSetup.OPT_NAME: _name_edit.text,
		ProjectSetup.OPT_GENRE: genre,
		ProjectSetup.OPT_PLATFORMS: platforms,
		ProjectSetup.OPT_GAME_DOCS: _game_docs_check.button_pressed,
		ProjectSetup.OPT_ENGLISH_DOCS: _english_check.button_pressed,
		ProjectSetup.OPT_COMMUNITY: _community_check.button_pressed,
		ProjectSetup.OPT_REMOVE_TOOLS: _remove_tools_check.button_pressed,
	}


func _update_plan() -> void:
	if _plan_label == null or _genre_option.item_count == 0:
		return
	_english_check.disabled = not _game_docs_check.button_pressed
	_community_check.disabled = not _game_docs_check.button_pressed
	var options := _options()
	var problem := ProjectSetup.validate(options)
	get_ok_button().disabled = not problem.is_empty()
	if not problem.is_empty():
		_plan_label.text = problem
		return
	_plan_label.text = "\n".join(ProjectSetup.plan(options, _git_state))


func _on_confirmed() -> void:
	var options := _options()
	var err := ProjectSetup.apply(options)
	var result := AcceptDialog.new()
	result.title = "Configurar novo jogo"
	if err == OK:
		result.dialog_text = "Pronto! O editor vai reiniciar para recarregar o projeto.\nDepois, aperte F5 para testar e faça um commit."
		result.confirmed.connect(EditorInterface.restart_editor.bind(false))
		result.canceled.connect(EditorInterface.restart_editor.bind(false))
	else:
		result.dialog_text = "Não foi possível concluir (%s). Veja o painel Output.\nSe o projeto estava no Git, desfaça com: git checkout -- . && git clean -fd" % error_string(err)
	EditorInterface.get_base_control().add_child(result)
	result.popup_centered()


func _add_title(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", 16)
	parent.add_child(label)


func _add_text(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = Color(1, 1, 1, 0.75)
	parent.add_child(label)


func _add_check(parent: Control, text: String, hint: String) -> CheckBox:
	var check := CheckBox.new()
	check.text = text
	check.tooltip_text = hint
	check.toggled.connect(_update_plan.unbind(1))
	parent.add_child(check)
	return check
