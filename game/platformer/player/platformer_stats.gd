class_name PlatformerStats
extends Resource
## Parâmetros de movimento/combate como Resource (data-driven): crie variações
## .tres para personagens diferentes ou power-ups sem tocar no código.
##
## O pulo é definido por ALTURA e TEMPO (mais intuitivo para game design),
## e a velocidade/gravidade são derivadas (ver MathUtils.jump_velocity).

@export_group("Horizontal")
@export var max_speed := 140.0
@export var acceleration := 1000.0
@export var friction := 1400.0
@export var air_acceleration := 700.0
@export var air_friction := 350.0

@export_group("Jump")
## Altura máxima do pulo, em pixels.
@export var jump_height := 52.0
## Tempo até o ápice (s). Menor = pulo mais "rápido".
@export var time_to_apex := 0.38
## Tempo do ápice ao chão (s). Menor que time_to_apex dá queda mais pesada.
@export var time_to_descent := 0.3
@export var max_fall_speed := 420.0
## Pulos extras no ar (exige a habilidade "double_jump").
@export var air_jumps := 1

@export_group("Assists")
## Janela para pular depois de sair da borda.
@export var coyote_time := 0.1
## Janela para "lembrar" o botão de pulo apertado antes de tocar o chão.
@export var jump_buffer_time := 0.12

@export_group("Attack")
## Tempo em que a hitbox do ataque fica ativa (s).
@export var attack_duration := 0.15
## Intervalo mínimo entre o fim de um ataque e o próximo (s).
@export var attack_cooldown := 0.12
## Impulso para cima ao acertar algo com o ataque para baixo (pogo).
@export var pogo_velocity := 260.0

@export_group("Dash")
@export var dash_speed := 320.0
## Duração (s). Distância ≈ dash_speed × dash_duration.
@export var dash_duration := 0.16
@export var dash_cooldown := 0.35
## Dashes permitidos por "tempo no ar" (recarrega no chão ou no pogo).
@export var air_dashes := 1
@export var dash_invulnerable := true

var jump_velocity: float:
	get:
		return MathUtils.jump_velocity(jump_height, time_to_apex)

## Gravidade enquanto sobe segurando pulo.
var jump_gravity: float:
	get:
		return MathUtils.jump_gravity(jump_height, time_to_apex)

## Gravidade na queda (e ao soltar o pulo cedo => pulo de altura variável).
var fall_gravity: float:
	get:
		return MathUtils.jump_gravity(jump_height, time_to_descent)
