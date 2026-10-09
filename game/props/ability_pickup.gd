class_name AbilityPickup
extends Area2D
## Item que destrava uma habilidade ao ser tocado pelo player (metroidvania).
## Funciona com qualquer player que implemente has_ability()/unlock_ability()
## (duck typing). Some sozinho se o player já tiver a habilidade (ex.: save
## carregado), e salva o progresso ao ser coletado.

@export var ability: StringName = &"double_jump"
@export var autosave := true
@export var bob_height := 3.0

var _time := 0.0

@onready var _visual: Node2D = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_free_if_already_owned.call_deferred()


func _process(delta: float) -> void:
	_time += delta
	_visual.position.y = sin(_time * 3.0) * bob_height
	_visual.rotation = sin(_time * 1.5) * 0.15


func _free_if_already_owned() -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	if player != null and player.has_method(&"has_ability") and player.call(&"has_ability", ability):
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method(&"unlock_ability"):
		return
	if body.call(&"unlock_ability", ability) and autosave:
		SaveSystem.save_game()
	queue_free()
