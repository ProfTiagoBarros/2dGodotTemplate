extends Node
## Detecta o dispositivo de entrada ativo (teclado/mouse, gamepad ou toque).
##
## Use para mostrar/ocultar controles de toque, trocar dicas de botões
## ("Pressione A" vs "Pressione Espaço") e decidir a fonte da mira.

signal device_changed(device: Device)

enum Device { KEYBOARD_MOUSE, GAMEPAD, TOUCH }

const JOY_AXIS_THRESHOLD := 0.5
## Deslocamento mínimo do mouse (px) para considerá-lo "em uso" (ignora tremidas).
const MOUSE_MOTION_THRESHOLD := 4.0

var current_device := Device.KEYBOARD_MOUSE
## true depois que o jogador mexeu/clicou o mouse de verdade; volta a false ao
## usar gamepad ou toque. Jogadores só de teclado nunca ativam a mira por mouse.
var using_mouse := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	current_device = _default_device()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func is_touch() -> bool:
	return current_device == Device.TOUCH


func is_gamepad() -> bool:
	return current_device == Device.GAMEPAD


func _input(event: InputEvent) -> void:
	var detected := _detect_device(event)
	if detected != -1 and detected != current_device:
		_set_device(detected as Device)


func _detect_device(event: InputEvent) -> int:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		return Device.TOUCH
	if event is InputEventJoypadButton:
		return Device.GAMEPAD
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return Device.GAMEPAD if absf(motion.axis_value) > JOY_AXIS_THRESHOLD else -1
	if event is InputEventKey:
		return Device.KEYBOARD_MOUSE
	# Ignora eventos de mouse emulados a partir do toque.
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return -1
	if event is InputEventMouseButton:
		using_mouse = true
		return Device.KEYBOARD_MOUSE
	if event is InputEventMouseMotion:
		if (event as InputEventMouseMotion).relative.length() >= MOUSE_MOTION_THRESHOLD:
			using_mouse = true
			return Device.KEYBOARD_MOUSE
	return -1


func _set_device(device: Device) -> void:
	current_device = device
	if device != Device.KEYBOARD_MOUSE:
		using_mouse = false
	device_changed.emit(device)


func _default_device() -> Device:
	return Device.TOUCH if PlatformUtils.is_touch_primary() else Device.KEYBOARD_MOUSE


func _on_joy_connection_changed(_device_id: int, connected: bool) -> void:
	if not connected and current_device == Device.GAMEPAD and Input.get_connected_joypads().is_empty():
		_set_device(_default_device())
