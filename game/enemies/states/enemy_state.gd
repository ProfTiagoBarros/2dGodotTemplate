class_name EnemyState
extends State
## Base dos estados genéricos de inimigo (servem a qualquer gênero: o
## movimento concreto fica na subclasse de Enemy).

const PATROL := &"Patrol"
const CHASE := &"Chase"
const WINDUP := &"Windup"
const ATTACK := &"Attack"
const RECOVER := &"Recover"
const HURT := &"Hurt"

var enemy: Enemy


func _ready() -> void:
	enemy = owner as Enemy
	assert(enemy != null, "EnemyState deve estar dentro de uma cena de Enemy.")


## Volta a perseguir (se ainda vê o player) ou a patrulhar.
func resume() -> void:
	transition_to(CHASE if enemy.target != null else PATROL)
