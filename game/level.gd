class_name Level
extends Node2D
## Raiz de toda fase (de qualquer gênero). Mantém metadados da fase e diz à
## "casca" (game.gd) como configurar a UI: quais dicas de botão mostrar e o
## que cada botão de toque faz. A lógica de fluxo (morte, vitória) fica em game.gd.

@export var level_id: StringName
@export var music: AudioStream

@export_group("UI")
## Ações dos botões de toque A, B e C, nessa ordem (vazio = botão escondido).
@export var touch_actions: Array[StringName] = [Actions.JUMP, Actions.ATTACK, Actions.DASH]
## Ações com dica "[atalho]" na HUD (ex.: tutorial mostra só o que já foi ensinado).
@export var hud_hint_actions: Array[StringName] = [Actions.JUMP, Actions.ATTACK, Actions.DASH, Actions.PAUSE]

@export_group("Câmera")
## Área (em pixels) que a câmera pode mostrar. Vazia = sem limites.
@export var camera_limits := Rect2i()


func _ready() -> void:
	if music != null:
		AudioManager.play_music(music)
	if camera_limits.has_area():
		# Adiado: a câmera do player entra na árvore depois da raiz da fase.
		_apply_camera_limits.call_deferred()


func _apply_camera_limits() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	camera.limit_left = camera_limits.position.x
	camera.limit_top = camera_limits.position.y
	camera.limit_right = camera_limits.end.x
	camera.limit_bottom = camera_limits.end.y
