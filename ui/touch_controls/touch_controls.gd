class_name TouchControls
extends CanvasLayer
## Exibe os controles de toque conforme a opção do usuário
## ("auto" = só quando o último input foi toque). As ações dos botões
## A/B/C são definidas pela fase via `configure()`, então a mesma UI
## serve para platformer (pular/atacar/dash) e top-down (atacar/dash).

@onready var _action_buttons: Array[TouchButton] = [%PrimaryButton, %SecondaryButton, %TertiaryButton]


func _ready() -> void:
	InputManager.device_changed.connect(_refresh.unbind(1))
	Settings.changed.connect(_on_settings_changed)
	_refresh()


## Atribui as ações aos botões A, B, C; botões sem ação (ou com ação
## inexistente no InputMap) ficam escondidos.
func configure(actions: Array[StringName]) -> void:
	for i in _action_buttons.size():
		var button := _action_buttons[i]
		var action: StringName = actions[i] if i < actions.size() else &""
		button.action = action
		button.visible = not action.is_empty() and InputMap.has_action(action)


func _refresh() -> void:
	match str(Settings.get_value("game", "touch_controls")):
		"always":
			visible = true
		"never":
			visible = false
		_:
			visible = InputManager.is_touch()


func _on_settings_changed(section: String, key: String, _value: Variant) -> void:
	if section == "game" and key == "touch_controls":
		_refresh()
