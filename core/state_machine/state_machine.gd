class_name StateMachine
extends Node
## Máquina de estados finitos baseada em nós: cada filho `State` é um estado.
## Delega _process/_physics_process/_unhandled_input ao estado atual.

signal state_changed(from: StringName, to: StringName)

@export var initial_state: State

var current_state: State
var _states: Dictionary[StringName, State] = {}


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
	if next == null:
		push_error("StateMachine: estado inexistente '%s'." % state_name)
		return
	if next == current_state:
		return
	var previous := current_state.name
	current_state.exit()
	current_state = next
	current_state.enter(previous, data)
	state_changed.emit(previous, current_state.name)


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
