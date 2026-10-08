class_name SettingsMenu
extends Control
## Tela de opções reutilizável: instancie como overlay (menu principal ou pausa)
## e escute `closed`. Ela mesma se libera ao fechar.

signal closed

const LOCALES: Array[String] = ["", "en", "pt_BR"]
const LOCALE_NAMES: Array[String] = ["UI_AUTO", "English", "Português (BR)"]
const TOUCH_MODES: Array[String] = ["auto", "always", "never"]
const TOUCH_MODE_NAMES: Array[String] = ["UI_AUTO", "UI_ALWAYS", "UI_NEVER"]
const CONTROLS_MENU := preload("res://ui/controls_menu/controls_menu.tscn")

@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _fullscreen_label: Label = %FullscreenLabel
@onready var _fullscreen_check: CheckButton = %FullscreenCheck
@onready var _vsync_label: Label = %VsyncLabel
@onready var _vsync_check: CheckButton = %VsyncCheck
@onready var _shake_check: CheckButton = %ShakeCheck
@onready var _language_option: OptionButton = %LanguageOption
@onready var _touch_option: OptionButton = %TouchOption
@onready var _controls_button: Button = %ControlsButton
@onready var _back_button: Button = %BackButton
@onready var _center: Control = $Center


func _ready() -> void:
	_bind_slider(_master_slider, "Master")
	_bind_slider(_music_slider, "Music")
	_bind_slider(_sfx_slider, "SFX")

	# Tela cheia / VSync só fazem sentido em desktop.
	var desktop := PlatformUtils.is_desktop()
	for control: Control in [_fullscreen_label, _fullscreen_check, _vsync_label, _vsync_check]:
		control.visible = desktop
	_bind_check(_fullscreen_check, "video", "fullscreen")
	_bind_check(_vsync_check, "video", "vsync")
	_bind_check(_shake_check, "game", "screen_shake")

	_bind_option(_language_option, "locale", LOCALES, LOCALE_NAMES)
	_bind_option(_touch_option, "touch_controls", TOUCH_MODES, TOUCH_MODE_NAMES)

	_controls_button.pressed.connect(_open_controls)
	_back_button.pressed.connect(close)
	_master_slider.grab_focus()


func _open_controls() -> void:
	var menu: ControlsMenu = CONTROLS_MENU.instantiate()
	menu.closed.connect(func() -> void:
		_center.show()
		_controls_button.grab_focus()
	)
	# Esconde o painel de trás para a navegação por gamepad não "vazar" para ele.
	_center.hide()
	add_child(menu)


func close() -> void:
	Settings.save()
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _bind_slider(slider: HSlider, bus: String) -> void:
	slider.value = float(Settings.get_value("audio", bus))
	slider.value_changed.connect(func(value: float) -> void: Settings.set_value("audio", bus, value))


func _bind_check(check: CheckButton, section: String, key: String) -> void:
	check.button_pressed = bool(Settings.get_value(section, key))
	check.toggled.connect(func(on: bool) -> void: Settings.set_value(section, key, on))


func _bind_option(option: OptionButton, key: String, values: Array[String], labels: Array[String]) -> void:
	for label: String in labels:
		option.add_item(label)
	option.selected = maxi(values.find(str(Settings.get_value("game", key))), 0)
	option.item_selected.connect(func(index: int) -> void: Settings.set_value("game", key, values[index]))
