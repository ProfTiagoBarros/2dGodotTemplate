extends CanvasLayer
## HUD: só observa eventos (EventBus) e nunca referencia o Player diretamente.

@onready var _health_bar: ProgressBar = %HealthBar


func _ready() -> void:
	EventBus.player_health_changed.connect(_on_player_health_changed)


func _on_player_health_changed(current: int, max_health: int) -> void:
	_health_bar.max_value = max_health
	var tween := create_tween()
	tween.tween_property(_health_bar, "value", float(current), 0.15)
