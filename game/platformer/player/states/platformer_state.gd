class_name PlatformerState
extends State
## Base dos estados do Player: acesso tipado ao dono, nomes dos estados e
## transições comuns.

const IDLE := &"Idle"
const RUN := &"Run"
const JUMP := &"Jump"
const FALL := &"Fall"
const ATTACK := &"Attack"
const DASH := &"Dash"

var player: PlatformerPlayer


func _ready() -> void:
	player = owner as PlatformerPlayer
	assert(player != null, "PlatformerState deve estar dentro da cena do Player.")


## Ataque e dash, disponíveis nos estados "livres" (chão e ar).
## Retorna true se transicionou.
func try_actions() -> bool:
	if Input.is_action_just_pressed(&"attack") and player.can_attack():
		transition_to(ATTACK)
		return true
	if Input.is_action_just_pressed(&"dash") and player.can_dash():
		transition_to(DASH)
		return true
	return false


## Volta para o estado de movimento adequado à situação atual.
func transition_to_free_state() -> void:
	if not player.is_on_floor():
		transition_to(FALL)
	elif is_zero_approx(player.get_input_axis()):
		transition_to(IDLE)
	else:
		transition_to(RUN)
