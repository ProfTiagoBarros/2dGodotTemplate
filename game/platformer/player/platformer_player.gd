class_name PlatformerPlayer
extends PlayerCharacter
## Player de plataforma (side-scrolling / metroidvania). A decisão "o que fazer
## agora" vive nos estados (states/); este script expõe só o que é ESPECÍFICO do
## gênero: movimento, pulo, ataque direcional/pogo e dash. Vida, dano, golpe,
## morte e o sistema de habilidades vêm de Character/PlayerCharacter.
##
## Habilidades usadas aqui: ABILITY_* (as iniciais ficam em `abilities` na cena).

const ABILITY_ATTACK := &"attack"
const ABILITY_DASH := &"dash"
const ABILITY_DOUBLE_JUMP := &"double_jump"
## Animações do golpe para cima/baixo (o lateral usa o nome do estado, "attack").
const ANIM_ATTACK_UP := &"attack_up"
const ANIM_ATTACK_DOWN := &"attack_down"

@export var stats: PlatformerStats
## Empurrão ao levar dano: x = para longe da fonte, y = para cima (negativo).
@export var knockback := Vector2(300.0, -280.0)

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var facing := 1.0
var air_jumps_left := 0
var air_dashes_left := 0
## Direção do ataque atual/último: lado, cima ou baixo (pogo).
var attack_direction := Vector2.RIGHT

var _attack_cooldown_left := 0.0
var _dash_cooldown_left := 0.0
var _was_on_floor := true
var _peak_fall_speed := 0.0


func _ready() -> void:
	super._ready()
	_refill_air_resources()


func _physics_process(delta: float) -> void:
	# Roda antes da StateMachine (o pai é processado antes dos filhos).
	if Input.is_action_just_pressed(Actions.JUMP):
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


#region Ganchos de Character

func get_facing_vector() -> Vector2:
	return Vector2(facing, 0.0)


func apply_knockback(direction: Vector2) -> void:
	var side := signf(direction.x) if not is_zero_approx(direction.x) else -facing
	velocity = Vector2(knockback.x * side, knockback.y)


## Pogo: acertar algo com o ataque para baixo quica e recarrega pulo/dash no ar.
func _on_hit_landed(_hurtbox: HurtboxComponent) -> void:
	if attack_direction == Vector2.DOWN:
		velocity.y = -stats.pogo_velocity
		_refill_air_resources()


## O golpe tem uma animação por direção (attack, attack_up, attack_down).
func animation_for_state(state: StringName) -> StringName:
	if state == PlatformerState.ATTACK:
		if attack_direction == Vector2.UP:
			return ANIM_ATTACK_UP
		if attack_direction == Vector2.DOWN:
			return ANIM_ATTACK_DOWN
	return super.animation_for_state(state)

#endregion


#region Movimento

func get_input_axis() -> float:
	return Input.get_axis(Actions.MOVE_LEFT, Actions.MOVE_RIGHT)


func apply_gravity(delta: float) -> void:
	var rising_with_jump := velocity.y < 0.0 and Input.is_action_pressed(Actions.JUMP)
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
		if not is_attacking():
			face(signf(axis))
	velocity.x = move_toward(velocity.x, axis * stats.max_speed, rate * delta)


func face(direction: float) -> void:
	if is_zero_approx(direction):
		return
	facing = signf(direction)
	visual.scale.x = facing


## Aterrissagem: squash proporcional à velocidade da queda (0..max_fall_speed).
func _on_landed(fall_speed: float) -> void:
	var impact := clampf(fall_speed / stats.max_fall_speed, 0.0, 1.0)
	if impact < 0.25:
		return
	squash.stretch_horizontal(1.0 + 0.4 * impact)
	GameFeel.spawn_effect(GameFeel.DUST, global_position)

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
	return has_ability(ABILITY_ATTACK) and not is_attacking() and _attack_cooldown_left <= 0.0


## Cima (segurando ↑), baixo (no ar segurando ↓ — pogo) ou para o lado.
func get_attack_direction() -> Vector2:
	if Input.is_action_pressed(Actions.MOVE_UP):
		return Vector2.UP
	if not is_on_floor() and Input.is_action_pressed(Actions.MOVE_DOWN):
		return Vector2.DOWN
	return Vector2(facing, 0.0)


func start_attack() -> void:
	attack_direction = get_attack_direction()
	attack_pivot.rotation = attack_direction.angle()
	set_attack_active(true)


func end_attack() -> void:
	if is_attacking():
		_attack_cooldown_left = stats.attack_cooldown
	set_attack_active(false)

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


#region Habilidades

## Destravar no chão recarrega na hora; travar no ar tira o pulo extra.
func _on_abilities_changed() -> void:
	if is_on_floor():
		_refill_air_resources()
	elif not has_ability(ABILITY_DOUBLE_JUMP):
		air_jumps_left = 0


func _refill_air_resources() -> void:
	air_jumps_left = stats.air_jumps if has_ability(ABILITY_DOUBLE_JUMP) else 0
	air_dashes_left = stats.air_dashes

#endregion
