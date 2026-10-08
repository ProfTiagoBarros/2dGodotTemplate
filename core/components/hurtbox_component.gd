class_name HurtboxComponent
extends Area2D
## Área que RECEBE dano de HitboxComponents sobrepostos e repassa ao HealthComponent.
## Camada sugerida: "hurtboxes" (layer 5), máscara: "hitboxes" (layer 4).
## Checa sobreposição a cada frame de física, então ficar parado sobre
## espinhos continua causando dano assim que os i-frames acabam.
## Hitboxes da mesma entidade (mesmo `owner`) são ignoradas, então o ataque
## do player nunca acerta o próprio player.

signal hit_received(hitbox: HitboxComponent)

@export var health: HealthComponent


func _physics_process(_delta: float) -> void:
	if health == null or health.is_invulnerable() or not has_overlapping_areas():
		return
	for area: Area2D in get_overlapping_areas():
		var hitbox := area as HitboxComponent
		if hitbox == null or hitbox.owner == owner:
			continue
		if health.take_damage(hitbox.damage, hitbox):
			hit_received.emit(hitbox)
			hitbox.hit_landed.emit(self)
			return
