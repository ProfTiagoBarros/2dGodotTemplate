class_name SquashStretch
extends Node2D
## Nó intermediário que deforma os filhos (squash & stretch) e volta ao normal
## com uma mola (TRANS_BACK). Fica ENTRE o nó que faz o flip (scale.x = ±1) e
## o desenho, para as duas coisas não brigarem pelo `scale`.
## Com a origem nos pés, os pés ficam "plantados" no chão ao deformar.
##
## Conservação de área: esticar por k num eixo divide o outro por k
## (sx · sy = 1), o que dá a sensação de "massa" constante.

@export var return_duration := 0.18

var _tween: Tween


## Esticado na vertical (pulo): factor > 1 alonga, < 1 achata.
func stretch_vertical(factor: float, duration: float = return_duration) -> void:
	deform(Vector2(1.0 / factor, factor), duration)


## Esticado na horizontal (dash, aterrissagem): factor > 1 alarga.
func stretch_horizontal(factor: float, duration: float = return_duration) -> void:
	deform(Vector2(factor, 1.0 / factor), duration)


func deform(target_scale: Vector2, duration: float = return_duration) -> void:
	scale = target_scale
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE, duration) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
