class_name OneShotEffect
extends CPUParticles2D
## Partícula de disparo único que se libera ao terminar. Use via
## GameFeel.spawn_effect(GameFeel.DUST, posição). CPUParticles2D é a opção
## segura no renderer Compatibility (mobile/web).


func _ready() -> void:
	one_shot = true
	finished.connect(queue_free)
	restart()
