class_name HitboxComponent
extends Area2D
## Área que CAUSA dano. Detectada por HurtboxComponent.
## Camada sugerida: "hitboxes" (layer 4). Não precisa monitorar nada.

signal hit_landed(hurtbox: HurtboxComponent)

@export var damage := 1
## Time de quem causa o dano ("player", "enemy"...). Hurtboxes do MESMO time
## ignoram este hitbox (sem fogo amigo). Vazio = neutro: fere todo mundo
## (ex.: espinhos, lava).
@export var team: StringName = &""
