class_name TouchButton
extends Control
## Botão de toque multitouch que dispara uma ação do InputMap.
## Gera InputEventAction reais: funciona com is_action_just_pressed E com
## _unhandled_input (ex.: menu de pausa).

@export var action := &"jump"
@export var label := "A"
@export var color := Color(1, 1, 1, 0.18)
@export var pressed_color := Color(1, 1, 1, 0.45)
## Multiplicador da área de toque além do círculo desenhado (dedos são imprecisos).
@export_range(1.0, 2.0) var touch_padding := 1.25

var _finger := -1


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventScreenTouch:
		return
	var touch := event as InputEventScreenTouch
	if touch.pressed and _finger == -1 and _is_inside(touch):
		_finger = touch.index
		_send(true)
		get_viewport().set_input_as_handled()
	elif not touch.pressed and touch.index == _finger:
		_finger = -1
		_send(false)
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree() and _finger != -1:
		_finger = -1
		_send(false)


func _draw() -> void:
	var center := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	draw_circle(center, r, pressed_color if _finger != -1 else color)

	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := center + Vector2(-text_size.x * 0.5, (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5)
	draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)


func _is_inside(touch: InputEventScreenTouch) -> bool:
	var local := (make_input_local(touch) as InputEventScreenTouch).position
	var r := minf(size.x, size.y) * 0.5 * touch_padding
	return local.distance_to(size * 0.5) <= r


func _send(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)
	queue_redraw()
