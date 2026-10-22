class_name TopDownPlayer
extends PlayerCharacter
## Player top-down (8 direções, analógico) com mira twin-stick. Os estados
## (states/) decidem as transições; este script expõe só o que é ESPECÍFICO do
## gênero: movimento, mira, dash e ataque. Vida, dano, golpe e morte vêm de
## Character/PlayerCharacter.
## A origem fica nos PÉS e a colisão cobre só a base: é isso que dá a
## sensação de profundidade e faz o Y-sort funcionar.
##
## Mira (prioridade): analógico direito > mouse (se em uso) > direção do movimento.

enum AimSource { MOVEMENT, MOUSE, STICK }

@export var stats: TopDownStats

## Última direção de movimento (unitária).
var facing := Vector2.DOWN
## Direção da mira (unitária). É para onde o ataque aponta.
var aim_direction := Vector2.DOWN
var aim_source := AimSource.MOVEMENT

var _dash_cooldown_left := 0.0

@onready var _aim_indicator: Node2D = $AttackPivot/AimIndicator


func _ready() -> void:
	super._ready()
	face(facing)


func _physics_process(delta: float) -> void:
	# Roda antes da StateMachine (pai antes dos filhos): estados já veem a mira atual.
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	_update_aim()


## Vetor de input já normalizado e com deadzone (módulo <= 1, preserva analógico).
func get_input_vector() -> Vector2:
	return Input.get_vector(Actions.MOVE_LEFT, Actions.MOVE_RIGHT, Actions.MOVE_UP, Actions.MOVE_DOWN)


func get_aim_stick() -> Vector2:
	if not InputMap.has_action(Actions.AIM_RIGHT):
		return Vector2.ZERO
	return Input.get_vector(Actions.AIM_LEFT, Actions.AIM_RIGHT, Actions.AIM_UP, Actions.AIM_DOWN)


func apply_movement(delta: float, direction: Vector2) -> void:
	var rate := stats.friction if direction.is_zero_approx() else stats.acceleration
	velocity = velocity.move_toward(direction * stats.max_speed, rate * delta)
	if not direction.is_zero_approx():
		face(direction)


func face(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	facing = direction.normalized()
	if aim_source == AimSource.MOVEMENT:
		_set_aim(facing)


func can_dash() -> bool:
	return _dash_cooldown_left <= 0.0


func start_dash_cooldown() -> void:
	_dash_cooldown_left = stats.dash_cooldown


func get_facing_vector() -> Vector2:
	return facing


func apply_knockback(direction: Vector2) -> void:
	velocity = direction * stats.knockback_speed


## Além de ligar a hitbox, trava o golpe na direção da mira e esconde o indicador.
func set_attack_active(active: bool) -> void:
	if active:
		attack_pivot.rotation = aim_direction.angle()
	super.set_attack_active(active)
	_aim_indicator.visible = not active and aim_source != AimSource.MOVEMENT


func _update_aim() -> void:
	var stick := get_aim_stick()
	if not stick.is_zero_approx():
		aim_source = AimSource.STICK
		_set_aim(stick)
	elif InputManager.using_mouse:
		aim_source = AimSource.MOUSE
		var to_mouse := get_global_mouse_position() - attack_pivot.global_position
		if to_mouse.length_squared() > 4.0:
			_set_aim(to_mouse)
	else:
		aim_source = AimSource.MOVEMENT
		_set_aim(facing)
	_aim_indicator.visible = not is_attacking() and aim_source != AimSource.MOVEMENT


func _set_aim(direction: Vector2) -> void:
	aim_direction = direction.normalized()
	# Durante o golpe a hitbox fica travada na direção em que o ataque começou.
	if not is_attacking():
		attack_pivot.rotation = aim_direction.angle()
	if not is_zero_approx(aim_direction.x):
		visual.scale.x = signf(aim_direction.x)
