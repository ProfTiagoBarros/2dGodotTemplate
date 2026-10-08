class_name PlatformerState
extends State
## Base dos estados do Player: acesso tipado ao dono e nomes dos estados.

const IDLE := &"Idle"
const RUN := &"Run"
const JUMP := &"Jump"
const FALL := &"Fall"

var player: PlatformerPlayer


func _ready() -> void:
	player = owner as PlatformerPlayer
	assert(player != null, "PlatformerState deve estar dentro da cena do Player.")
