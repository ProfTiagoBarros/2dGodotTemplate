@abstract
class_name Character
extends CharacterBody2D
## Base de TODO personagem de combate (players e inimigos, de qualquer gênero).
##
## Divisão de responsabilidades:
##   - CAPACIDADES vêm de componentes (HealthComponent, Hitbox/Hurtbox,
##     HitFlashComponent, SquashStretch): composição.
##   - O CICLO DE VIDA de combate é fixo aqui (Template Method) e cada
##     personagem só preenche os ganchos @abstract:
##       levou dano      -> apply_knockback() -> tremor/hitstop -> _on_hurt()
##       golpe acertou   -> tremor/hitstop/faíscas -> _on_hit_landed()
##       morreu          -> desliga física, IA e hitbox -> _play_death()
##
## Um personagem que não implemente os ganchos obrigatórios é recusado pelo
## compilador (não só em tempo de execução).
##
## Cena esperada: Visual/Squash, HealthComponent, StateMachine,
## AttackPivot/AttackHitbox/CollisionShape2D.
##
## Animação (opcional): com um AnimatedSprite2D em Visual/Squash/Sprite, cada
## estado da StateMachine toca a animação de mesmo nome em snake_case ("Idle"
## -> "idle"). Personagens que variam por contexto (direção do golpe, direção
## do olhar) sobrescrevem animation_for_state().

@export_group("Game feel")
## Tremor de tela quando ESTE personagem leva dano (0 = nenhum).
@export_range(0.0, 1.0, 0.05) var hurt_shake := 0.5
## Hitstop quando ESTE personagem leva dano (s).
@export_range(0.0, 0.3, 0.01) var hurt_hitstop := 0.08
## Tremor de tela quando o golpe DESTE personagem acerta.
@export_range(0.0, 1.0, 0.05) var hit_shake := 0.15
## Hitstop quando o golpe DESTE personagem acerta (s).
@export_range(0.0, 0.3, 0.01) var hit_hitstop := 0.05

var _attacking := false

@onready var visual: Node2D = $Visual
@onready var squash: SquashStretch = $Visual/Squash
@onready var health: HealthComponent = $HealthComponent
@onready var state_machine: StateMachine = $StateMachine
@onready var attack_pivot: Node2D = $AttackPivot
@onready var attack_hitbox: HitboxComponent = $AttackPivot/AttackHitbox
@onready var _attack_shape: CollisionShape2D = $AttackPivot/AttackHitbox/CollisionShape2D
@onready var sprite: AnimatedSprite2D = get_node_or_null(^"Visual/Squash/Sprite") as AnimatedSprite2D


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	attack_hitbox.hit_landed.connect(_on_attack_landed)
	set_attack_active(false)
	if sprite != null:
		state_machine.state_changed.connect(_on_state_changed)
		# O estado inicial entra depois do _ready (a StateMachine espera o dono).
		refresh_animation.call_deferred()


#region Ganchos (implementados por cada personagem)

## Direção para onde o personagem olha (unitária). Usada como fallback do
## knockback quando o dano não tem posição de origem.
@abstract func get_facing_vector() -> Vector2


## Empurrão ao levar dano. `direction` (unitária) aponta para LONGE da fonte.
@abstract func apply_knockback(direction: Vector2) -> void


## Animação/efeitos de morte. Física, IA e hitbox já foram desligadas.
@abstract func _play_death() -> void


## Reação extra ao dano, depois do knockback (ex.: inimigo entra em Hurt).
func _on_hurt(_amount: int, _source: Node) -> void:
	pass


## Reação extra quando o próprio golpe acerta (ex.: pogo do platformer).
func _on_hit_landed(_hurtbox: HurtboxComponent) -> void:
	pass


## Animação do `sprite` para o estado `state` (padrão: nome em snake_case).
func animation_for_state(state: StringName) -> StringName:
	return StringName(String(state).to_snake_case())

#endregion


#region API comum

func is_attacking() -> bool:
	return _attacking


## Liga/desliga a hitbox do golpe (forma de colisão + visual do golpe).
func set_attack_active(active: bool) -> void:
	_attacking = active
	_attack_shape.set_deferred(&"disabled", not active)
	attack_hitbox.visible = active


## Atualiza a animação sem reiniciá-la (ex.: o olhar mudou de direção no meio
## de uma caminhada): troca o clipe e mantém o quadro, para o passo não "pular".
func refresh_animation() -> void:
	if sprite == null or state_machine.current_state == null:
		return
	var anim := animation_for_state(state_machine.current_state.name)
	if anim == sprite.animation or not sprite.sprite_frames.has_animation(anim):
		return
	var frame := sprite.frame
	var progress := sprite.frame_progress
	sprite.play(anim)
	if frame < sprite.sprite_frames.get_frame_count(anim):
		sprite.set_frame_and_progress(frame, progress)


## Direção unitária para longe de `source`. Usa `fallback` se a fonte não tiver
## posição (ex.: dano por veneno) ou estiver exatamente no mesmo ponto.
func direction_away_from(source: Node, fallback: Vector2) -> Vector2:
	if source is Node2D:
		var offset := global_position - (source as Node2D).global_position
		if not offset.is_zero_approx():
			return offset.normalized()
	return fallback

#endregion


func _on_damaged(amount: int, source: Node) -> void:
	apply_knockback(direction_away_from(source, -get_facing_vector()))
	if hurt_shake > 0.0:
		EventBus.camera_shake_requested.emit(hurt_shake)
	GameFeel.hitstop(hurt_hitstop)
	_on_hurt(amount, source)


func _on_attack_landed(hurtbox: HurtboxComponent) -> void:
	if hit_shake > 0.0:
		EventBus.camera_shake_requested.emit(hit_shake)
	GameFeel.hitstop(hit_hitstop)
	GameFeel.spawn_effect(GameFeel.HIT_SPARKS, _attack_shape.global_position)
	_on_hit_landed(hurtbox)


func _on_state_changed(_from: StringName, to: StringName) -> void:
	# Estado novo sempre começa a animação do início (ex.: dois golpes seguidos).
	var anim := animation_for_state(to)
	if sprite.sprite_frames.has_animation(anim):
		sprite.stop()
		sprite.play(anim)


func _on_died() -> void:
	set_physics_process(false)
	state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	set_attack_active(false)
	_play_death()
