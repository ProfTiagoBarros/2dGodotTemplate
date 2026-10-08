extends Control

const SETTINGS_MENU := preload("res://ui/settings_menu/settings_menu.tscn")

@onready var _play_button: Button = %PlayButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _version_label: Label = %VersionLabel


func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_quit)
	_quit_button.visible = PlatformUtils.can_quit()
	# Versão vem de application/config/version (o CI preenche a partir da tag git).
	_version_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_version_label.text = "v%s%s" % [
		ProjectSettings.get_setting("application/config/version", "0.0.0"),
		"" if OS.has_feature("template") else "-dev",
	]
	# Foco inicial é essencial para navegação por gamepad/teclado.
	_play_button.grab_focus()


func _notification(what: int) -> void:
	# Botão "voltar" do Android no menu principal fecha o app.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_quit()


func _on_play_pressed() -> void:
	if not SaveSystem.load_game():
		SaveSystem.new_game()
	SceneLoader.change_scene(ScenePaths.GAME)


func _on_settings_pressed() -> void:
	var menu: SettingsMenu = SETTINGS_MENU.instantiate()
	menu.closed.connect(_settings_button.grab_focus)
	add_child(menu)


func _quit() -> void:
	get_tree().quit()
