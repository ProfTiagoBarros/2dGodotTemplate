class_name Actions
## Nomes das ações do InputMap (Project Settings > Input Map).
##
## Use SEMPRE estas constantes no código (`Input.is_action_pressed(Actions.JUMP)`):
## um erro de digitação vira erro de COMPILAÇÃO, em vez de uma ação que nunca
## dispara. O smoke test garante que toda ação do InputMap está declarada aqui.
##
## Ao criar uma ação nova: adicione no InputMap, aqui (constante + ALL) e, se o
## jogador puder remapear, em InputBindings.REMAPPABLE.

const MOVE_LEFT := &"move_left"
const MOVE_RIGHT := &"move_right"
const MOVE_UP := &"move_up"
const MOVE_DOWN := &"move_down"
const JUMP := &"jump"
const ATTACK := &"attack"
const DASH := &"dash"
const INTERACT := &"interact"
const PAUSE := &"pause"
## Mira com o analógico direito (top-down).
const AIM_LEFT := &"aim_left"
const AIM_RIGHT := &"aim_right"
const AIM_UP := &"aim_up"
const AIM_DOWN := &"aim_down"

## Todas as ações do jogo (as `ui_*` nativas do Godot ficam de fora).
const ALL: Array[StringName] = [
	MOVE_LEFT, MOVE_RIGHT, MOVE_UP, MOVE_DOWN,
	JUMP, ATTACK, DASH, INTERACT, PAUSE,
	AIM_LEFT, AIM_RIGHT, AIM_UP, AIM_DOWN,
]
