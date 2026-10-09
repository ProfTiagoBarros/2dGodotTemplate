class_name HealthComponent
extends Node
## Vida reutilizável (composição): adicione como filho de qualquer entidade.

signal health_changed(current: int, max_health: int)
signal damaged(amount: int, source: Node)
signal healed(amount: int)
signal died

@export_range(1, 999) var max_health := 3
## Segundos de invencibilidade após levar dano (i-frames).
@export_range(0.0, 5.0, 0.05) var invulnerability_time := 0.0

var current := 0
## Ignora todo dano (cheat de debug, cutscenes).
var god_mode := false
var _invulnerable_left := 0.0


func _ready() -> void:
	current = max_health
	set_physics_process(false)


func is_dead() -> bool:
	return current <= 0


func is_invulnerable() -> bool:
	return god_mode or _invulnerable_left > 0.0


## Morte imediata, ignorando i-frames e god mode (abismos, comandos de debug).
func kill() -> void:
	if is_dead():
		return
	current = 0
	health_changed.emit(current, max_health)
	died.emit()


## Restaura a vida cheia, inclusive após a morte (respawn, checkpoints).
func revive() -> void:
	current = max_health
	health_changed.emit(current, max_health)


## Invencibilidade sob demanda (ex.: durante um dash ou cutscene).
func grant_invulnerability(seconds: float) -> void:
	_invulnerable_left = maxf(_invulnerable_left, seconds)
	set_physics_process(_invulnerable_left > 0.0)


## Retorna true se o dano foi aplicado.
func take_damage(amount: int, source: Node = null) -> bool:
	if amount <= 0 or is_dead() or is_invulnerable():
		return false
	current = maxi(current - amount, 0)
	if invulnerability_time > 0.0:
		_invulnerable_left = invulnerability_time
		set_physics_process(true)
	damaged.emit(amount, source)
	health_changed.emit(current, max_health)
	if is_dead():
		died.emit()
	return true


func heal(amount: int) -> void:
	if amount <= 0 or is_dead():
		return
	var previous := current
	current = mini(current + amount, max_health)
	if current != previous:
		healed.emit(current - previous)
		health_changed.emit(current, max_health)


func _physics_process(delta: float) -> void:
	_invulnerable_left -= delta
	if _invulnerable_left <= 0.0:
		_invulnerable_left = 0.0
		set_physics_process(false)
