class_name HurtboxComponent
extends Area2D
## Área que RECEBE dano de HitboxComponents sobrepostos e repassa ao HealthComponent.
## Camada sugerida: "hurtboxes" (layer 5), máscara: "hitboxes" (layer 4).
## Checa sobreposição a cada frame de física, então ficar parado sobre
## espinhos continua causando dano assim que os i-frames acabam.
##
## Ignora hitboxes da mesma entidade (mesmo `owner`) e do mesmo `team`
## (sem fogo amigo). Hitboxes sem time (neutros) ferem todos.

signal hit_received(hitbox: HitboxComponent)

@export var health: HealthComponent
## Time desta entidade ("player", "enemy"...). Vazio = recebe dano de todos.
@export var team: StringName = &""


func _ready() -> void:
	# Performance: só processa enquanto algo sobrepõe (dorme no resto do tempo).
	set_physics_process(false)
	area_entered.connect(_on_area_entered)


func _physics_process(_delta: float) -> void:
	if not has_overlapping_areas():
		set_physics_process(false)
		return
	if health == null or health.is_invulnerable():
		return
	for area: Area2D in get_overlapping_areas():
		var hitbox := area as HitboxComponent
		if hitbox == null or not can_be_hit_by(hitbox):
			continue
		if health.take_damage(hitbox.damage, hitbox):
			hit_received.emit(hitbox)
			hitbox.hit_landed.emit(self)
			return


func _on_area_entered(_area: Area2D) -> void:
	set_physics_process(true)


func can_be_hit_by(hitbox: HitboxComponent) -> bool:
	if hitbox.owner == owner:
		return false
	return team.is_empty() or hitbox.team.is_empty() or hitbox.team != team
