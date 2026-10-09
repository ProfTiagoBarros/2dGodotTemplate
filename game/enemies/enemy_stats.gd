class_name EnemyStats
extends Resource
## Parâmetros de um tipo de inimigo (data-driven): um .tres por tipo
## ("walker", "slime"...) muda o comportamento sem tocar no código.

@export_group("Movement")
@export var patrol_speed := 35.0
@export var chase_speed := 75.0
@export var acceleration := 600.0
## Só usados por inimigos com gravidade (platformer).
@export var gravity := 900.0
@export var max_fall_speed := 420.0

@export_group("Senses")
## Distância para NOTAR o player (com linha de visão).
@export var detection_radius := 110.0
## Distância para PERDER o player. Maior que detection_radius (histerese):
## evita alternar patrulha/perseguição quando o player está na borda.
@export var lose_target_radius := 170.0

@export_group("Attack")
## Distância para iniciar o ataque.
@export var attack_range := 30.0
## Tempo de "aviso" antes do bote. Curto demais = injusto; longo = fácil.
@export var windup_time := 0.4
@export var windup_color := Color(1.0, 0.45, 0.45)
@export var lunge_speed := 200.0
@export var lunge_time := 0.2
## Pausa depois do bote: a janela para o jogador contra-atacar.
@export var recover_time := 0.6

@export_group("Hurt")
## Tempo atordoado após levar dano (interrompe o ataque).
@export var hurt_time := 0.25
@export var knockback_speed := 150.0
