extends Node
## Barramento global de sinais (padrão Observer / Event Bus).
##
## Use SOMENTE para eventos transversais entre sistemas que não se conhecem
## (ex.: Player -> HUD, qualquer coisa -> câmera). Para comunicação dentro de
## uma mesma cena, prefira "call down, signal up": o pai chama métodos dos
## filhos e os filhos emitem sinais locais.

@warning_ignore_start("unused_signal")

# Player
signal player_health_changed(current: int, max_health: int)
signal player_died

# Fluxo de jogo
signal level_completed(level_id: StringName)
signal game_paused(paused: bool)

# Feedback / "juice"
signal camera_shake_requested(trauma: float)

@warning_ignore_restore("unused_signal")
