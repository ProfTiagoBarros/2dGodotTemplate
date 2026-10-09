class_name TopDownPlayer
extends CharacterBody2D
## Player top-down (8 direções, analógico) com mira twin-stick. Os estados
## (states/) decidem as transições; este script expõe primitivas de movimento,
## mira, dash e ataque.
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
var _attacking := false

@onready var visual: Node2D = $Visual
@onready var squash: SquashStretch = $Visual/Squash
@onready var health: HealthComponent = $HealthComponent
@onready var state_machine: StateMachine = $StateMachine
@onready var attack_pivot: Node2D = $AttackPivot
@onready var attack_hitbox: HitboxComponent = $AttackPivot/AttackHitbox
@onready var _attack_shape: CollisionShape2D = $AttackPivot/AttackHitbox/CollisionShape2D
@onready var _aim_indicator: Node2D = $AttackPivot/AimIndicator


func _ready() -> void:
	health.health_changed.connect(_on_health_changed)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	attack_hitbox.hit_landed.connect(_on_attack_landed)
	set_attack_active(false)
	face(facing)
	_on_health_changed.call_deferred(health.current, health.max_health)


func _physics_process(delta: float) -> void:
	# Roda antes da StateMachine (pai antes dos filhos): estados já veem a mira atual.
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	_update_aim()


## Vetor de input já normalizado e com deadzone (módulo <= 1, preserva analógico).
func get_input_vector() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


func get_aim_stick() -> Vector2:
	if not InputMap.has_action(&"aim_right"):
		return Vector2.ZERO
	return Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")


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


func set_attack_active(active: bool) -> void:
	_attacking = active
	if active:
		attack_pivot.rotation = aim_direction.angle()
	_attack_shape.set_deferred(&"disabled", not active)
	attack_hitbox.visible = active
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
	_aim_indicator.visible = not _attacking and aim_source != AimSource.MOVEMENT


func _set_aim(direction: Vector2) -> void:
	aim_direction = direction.normalized()
	# Durante o golpe a hitbox fica travada na direção em que o ataque começou.
	if not _attacking:
		attack_pivot.rotation = aim_direction.angle()
	if not is_zero_approx(aim_direction.x):
		visual.scale.x = signf(aim_direction.x)


func _on_health_changed(current: int, max_health: int) -> void:
	EventBus.player_health_changed.emit(current, max_health)


func _on_damaged(_amount: int, source: Node) -> void:
	var away := -facing
	if source is Node2D:
		var offset := global_position - (source as Node2D).global_position
		if not offset.is_zero_approx():
			away = offset.normalized()
	velocity = away * stats.knockback_speed
	EventBus.camera_shake_requested.emit(0.5)
	GameFeel.hitstop(0.08)


func _on_attack_landed(_hurtbox: HurtboxComponent) -> void:
	EventBus.camera_shake_requested.emit(0.2)
	GameFeel.hitstop(0.05)
	GameFeel.spawn_effect(GameFeel.HIT_SPARKS, _attack_shape.global_position)


func _on_died() -> void:
	set_physics_process(false)
	set_attack_active(false)
	state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 0.4)
	EventBus.player_died.emit()
