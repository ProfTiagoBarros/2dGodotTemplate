class_name ActionPromptLabel
extends Label
## Mostra "<ação> [atalho]" com o atalho do dispositivo atual, atualizando
## ao trocar de dispositivo, remapear ou mudar o idioma. Some no toque e
## quando a ação não existe no projeto (ex.: `jump` num jogo top-down).

@export var action: StringName


func _ready() -> void:
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	InputManager.device_changed.connect(_refresh.unbind(1))
	InputBindings.bindings_changed.connect(_refresh)
	Input.joy_connection_changed.connect(_refresh.unbind(2))
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh()


func _refresh() -> void:
	visible = InputMap.has_action(action) and not InputManager.is_touch()
	if visible:
		text = "%s [%s]" % [InputBindings.get_action_name(action), InputBindings.get_prompt(action)]
