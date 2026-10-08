class_name Level
extends Node2D
## Raiz de toda fase (de qualquer gênero). Mantém metadados da fase; a lógica
## de fluxo (morte, vitória, transições) fica em game.gd.

@export var level_id: StringName
@export var music: AudioStream

@export_group("Touch")
## Ação do botão de toque principal (A). Platformer: jump. Top-down: attack.
@export var touch_primary_action := &"jump"
## Ação do botão de toque secundário (B). Platformer: interact. Top-down: dash.
@export var touch_secondary_action := &"interact"


func _ready() -> void:
	if music != null:
		AudioManager.play_music(music)
