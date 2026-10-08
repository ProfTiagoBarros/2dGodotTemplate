class_name TopDownStats
extends Resource
## Parâmetros do player top-down como Resource (data-driven).

@export_group("Movement")
@export var max_speed := 110.0
@export var acceleration := 900.0
@export var friction := 1100.0

@export_group("Dash")
@export var dash_speed := 300.0
## Duração do dash (s). Distância percorrida ≈ dash_speed × dash_duration.
@export var dash_duration := 0.15
@export var dash_cooldown := 0.4

@export_group("Combat")
## Tempo em que a hitbox do ataque fica ativa (s).
@export var attack_duration := 0.18
@export var knockback_speed := 180.0
