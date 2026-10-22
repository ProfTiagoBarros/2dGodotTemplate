class_name StateMachine
extends Node
## Máquina de estados finitos baseada em nós: cada filho `State` é um estado.
## Delega _process/_physics_process/_unhandled_input ao estado atual.

signal state_changed(from: StringName, to: StringName)

@export var initial_state: State

var current_state: State
var _states: Dictionary[StringName, State] = {}
var _transitioning := false
var _queued_transition: Array = []


func _ready() -> void:
	for child: Node in get_children():
		if child is State:
			var state := child as State
			state.state_machine = self
			_states[state.name] = state

	# Garante que o dono (ex.: Player) terminou o _ready antes do primeiro estado.
	if owner != null and not owner.is_node_ready():
		await owner.ready

	current_state = initial_state if initial_state != null else _first_state()
	assert(current_state != null, "StateMachine '%s' não tem estados." % get_path())
	current_state.enter(&"", {})


func transition_to(state_name: StringName, data: Dictionary = {}) -> void:
	var next: State = _states.get(state_name)
	if next == null and _states.is_empty():
		# Antes do _ready os estados ainda não foram registrados: busca pelo nó.
		next = get_node_or_null(NodePath(state_name)) as State
	if next == null:
		Log.error("StateMachine: estado inexistente '%s'." % state_name)
		return
	if current_state == null:
		# Ainda inicializando (ex.: dano no mesmo frame em que a entidade nasce):
		# vira o estado inicial em vez de quebrar.
		initial_state = next
		return
	if _transitioning:
		# Transição pedida dentro de enter()/exit(): executa depois da atual,
		# para os sinais e a ordem enter/exit não se embaralharem.
		_queued_transition = [state_name, data]
		return
	if next == current_state:
		return
	_transitioning = true
	var previous := current_state.name
	current_state.exit()
	current_state = next
	current_state.enter(previous, data)
	state_changed.emit(previous, current_state.name)
	_transitioning = false
	if not _queued_transition.is_empty():
		var queued := _queued_transition
		_queued_transition = []
		transition_to(queued[0], queued[1])


func _unhandled_input(event: InputEvent) -> void:
	if current_state != null:
		current_state.handle_input(event)


func _process(delta: float) -> void:
	if current_state != null:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)


func _first_state() -> State:
	return _states.values()[0] if not _states.is_empty() else null
