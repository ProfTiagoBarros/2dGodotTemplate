class_name ControlsMenu
extends Control
## Tela de remapeamento: uma linha por ação, colunas Teclado/Mouse e Controle.
## Clique (ou confirme no gamepad) num atalho e pressione o novo; Esc cancela.
## Overlay que se libera sozinho ao fechar (emite `closed`).

signal closed

const BUTTON_SIZE := Vector2(120, 22)

var _listening_action := &""
var _listening_kind := -1
var _buttons: Dictionary[String, Button] = {}

@onready var _grid: GridContainer = %Grid
@onready var _listen_label: Label = %ListenLabel
@onready var _reset_button: Button = %ResetButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_build_rows()
	_listen_label.hide()
	_reset_button.pressed.connect(InputBindings.reset_all)
	_back_button.pressed.connect(close)
	InputBindings.bindings_changed.connect(_refresh_labels)
	Input.joy_connection_changed.connect(_refresh_labels.unbind(2))

	var first := _grid.find_child("*Button*", true, false) as Button
	if first != null:
		first.grab_focus()


func close() -> void:
	_stop_listening()
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if _listening_kind == -1:
		return
	# Enquanto escuta, nenhum input chega ao resto da UI/jogo.
	get_viewport().set_input_as_handled()

	if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_ESCAPE:
		if event.is_pressed():
			_stop_listening()
		return
	if _accepts(event):
		var action := _listening_action
		var kind := _listening_kind as InputBindings.Kind
		_stop_listening()
		InputBindings.rebind(action, kind, event)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _accepts(event: InputEvent) -> bool:
	if _listening_kind == InputBindings.Kind.KEYBOARD_MOUSE:
		if event is InputEventKey:
			return event.is_pressed() and not event.is_echo()
		if event is InputEventMouseButton:
			return event.is_pressed() and event.device != InputEvent.DEVICE_ID_EMULATION
	else:
		if event is InputEventJoypadButton:
			return event.is_pressed()
		if event is InputEventJoypadMotion:
			return absf((event as InputEventJoypadMotion).axis_value) >= 0.6
	return false


func _build_rows() -> void:
	for header: String in ["", "UI_KEYBOARD_MOUSE", "UI_GAMEPAD"]:
		var label := Label.new()
		label.text = header
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override(&"font_color", Color(1, 1, 1, 0.6))
		_grid.add_child(label)

	for action: StringName in InputBindings.get_remappable_actions():
		var name_label := Label.new()
		name_label.text = InputBindings.get_action_name_key(action)
		_grid.add_child(name_label)
		for kind: InputBindings.Kind in [InputBindings.Kind.KEYBOARD_MOUSE, InputBindings.Kind.GAMEPAD]:
			var button := Button.new()
			button.name = "%sButton%d" % [action, kind]
			button.custom_minimum_size = BUTTON_SIZE
			button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			button.clip_text = true
			button.pressed.connect(_start_listening.bind(action, kind))
			_grid.add_child(button)
			_buttons[_key(action, kind)] = button
	_refresh_labels()


func _refresh_labels() -> void:
	for action: StringName in InputBindings.get_remappable_actions():
		for kind: InputBindings.Kind in [InputBindings.Kind.KEYBOARD_MOUSE, InputBindings.Kind.GAMEPAD]:
			var button: Button = _buttons.get(_key(action, kind))
			if button != null:
				button.text = InputBindings.get_event_label(InputBindings.get_binding(action, kind))


func _start_listening(action: StringName, kind: InputBindings.Kind) -> void:
	_stop_listening()
	_listening_action = action
	_listening_kind = kind
	_buttons[_key(action, kind)].text = "..."
	_listen_label.text = "UI_PRESS_KEY" if kind == InputBindings.Kind.KEYBOARD_MOUSE else "UI_PRESS_BUTTON"
	_listen_label.show()


func _stop_listening() -> void:
	if _listening_kind == -1:
		return
	var button: Button = _buttons.get(_key(_listening_action, _listening_kind))
	_listening_action = &""
	_listening_kind = -1
	_listen_label.hide()
	_refresh_labels()
	if button != null:
		button.grab_focus()


func _key(action: StringName, kind: int) -> String:
	return "%s:%d" % [action, kind]
