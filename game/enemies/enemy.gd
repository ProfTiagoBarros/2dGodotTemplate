class_name Enemy
extends CharacterBody2D
## Base de inimigos de QUALQUER gênero. Os estados genéricos em
## game/enemies/states/ (Patrol → Chase → Windup → Attack → Recover, e Hurt ao
## levar dano) usam só a API pública abaixo. Cada gênero estende esta classe e
## implementa o MOVIMENTO (métodos marcados "Sobrescreva").
##
## Cena esperada (veja platformer_enemy.tscn / topdown_enemy.tscn):
##   Visual/Squash, HealthComponent, Hurtbox, ContactHitbox,
##   AttackPivot/AttackHitbox/CollisionShape2D, StateMachine.

signal target_changed(target: Node2D)

@export var stats: EnemyStats

## Player perseguido no momento (null = nenhum).
var target: Node2D
var facing := Vector2.RIGHT

var _attacking := false
var _windup_tween: Tween

@onready var visual: Node2D = $Visual
@onready var squash: SquashStretch = $Visual/Squash
@onready var health: HealthComponent = $HealthComponent
@onready var state_machine: StateMachine = $StateMachine
@onready var attack_pivot: Node2D = $AttackPivot
@onready var attack_hitbox: HitboxComponent = $AttackPivot/AttackHitbox
@onready var _attack_shape: CollisionShape2D = $AttackPivot/AttackHitbox/CollisionShape2D
@onready var _contact_hitbox: HitboxComponent = $ContactHitbox
@onready var _hurtbox: HurtboxComponent = $Hurtbox


func _ready() -> void:
	add_to_group(&"enemy")
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	set_attack_active(false)


func _physics_process(_delta: float) -> void:
	# Antes da StateMachine (pai antes dos filhos): estados veem o alvo atual.
	update_target()


#region Percepção

## Alvo = player (grupo "player") vivo, dentro do raio e com linha de visão.
## Já perseguindo, usa o raio maior (lose_target_radius): histerese.
func update_target() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	var new_target: Node2D = null
	if player != null and _is_alive(player):
		var radius := stats.lose_target_radius if target != null else stats.detection_radius
		if global_position.distance_to(player.global_position) <= radius and has_line_of_sight(player):
			new_target = player
	if new_target != target:
		target = new_target
		target_changed.emit(target)


func has_line_of_sight(node: Node2D) -> bool:
	var query := PhysicsRayQueryParameters2D.create(
			eye_position(), node.global_position + Vector2(0.0, -6.0), PhysicsLayers.WORLD, [get_rid()])
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func eye_position() -> Vector2:
	return global_position + Vector2(0.0, -6.0)


func can_attack_target() -> bool:
	return target != null and global_position.distance_to(target.global_position) <= stats.attack_range


func _is_alive(node: Node) -> bool:
	var target_health := node.get(&"health") as HealthComponent
	return target_health == null or not target_health.is_dead()

#endregion


#region Movimento (sobrescreva por gênero)

## Sobrescreva: direção (unitária) até o alvo no plano de movimento do gênero.
func direction_to_target() -> Vector2:
	return Vector2.ZERO


## Sobrescreva: direção de patrulha (ida e volta, vaguear...).
func patrol_direction() -> Vector2:
	return Vector2.ZERO


## Sobrescreva: acelera até direction × speed e chama move_and_slide().
## direction = ZERO desacelera (usado em Windup/Recover/Hurt).
func move_toward_direction(_direction: Vector2, _speed: float, _delta: float) -> void:
	move_and_slide()


## Sobrescreva se o bote precisar de gravidade etc.
func lunge_step(_delta: float) -> void:
	move_and_slide()


## Sobrescreva para ajustar o knockback (ex.: pulinho no platformer).
func apply_knockback(direction: Vector2) -> void:
	velocity = direction * stats.knockback_speed


func face(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	facing = direction.normalized()
	if not is_zero_approx(facing.x):
		visual.scale.x = signf(facing.x)

#endregion


#region Ataque

## Telegrafa o golpe: o jogador precisa VER o ataque vindo para reagir.
func begin_windup() -> void:
	face(direction_to_target())
	squash.stretch_horizontal(1.3, stats.windup_time)
	_windup_tween = create_tween()
	_windup_tween.tween_property(squash, "modulate", stats.windup_color, stats.windup_time * 0.8)


func end_windup() -> void:
	# Mata o tween: se o windup foi interrompido (dano), não pode "avermelhar" depois.
	if _windup_tween != null:
		_windup_tween.kill()
	squash.modulate = Color.WHITE


func start_lunge() -> void:
	var direction := direction_to_target()
	if direction.is_zero_approx():
		direction = facing
	face(direction)
	velocity = facing * stats.lunge_speed
	set_attack_active(true)
	squash.stretch_horizontal(1.35)


func end_lunge() -> void:
	set_attack_active(false)


func is_attacking() -> bool:
	return _attacking


func set_attack_active(active: bool) -> void:
	_attacking = active
	attack_pivot.rotation = facing.angle()
	_attack_shape.set_deferred(&"disabled", not active)
	attack_hitbox.visible = active

#endregion


func _on_damaged(_amount: int, source: Node) -> void:
	var away := -facing
	if source is Node2D:
		var offset := global_position - (source as Node2D).global_position
		if not offset.is_zero_approx():
			away = offset.normalized()
	apply_knockback(away)
	if not health.is_dead():
		state_machine.transition_to(&"Hurt")


func _on_died() -> void:
	EventBus.enemy_died.emit(self)
	set_physics_process(false)
	state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	set_attack_active(false)
	collision_layer = 0
	_contact_hitbox.set_deferred(&"monitorable", false)
	_hurtbox.set_deferred(&"monitoring", false)
	GameFeel.spawn_effect(GameFeel.HIT_SPARKS, eye_position())
	GameFeel.spawn_effect(GameFeel.DUST, global_position)
	EventBus.camera_shake_requested.emit(0.25)
	var tween := create_tween()
	tween.tween_property(squash, "scale", Vector2(1.6, 0.05), 0.15)
	tween.tween_callback(queue_free)
