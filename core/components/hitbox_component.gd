class_name HitboxComponent
extends Area2D
## Área que CAUSA dano. Detectada por HurtboxComponent.
## Camada sugerida: "hitboxes" (layer 4). Não precisa monitorar nada.

signal hit_landed(hurtbox: HurtboxComponent)

@export var damage := 1
