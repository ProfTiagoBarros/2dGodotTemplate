extends Node
## Remapeamento de controles (teclado/mouse e gamepad) com persistência.
##
## Os padrões são os do InputMap (Project Settings > Input Map). As mudanças do
## jogador ficam em user://settings.cfg, seção [input], e são reaplicadas ao iniciar.
##
## Cada ação tem um atalho PRINCIPAL por tipo de dispositivo: o primeiro evento
## daquele tipo na lista da ação. É ele que a tela de Controles mostra e troca.
## Os demais (ex.: setas, D-pad) continuam funcionando como alternativos.
##
## Dicas na tela: InputBindings.get_prompt(&"attack") -> "J" / "X" / "Square"...

signal bindings_changed

enum Kind { KEYBOARD_MOUSE, GAMEPAD }
enum PadFamily { XBOX, PLAYSTATION, NINTENDO }

const SETTINGS_SECTION := "input"

## Ações exibidas na tela de Controles (em ordem) -> chave de tradução do nome.
## Ações inexistentes no InputMap (ex.: removidas pelo setup de gênero) são puladas.
const REMAPPABLE := {
	&"move_up": "INPUT_MOVE_UP",
	&"move_down": "INPUT_MOVE_DOWN",
	&"move_left": "INPUT_MOVE_LEFT",
	&"move_right": "INPUT_MOVE_RIGHT",
	&"jump": "INPUT_JUMP",
	&"attack": "INPUT_ATTACK",
	&"dash": "INPUT_DASH",
	&"interact": "INPUT_INTERACT",
	&"pause": "INPUT_PAUSE",
}

const MOUSE_BUTTON_KEYS := {
	MOUSE_BUTTON_LEFT: "INPUT_MOUSE_LEFT",
	MOUSE_BUTTON_RIGHT: "INPUT_MOUSE_RIGHT",
	MOUSE_BUTTON_MIDDLE: "INPUT_MOUSE_MIDDLE",
	MOUSE_BUTTON_WHEEL_UP: "INPUT_MOUSE_WHEEL_UP",
	MOUSE_BUTTON_WHEEL_DOWN: "INPUT_MOUSE_WHEEL_DOWN",
	MOUSE_BUTTON_XBUTTON1: "INPUT_MOUSE_X1",
	MOUSE_BUTTON_XBUTTON2: "INPUT_MOUSE_X2",
}

## Nomes dos botões por família (índices de JoyButton 0..14, layout SDL).
const PAD_BUTTONS := {
	PadFamily.XBOX: ["A", "B", "X", "Y", "View", "Guide", "Menu", "LS", "RS", "LB", "RB",
			"D-pad Up", "D-pad Down", "D-pad Left", "D-pad Right"],
	PadFamily.PLAYSTATION: ["Cross", "Circle", "Square", "Triangle", "Share", "PS", "Options",
			"L3", "R3", "L1", "R1", "D-pad Up", "D-pad Down", "D-pad Left", "D-pad Right"],
	PadFamily.NINTENDO: ["B", "A", "Y", "X", "-", "Home", "+", "LS", "RS", "L", "R",
			"D-pad Up", "D-pad Down", "D-pad Left", "D-pad Right"],
}
const PAD_TRIGGERS := {
	PadFamily.XBOX: ["LT", "RT"],
	PadFamily.PLAYSTATION: ["L2", "R2"],
	PadFamily.NINTENDO: ["ZL", "ZR"],
}

var _defaults: Dictionary[StringName, Array] = {}


func _ready() -> void:
	for action: StringName in InputMap.get_actions():
		if not String(action).begins_with("ui_"):
			_defaults[action] = InputMap.action_get_events(action)
	_apply_saved()


#region Consulta

func get_remappable_actions() -> Array[StringName]:
	var result: Array[StringName] = []
	for action: StringName in REMAPPABLE:
		if InputMap.has_action(action):
			result.append(action)
	return result


## Chave de tradução do nome da ação (Labels/Buttons traduzem sozinhos).
func get_action_name_key(action: StringName) -> String:
	return REMAPPABLE.get(action, String(action))


func get_action_name(action: StringName) -> String:
	return tr(get_action_name_key(action))


## Atalho principal de `action` para o tipo de dispositivo (ou null).
func get_binding(action: StringName, kind: Kind) -> InputEvent:
	for event: InputEvent in InputMap.action_get_events(action):
		if kind_of(event) == kind:
			return event
	return null


## Texto do atalho de `action` no dispositivo atual (para dicas na tela).
func get_prompt(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	var kind := Kind.GAMEPAD if InputManager.is_gamepad() else Kind.KEYBOARD_MOUSE
	return get_event_label(get_binding(action, kind))


static func kind_of(event: InputEvent) -> int:
	if event is InputEventKey or event is InputEventMouseButton:
		return Kind.KEYBOARD_MOUSE
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return Kind.GAMEPAD
	return -1

#endregion


#region Remapeamento

## Troca o atalho principal de `action`. Se outra ação já usava o novo atalho,
## ela recebe o atalho antigo (troca), para nenhuma ação ficar sem tecla.
func rebind(action: StringName, kind: Kind, event: InputEvent) -> void:
	var new_event := _normalized(event)
	if new_event == null or kind_of(new_event) != kind:
		Log.warn("InputBindings: evento incompatível com o tipo de dispositivo.")
		return
	var old_event := get_binding(action, kind)
	if old_event != null and old_event.is_match(new_event):
		return

	for other: StringName in get_remappable_actions():
		if other == action:
			continue
		for existing: InputEvent in InputMap.action_get_events(other):
			if existing.is_match(new_event):
				_replace_event(other, existing, old_event)
				_persist(other)
				break

	_replace_event(action, old_event, new_event)
	_persist(action)
	Settings.save()
	bindings_changed.emit()


func reset_all() -> void:
	for action: StringName in _defaults:
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		for event: InputEvent in _defaults[action]:
			InputMap.action_add_event(action, event)
		Settings.erase_value(SETTINGS_SECTION, action)
	Settings.save()
	bindings_changed.emit()


## Cópia dos atalhos atuais (para "cancelar alterações" ou isolar testes).
func get_snapshot() -> Dictionary:
	var snapshot := {}
	for action: StringName in _defaults:
		if InputMap.has_action(action):
			snapshot[action] = InputMap.action_get_events(action)
	return snapshot


func apply_snapshot(snapshot: Dictionary) -> void:
	for action: StringName in snapshot:
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		for event: InputEvent in snapshot[action]:
			InputMap.action_add_event(action, event)
		_persist(action)
	Settings.save()
	bindings_changed.emit()


## Reaplica o que está salvo no settings.cfg por cima do InputMap atual.
func reload_saved() -> void:
	_apply_saved()
	bindings_changed.emit()


func _replace_event(action: StringName, old_event: InputEvent, new_event: InputEvent) -> void:
	var events := InputMap.action_get_events(action)
	var index := events.find(old_event) if old_event != null else -1
	if index >= 0:
		if new_event != null:
			events[index] = new_event
		else:
			events.remove_at(index)
	elif new_event != null:
		events.append(new_event)
	InputMap.action_erase_events(action)
	for event: InputEvent in events:
		InputMap.action_add_event(action, event)

#endregion


#region Persistência

func _persist(action: StringName) -> void:
	var events := InputMap.action_get_events(action)
	if _same_events(events, _defaults.get(action, [])):
		Settings.erase_value(SETTINGS_SECTION, action)
	else:
		Settings.set_value(SETTINGS_SECTION, action, events.map(_serialize))


func _apply_saved() -> void:
	for action: StringName in _defaults:
		var saved: Variant = Settings.get_value(SETTINGS_SECTION, action)
		if not saved is Array:
			continue
		var events: Array[InputEvent] = []
		for data: Variant in saved:
			var event := _deserialize(data)
			if event != null:
				events.append(event)
		if events.is_empty():
			continue
		InputMap.action_erase_events(action)
		for event: InputEvent in events:
			InputMap.action_add_event(action, event)


func _same_events(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		var left := a[i] as InputEvent
		var right := b[i] as InputEvent
		if not left.is_match(right) or left.device != right.device:
			return false
	return true


## Formato legível e estável no settings.cfg (não depende de serializar Objects).
static func _serialize(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var key := event as InputEventKey
		return {"type": "key", "physical_keycode": key.physical_keycode, "keycode": key.keycode}
	if event is InputEventMouseButton:
		return {"type": "mouse_button", "button_index": (event as InputEventMouseButton).button_index}
	if event is InputEventJoypadButton:
		return {"type": "joy_button", "button_index": (event as InputEventJoypadButton).button_index}
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return {"type": "joy_motion", "axis": motion.axis, "axis_value": signf(motion.axis_value)}
	return {}


static func _deserialize(data: Variant) -> InputEvent:
	if not data is Dictionary:
		return null
	var dict := data as Dictionary
	match str(dict.get("type", "")):
		"key":
			var key := InputEventKey.new()
			key.device = -1
			key.physical_keycode = int(dict.get("physical_keycode", KEY_NONE)) as Key
			if key.physical_keycode == KEY_NONE:
				key.keycode = int(dict.get("keycode", KEY_NONE)) as Key
			return key
		"mouse_button":
			# Só o mouse REAL: ignora cliques emulados pelo toque (DEVICE_ID_EMULATION).
			var mouse := InputEventMouseButton.new()
			mouse.device = InputEvent.DEVICE_ID_MOUSE
			mouse.button_index = int(dict.get("button_index", MOUSE_BUTTON_LEFT)) as MouseButton
			return mouse
		"joy_button":
			var button := InputEventJoypadButton.new()
			button.device = -1
			button.button_index = int(dict.get("button_index", 0)) as JoyButton
			return button
		"joy_motion":
			var motion := InputEventJoypadMotion.new()
			motion.device = -1
			motion.axis = int(dict.get("axis", 0)) as JoyAxis
			motion.axis_value = signf(float(dict.get("axis_value", 1.0)))
			return motion
	return null


## Cópia "limpa" do evento capturado: sem modificadores, sem estado, device correto.
static func _normalized(event: InputEvent) -> InputEvent:
	return _deserialize(_serialize(event))

#endregion


#region Nomes para exibição

func get_event_label(event: InputEvent) -> String:
	if event == null:
		return tr("INPUT_UNBOUND")
	if event is InputEventKey:
		var key := event as InputEventKey
		var keycode := key.keycode
		if key.physical_keycode != KEY_NONE:
			keycode = key.physical_keycode
			# Mostra a tecla no layout do jogador (ABNT2, AZERTY...).
			if DisplayServer.get_name() != "headless":
				var localized := DisplayServer.keyboard_get_keycode_from_physical(key.physical_keycode)
				if localized != KEY_NONE:
					keycode = localized
		return OS.get_keycode_string(keycode)
	if event is InputEventMouseButton:
		return tr(MOUSE_BUTTON_KEYS.get((event as InputEventMouseButton).button_index, "INPUT_MOUSE_BUTTON"))
	if event is InputEventJoypadButton:
		var index := (event as InputEventJoypadButton).button_index as int
		var names: Array = PAD_BUTTONS[get_pad_family()]
		return str(names[index]) if index >= 0 and index < names.size() else "Button %d" % index
	if event is InputEventJoypadMotion:
		return _axis_label(event as InputEventJoypadMotion)
	return "?"


func get_pad_family() -> PadFamily:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		return PadFamily.XBOX
	var pad_name := Input.get_joy_name(pads[0]).to_lower()
	for hint: String in ["playstation", "dualshock", "dualsense", "ps3", "ps4", "ps5", "sony"]:
		if hint in pad_name:
			return PadFamily.PLAYSTATION
	for hint: String in ["nintendo", "switch", "joy-con", "pro controller"]:
		if hint in pad_name:
			return PadFamily.NINTENDO
	return PadFamily.XBOX


func _axis_label(motion: InputEventJoypadMotion) -> String:
	var negative := motion.axis_value < 0.0
	match motion.axis:
		JOY_AXIS_LEFT_X:
			return "L-Stick Left" if negative else "L-Stick Right"
		JOY_AXIS_LEFT_Y:
			return "L-Stick Up" if negative else "L-Stick Down"
		JOY_AXIS_RIGHT_X:
			return "R-Stick Left" if negative else "R-Stick Right"
		JOY_AXIS_RIGHT_Y:
			return "R-Stick Up" if negative else "R-Stick Down"
		JOY_AXIS_TRIGGER_LEFT:
			return str(PAD_TRIGGERS[get_pad_family()][0])
		JOY_AXIS_TRIGGER_RIGHT:
			return str(PAD_TRIGGERS[get_pad_family()][1])
	return "Axis %d" % motion.axis

#endregion
