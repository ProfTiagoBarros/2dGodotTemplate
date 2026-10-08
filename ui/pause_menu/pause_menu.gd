extends CanvasLayer
## Menu de pausa. Também pausa automaticamente quando o app perde foco
## ou vai para segundo plano (essencial em mobile) e trata o "voltar" do Android.

const SETTINGS_MENU := preload("res://ui/settings_menu/settings_menu.tscn")

var _settings_menu: SettingsMenu

@onready var _root: Control = %Root
@onready var _menu_box: Control = %MenuBox
@onready var _resume_button: Button = %ResumeButton
@onready var _settings_button: Button = %SettingsButton
@onready var _main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	_root.hide()
	_resume_button.pressed.connect(set_paused.bind(false))
	_settings_button.pressed.connect(_open_settings)
	_main_menu_button.pressed.connect(_go_to_main_menu)


func set_paused(paused: bool) -> void:
	if _settings_menu != null:
		return
	get_tree().paused = paused
	_root.visible = paused
	EventBus.game_paused.emit(paused)
	if paused:
		_resume_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _settings_menu == null and event.is_action_pressed(&"pause"):
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if not is_node_ready() or SceneLoader.is_changing:
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			set_paused(true)
		NOTIFICATION_WM_GO_BACK_REQUEST:
			set_paused(not get_tree().paused)


func _open_settings() -> void:
	_settings_menu = SETTINGS_MENU.instantiate()
	_settings_menu.closed.connect(_on_settings_closed)
	_menu_box.hide()
	add_child(_settings_menu)


func _on_settings_closed() -> void:
	_settings_menu = null
	_menu_box.show()
	_settings_button.grab_focus()


func _go_to_main_menu() -> void:
	SceneLoader.change_scene(ScenePaths.MAIN_MENU)
