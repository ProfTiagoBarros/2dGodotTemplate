class_name SafeAreaMargin
extends MarginContainer
## Afasta o conteúdo de notches, cantos arredondados e barras do sistema
## usando a "safe area" do dispositivo. Em desktop aplica só `base_margin`.

@export var base_margin := 8


func _ready() -> void:
	get_viewport().size_changed.connect(_update_margins)
	_update_margins()


func _update_margins() -> void:
	var left := float(base_margin)
	var top := float(base_margin)
	var right := float(base_margin)
	var bottom := float(base_margin)

	if PlatformUtils.is_mobile():
		var window_size := Vector2(DisplayServer.window_get_size())
		if window_size.x > 0.0 and window_size.y > 0.0:
			var safe := Rect2(DisplayServer.get_display_safe_area())
			# Converte pixels de tela para unidades do canvas (stretch canvas_items).
			var to_canvas := get_viewport().get_visible_rect().size / window_size
			left += safe.position.x * to_canvas.x
			top += safe.position.y * to_canvas.y
			right += (window_size.x - safe.end.x) * to_canvas.x
			bottom += (window_size.y - safe.end.y) * to_canvas.y

	add_theme_constant_override(&"margin_left", roundi(left))
	add_theme_constant_override(&"margin_top", roundi(top))
	add_theme_constant_override(&"margin_right", roundi(right))
	add_theme_constant_override(&"margin_bottom", roundi(bottom))
