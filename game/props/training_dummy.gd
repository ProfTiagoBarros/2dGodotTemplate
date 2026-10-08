class_name TrainingDummy
extends StaticBody2D
## Alvo de treino: recebe dano, reage com feedback visual e se regenera.
## Útil para calibrar ataques e como exemplo mínimo de entidade "atacável".

@export var revive_delay := 1.0

@onready var _visual: Node2D = $Visual
@onready var _health: HealthComponent = $HealthComponent


func _ready() -> void:
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_on_died)


func _on_damaged(_amount: int, _source: Node) -> void:
	_visual.modulate = Color(1.0, 0.4, 0.4)
	_visual.scale = Vector2(1.25, 0.8)
	var tween := create_tween().set_parallel()
	tween.tween_property(_visual, "modulate", Color.WHITE, 0.2)
	tween.tween_property(_visual, "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _on_died() -> void:
	await get_tree().create_timer(revive_delay, false).timeout
	_health.revive()
