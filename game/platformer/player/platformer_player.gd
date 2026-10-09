class_name PlatformerPlayer
extends CharacterBody2D
## Player de plataforma (side-scrolling / metroidvania). A decisão "o que fazer
## agora" vive nos estados (states/); este script expõe as primitivas de
## movimento, ataque, dash e o controle de HABILIDADES desbloqueáveis.
##
## Habilidades (progressão metroidvania): `abilities` lista o que o player já
## pode fazer. Destrave com `unlock_ability()` (ex.: AbilityPickup); o progresso
## é salvo no SaveSystem (grupo "persist").

const ABILITY_ATTACK := &"attack"
const ABILITY_DASH := &"dash"
const ABILITY_DOUBLE_JUMP := &"double_jump"
const SAVE_KEY := "platformer_abilities"

@export var stats: PlatformerStats
@export var knockback := Vector2(160.0, -180.0)
## Habilidades iniciais (usadas quando o save ainda não tem progresso).
@export var abilities: Array[StringName] = [ABILITY_ATTACK, ABILITY_DASH]

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var facing := 1.0
var air_jumps_left := 0
var air_dashes_left := 0
## Direção do ataque atual/último: lado, cima ou baixo (pogo).
var attack_direction := Vector2.RIGHT

var _attacking := false
var _attack_cooldown_left := 0.0
var _dash_cooldown_left := 0.0
var _was_on_floor := true
var _peak_fall_speed := 0.0

@onready var visual: Node2D = $Visual
@onready var squash: SquashStretch = $Visual/Squash
@onready var health: HealthComponent = $HealthComponent
@onready var state_machine: StateMachine = $StateMachine
@onready var attack_pivot: Node2D = $AttackPivot
@onready var attack_hitbox: HitboxComponent = $AttackPivot/AttackHitbox
@onready var _attack_shape: CollisionShape2D = $AttackPivot/AttackHitbox/CollisionShape2D


func _ready() -> void:
	add_to_group(SaveSystem.PERSIST_GROUP)
	_load_abilities()
	health.health_changed.connect(_on_health_changed)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	attack_hitbox.hit_landed.connect(_on_attack_landed)
	_set_hitbox_active(false)
	_refill_air_resources()
	# Adiado para que a HUD (instanciada depois) já esteja conectada.
	_on_health_changed.call_deferred(health.current, health.max_health)


func _physics_process(delta: float) -> void:
	# Roda antes da StateMachine (o pai é processado antes dos filhos).
	if Input.is_action_just_pressed(&"jump"):
		jump_buffer_timer = stats.jump_buffer_time
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)
	if is_on_floor():
		coyote_timer = stats.coyote_time
		_refill_air_resources()
		if not _was_on_floor:
			_on_landed(_peak_fall_speed)
		_peak_fall_speed = 0.0
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)
		_peak_fall_speed = maxf(_peak_fall_speed, velocity.y)
	_was_on_floor = is_on_floor()
	_attack_cooldown_left = maxf(_attack_cooldown_left - delta, 0.0)
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)


#region Movimento

func get_input_axis() -> float:
	return Input.get_axis(&"move_left", &"move_right")


func apply_gravity(delta: float) -> void:
	var rising_with_jump := velocity.y < 0.0 and Input.is_action_pressed(&"jump")
	var gravity := stats.jump_gravity if rising_with_jump else stats.fall_gravity
	velocity.y = minf(velocity.y + gravity * delta, stats.max_fall_speed)


func apply_horizontal(delta: float, on_ground: bool) -> void:
	var axis := get_input_axis()
	var rate: float
	if is_zero_approx(axis):
		rate = stats.friction if on_ground else stats.air_friction
	else:
		rate = stats.acceleration if on_ground else stats.air_acceleration
		# Durante o golpe o player não vira (a hitbox não "troca de lado").
		if not _attacking:
			face(signf(axis))
	velocity.x = move_toward(velocity.x, axis * stats.max_speed, rate * delta)


func face(direction: float) -> void:
	if is_zero_approx(direction):
		return
	facing = signf(direction)
	visual.scale.x = facing

#endregion


#region Pulo

func wants_to_jump() -> bool:
	return jump_buffer_timer > 0.0


## Pulo do chão (inclui coyote time).
func can_jump() -> bool:
	return coyote_timer > 0.0


## Pulo do chão OU pulo extra no ar (habilidade double_jump).
func can_any_jump() -> bool:
	return can_jump() or air_jumps_left > 0


func jump() -> void:
	var from_ground := can_jump()
	if not from_ground:
		air_jumps_left = maxi(air_jumps_left - 1, 0)
	velocity.y = -stats.jump_velocity
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	squash.stretch_vertical(1.3)
	if from_ground:
		GameFeel.spawn_effect(GameFeel.DUST, global_position)

#endregion


#region Ataque

func can_attack() -> bool:
	return has_ability(ABILITY_ATTACK) and not _attacking and _attack_cooldown_left <= 0.0


## Cima (segurando ↑), baixo (no ar segurando ↓ — pogo) ou para o lado.
func get_attack_direction() -> Vector2:
	if Input.is_action_pressed(&"move_up"):
		return Vector2.UP
	if not is_on_floor() and Input.is_action_pressed(&"move_down"):
		return Vector2.DOWN
	return Vector2(facing, 0.0)


func start_attack() -> void:
	attack_direction = get_attack_direction()
	attack_pivot.rotation = attack_direction.angle()
	_set_hitbox_active(true)


func end_attack() -> void:
	if _attacking:
		_attack_cooldown_left = stats.attack_cooldown
	_set_hitbox_active(false)


func is_attacking() -> bool:
	return _attacking


func _set_hitbox_active(active: bool) -> void:
	_attacking = active
	_attack_shape.set_deferred(&"disabled", not active)
	attack_hitbox.visible = active

#endregion


#region Dash

func can_dash() -> bool:
	return has_ability(ABILITY_DASH) and _dash_cooldown_left <= 0.0 \
			and (is_on_floor() or air_dashes_left > 0)


## Inicia o dash e devolve a direção (-1/1): input horizontal ou para onde olha.
func start_dash() -> float:
	var axis := get_input_axis()
	var direction := signf(axis) if not is_zero_approx(axis) else facing
	face(direction)
	if not is_on_floor():
		air_dashes_left -= 1
	else:
		GameFeel.spawn_effect(GameFeel.DUST, global_position)
	velocity = Vector2(direction * stats.dash_speed, 0.0)
	squash.stretch_horizontal(1.35)
	if stats.dash_invulnerable:
		health.grant_invulnerability(stats.dash_duration)
	return direction


func end_dash() -> void:
	_dash_cooldown_left = stats.dash_cooldown
	velocity.x = clampf(velocity.x, -stats.max_speed, stats.max_speed)

#endregion


#region Habilidades (metroidvania)

func has_ability(ability: StringName) -> bool:
	return ability in abilities


## Retorna true se a habilidade era nova.
func unlock_ability(ability: StringName) -> bool:
	if has_ability(ability):
		return false
	abilities.append(ability)
	if is_on_floor():
		_refill_air_resources()
	EventBus.ability_unlocked.emit(ability)
	return true


func lock_ability(ability: StringName) -> void:
	abilities.erase(ability)
	_refill_air_resources()


## Chamado pelo SaveSystem (grupo "persist").
func save_state(data: Dictionary) -> void:
	var names: Array[String] = []
	for ability: StringName in abilities:
		names.append(String(ability))
	data[SAVE_KEY] = names


## Chamado pelo SaveSystem (grupo "persist").
func load_state(_data: Dictionary) -> void:
	_load_abilities()


func _load_abilities() -> void:
	var saved: Variant = SaveSystem.data.get(SAVE_KEY)
	if not saved is Array:
		return
	abilities.clear()
	for ability: Variant in saved:
		abilities.append(StringName(str(ability)))


func _refill_air_resources() -> void:
	air_jumps_left = stats.air_jumps if has_ability(ABILITY_DOUBLE_JUMP) else 0
	air_dashes_left = stats.air_dashes

#endregion


func _on_health_changed(current: int, max_health: int) -> void:
	EventBus.player_health_changed.emit(current, max_health)


func _on_damaged(_amount: int, source: Node) -> void:
	var direction := -facing
	if source is Node2D:
		var away := signf(global_position.x - (source as Node2D).global_position.x)
		if away != 0.0:
			direction = away
	velocity = Vector2(knockback.x * direction, knockback.y)
	# Flash: HitFlashComponent. Aqui: impacto "médio-grande".
	EventBus.camera_shake_requested.emit(0.5)
	GameFeel.hitstop(0.08)


## Aterrissagem: squash proporcional à velocidade da queda (0..max_fall_speed).
func _on_landed(fall_speed: float) -> void:
	var impact := clampf(fall_speed / stats.max_fall_speed, 0.0, 1.0)
	if impact < 0.25:
		return
	squash.stretch_horizontal(1.0 + 0.4 * impact)
	GameFeel.spawn_effect(GameFeel.DUST, global_position)


func _on_attack_landed(_hurtbox: HurtboxComponent) -> void:
	EventBus.camera_shake_requested.emit(0.15)
	GameFeel.hitstop(0.05)
	GameFeel.spawn_effect(GameFeel.HIT_SPARKS, _attack_shape.global_position)
	# Pogo: acertar algo com o ataque para baixo quica e recarrega pulo/dash no ar.
	if attack_direction == Vector2.DOWN:
		velocity.y = -stats.pogo_velocity
		_refill_air_resources()


func _on_died() -> void:
	set_physics_process(false)
	end_attack()
	state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 0.4)
	EventBus.player_died.emit()
