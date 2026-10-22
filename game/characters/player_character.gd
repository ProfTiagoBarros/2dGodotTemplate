@abstract
class_name PlayerCharacter
extends Character
## Base dos players de qualquer gênero: o que é "ser o player", independente de
## como ele se move. Liga a vida à HUD (via EventBus), entra no grupo PLAYER e
## anuncia a morte. Cada gênero estende e implementa movimento + ganchos de
## Character (apply_knockback, get_facing_vector).

## Duração do fade-out ao morrer (s).
@export var death_fade_time := 0.4


func _ready() -> void:
	super._ready()
	add_to_group(Groups.PLAYER)
	health.health_changed.connect(_on_health_changed)
	# Adiado para que a HUD (instanciada depois do player) já esteja conectada.
	_on_health_changed.call_deferred(health.current, health.max_health)


func _play_death() -> void:
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, death_fade_time)
	EventBus.player_died.emit()


func _on_health_changed(current: int, max_health: int) -> void:
	EventBus.player_health_changed.emit(current, max_health)
