@abstract
class_name Enemy
extends Character
## Base de inimigos de QUALQUER gênero. Os estados genéricos em
## game/enemies/states/ (Patrol → Chase → Windup → Attack → Recover, e Hurt ao
## levar dano) usam só a API pública abaixo. Dano, golpe e morte vêm de
## Character; cada gênero estende esta classe e implementa o MOVIMENTO
## (métodos @abstract — o compilador recusa um inimigo que esqueça algum).
##
## Cena esperada (veja platformer_enemy.tscn / topdown_enemy.tscn):
##   Visual/Squash, HealthComponent, Hurtbox, ContactHitbox,
##   AttackPivot/AttackHitbox/CollisionShape2D, StateMachine.

signal target_changed(target: Node2D)

@export var stats: EnemyStats
## Intervalo entre checagens de percepção (s). O raycast de linha de visão é a
## parte cara; 10 Hz é imperceptível e funciona como "tempo de reação".
@export var perception_interval := 0.1

## Player perseguido no momento (null = nenhum).
var target: Node2D
var facing := Vector2.RIGHT

var _windup_tween: Tween
var _perception_cooldown := 0.0

@onready var _contact_hitbox: HitboxComponent = $ContactHitbox
@onready var _hurtbox: HurtboxComponent = $Hurtbox


func _init() -> void:
	# O tremor/hitstop do combate já é disparado pelo PLAYER (ao acertar e ao
	# levar dano); repetir aqui dobraria o efeito. Uma cena pode religar.
	hurt_shake = 0.0
	hurt_hitstop = 0.0
	hit_shake = 0.0
	hit_hitstop = 0.0


func _ready() -> void:
	super._ready()
	add_to_group(Groups.ENEMY)
	# Começa em fase aleatória: espalha os raycasts dos inimigos entre frames.
	_perception_cooldown = randf() * perception_interval


func _physics_process(delta: float) -> void:
	# Antes da StateMachine (pai antes dos filhos): estados veem o alvo atual.
	_perception_cooldown -= delta
	if _perception_cooldown <= 0.0:
		_perception_cooldown += perception_interval
		update_target()


#region Percepção

## Alvo = player (grupo Groups.PLAYER) vivo, dentro do raio e com linha de visão.
## Já perseguindo, usa o raio maior (lose_target_radius): histerese.
func update_target() -> void:
	var player := get_tree().get_first_node_in_group(Groups.PLAYER) as Node2D
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


#region Movimento (implementado por gênero)

## Direção (unitária) até o alvo no plano de movimento do gênero.
@abstract func direction_to_target() -> Vector2


## Direção de patrulha (ida e volta, vaguear...).
@abstract func patrol_direction() -> Vector2


## Acelera até direction × speed e chama move_and_slide().
## direction = ZERO desacelera (usado em Windup/Recover/Hurt).
@abstract func move_toward_direction(direction: Vector2, speed: float, delta: float) -> void


## Sobrescreva se o bote precisar de gravidade etc.
func lunge_step(_delta: float) -> void:
	move_and_slide()


## Sobrescreva para ajustar o knockback (ex.: pulinho no platformer).
func apply_knockback(direction: Vector2) -> void:
	velocity = direction * stats.knockback_speed


func get_facing_vector() -> Vector2:
	return facing


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


## O golpe sai na direção para onde o inimigo olha.
func set_attack_active(active: bool) -> void:
	attack_pivot.rotation = facing.angle()
	super.set_attack_active(active)

#endregion


func _on_hurt(_amount: int, _source: Node) -> void:
	if not health.is_dead():
		state_machine.transition_to(&"Hurt")


func _play_death() -> void:
	EventBus.enemy_died.emit(self)
	collision_layer = 0
	_contact_hitbox.set_deferred(&"monitorable", false)
	_hurtbox.set_deferred(&"monitoring", false)
	GameFeel.spawn_effect(GameFeel.HIT_SPARKS, eye_position())
	GameFeel.spawn_effect(GameFeel.DUST, global_position)
	EventBus.camera_shake_requested.emit(0.25)
	var tween := create_tween()
	tween.tween_property(squash, "scale", Vector2(1.6, 0.05), 0.15)
	tween.tween_callback(queue_free)
