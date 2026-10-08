@tool
class_name SolidBlock
extends StaticBody2D
## Bloco sólido de protótipo (greybox): colisão + visual a partir de `size`.
## Ótimo para prototipar fases antes de ter tiles/arte; substitua por
## TileMapLayer quando a arte chegar.

@export var size := Vector2(64.0, 16.0):
	set(value):
		size = value.max(Vector2.ONE)
		_update_shape()
@export var color := Color(0.23, 0.23, 0.31):
	set(value):
		color = value
		queue_redraw()

var _collision := CollisionShape2D.new()


func _ready() -> void:
	_collision.shape = RectangleShape2D.new()
	add_child(_collision, false, Node.INTERNAL_MODE_FRONT)
	_update_shape()


func _draw() -> void:
	draw_rect(Rect2(-size * 0.5, size), color)


func _update_shape() -> void:
	var rect := _collision.shape as RectangleShape2D
	if rect != null:
		rect.size = size
	queue_redraw()
