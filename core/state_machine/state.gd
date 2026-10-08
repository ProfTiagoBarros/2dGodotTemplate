class_name State
extends Node
## Estado base de uma StateMachine. Sobrescreva apenas o que precisar.
## O nome do nó é o identificador do estado (ex.: "Idle", "Run").

var state_machine: StateMachine


## Chamado ao entrar no estado. `data` permite passar contexto (ex.: direção do hit).
func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func transition_to(state_name: StringName, data: Dictionary = {}) -> void:
	state_machine.transition_to(state_name, data)
