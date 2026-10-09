class_name HitFlashComponent
extends Node
## Pisca o visual (padrão: branco) quando o HealthComponent leva dano.
## Aplica um ShaderMaterial em `target` e faz todos os CanvasItems filhos
## herdarem o material (use_parent_material). Dica: aponte para um nó que
## agrupa só o "corpo" (sem sombra), ex.: Visual/Squash.

const SHADER := preload("res://core/feel/hit_flash.gdshader")

@export var target: CanvasItem
@export var health: HealthComponent
@export var flash_color := Color.WHITE
@export var duration := 0.12

var _material := ShaderMaterial.new()
var _tween: Tween


func _ready() -> void:
	_material.shader = SHADER
	_material.set_shader_parameter(&"flash_color", flash_color)
	target.material = _material
	for child: Node in target.find_children("*", "CanvasItem", true, false):
		(child as CanvasItem).use_parent_material = true
	if health != null:
		health.damaged.connect(_on_damaged)


func flash() -> void:
	if _tween != null:
		_tween.kill()
	_set_amount(1.0) # já no frame do impacto (o tween só começa no próximo)
	_tween = create_tween()
	_tween.tween_method(_set_amount, 1.0, 0.0, duration).set_ease(Tween.EASE_IN)


func get_amount() -> float:
	return float(_material.get_shader_parameter(&"flash_amount"))


func _set_amount(amount: float) -> void:
	_material.set_shader_parameter(&"flash_amount", amount)


func _on_damaged(_amount: int, _source: Node) -> void:
	flash()
