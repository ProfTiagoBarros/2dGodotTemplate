class_name GameHUD
extends CanvasLayer
## HUD: só observa eventos (EventBus) e nunca referencia o Player diretamente.
## As dicas de botão são definidas pela fase (Level.hud_hint_actions).

const HINT_FONT_SIZE := 10
const TOAST_DURATION := 2.5

var _toast_tween: Tween

@onready var _health_bar: ProgressBar = %HealthBar
@onready var _hints: VBoxContainer = %Hints
@onready var _toast: Label = %Toast


func _ready() -> void:
	_toast.hide()
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.toast_requested.connect(show_toast)
	EventBus.ability_unlocked.connect(_on_ability_unlocked)


func set_hint_actions(actions: Array[StringName]) -> void:
	for child: Node in _hints.get_children():
		child.queue_free()
	for action: StringName in actions:
		var hint := ActionPromptLabel.new()
		hint.name = "%sHint" % String(action).to_pascal_case()
		hint.action = action
		hint.add_theme_font_size_override(&"font_size", HINT_FONT_SIZE)
		_hints.add_child(hint)


func get_hint_actions() -> Array[StringName]:
	var actions: Array[StringName] = []
	for child: Node in _hints.get_children():
		if child is ActionPromptLabel and not child.is_queued_for_deletion():
			actions.append((child as ActionPromptLabel).action)
	return actions


## Mensagem curta no topo da tela (ex.: "Pulo duplo desbloqueado!").
func show_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	_toast.show()
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(TOAST_DURATION)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(_toast.hide)


## Nome traduzível: chave "ABILITY_<NOME>" (ex.: ABILITY_DOUBLE_JUMP).
func _on_ability_unlocked(ability: StringName) -> void:
	show_toast(tr("ABILITY_UNLOCKED") % tr("ABILITY_" + String(ability).to_upper()))


func _on_player_health_changed(current: int, max_health: int) -> void:
	_health_bar.max_value = max_health
	var tween := create_tween()
	tween.tween_property(_health_bar, "value", float(current), 0.15)
