class_name TouchControls
extends CanvasLayer
## Exibe os controles de toque conforme a opção do usuário
## ("auto" = só quando o último input foi toque). As ações dos botões
## A/B são definidas pela fase via `configure()`, então a mesma UI
## serve para platformer (pular/interagir) e top-down (atacar/dash).

@onready var _primary_button: TouchButton = %PrimaryButton
@onready var _secondary_button: TouchButton = %SecondaryButton


func _ready() -> void:
	InputManager.device_changed.connect(_refresh.unbind(1))
	Settings.changed.connect(_on_settings_changed)
	_refresh()


func configure(primary_action: StringName, secondary_action: StringName) -> void:
	_primary_button.action = primary_action
	_secondary_button.action = secondary_action
	_secondary_button.visible = not secondary_action.is_empty()


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
