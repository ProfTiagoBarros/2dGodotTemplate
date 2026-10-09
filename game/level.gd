class_name Level
extends Node2D
## Raiz de toda fase (de qualquer gênero). Mantém metadados da fase e diz à
## "casca" (game.gd) como configurar a UI: quais dicas de botão mostrar e o
## que cada botão de toque faz. A lógica de fluxo (morte, vitória) fica em game.gd.

@export var level_id: StringName
@export var music: AudioStream

@export_group("UI")
## Ações dos botões de toque A, B e C, nessa ordem (vazio = botão escondido).
@export var touch_actions: Array[StringName] = [&"jump", &"attack", &"dash"]
## Ações com dica "[atalho]" na HUD (ex.: tutorial mostra só o que já foi ensinado).
@export var hud_hint_actions: Array[StringName] = [&"jump", &"attack", &"dash", &"pause"]


func _ready() -> void:
	if music != null:
		AudioManager.play_music(music)
