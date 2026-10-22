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


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	attack_hitbox.hit_landed.connect(_on_attack_landed)
	set_attack_active(false)


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

#endregion


#region API comum

func is_attacking() -> bool:
	return _attacking


## Liga/desliga a hitbox do golpe (forma de colisão + visual do golpe).
func set_attack_active(active: bool) -> void:
	_attacking = active
	_attack_shape.set_deferred(&"disabled", not active)
	attack_hitbox.visible = active


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


func _on_died() -> void:
	set_physics_process(false)
	state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	set_attack_active(false)
	_play_death()
