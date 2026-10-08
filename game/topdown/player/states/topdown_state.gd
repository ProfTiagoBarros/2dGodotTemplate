class_name TopDownState
extends State
## Base dos estados do player top-down: acesso tipado ao dono e nomes dos estados.

const IDLE := &"Idle"
const WALK := &"Walk"
const DASH := &"Dash"
const ATTACK := &"Attack"

var player: TopDownPlayer


func _ready() -> void:
	player = owner as TopDownPlayer
	assert(player != null, "TopDownState deve estar dentro da cena do TopDownPlayer.")


## Ações disponíveis nos estados "livres" (Idle/Walk). Retorna true se transicionou.
func try_actions() -> bool:
	if Input.is_action_just_pressed(&"attack"):
		transition_to(ATTACK)
		return true
	if Input.is_action_just_pressed(&"dash") and player.can_dash():
		transition_to(DASH)
		return true
	return false
