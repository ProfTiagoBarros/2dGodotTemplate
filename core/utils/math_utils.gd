class_name MathUtils
## Funções matemáticas utilitárias para gameplay.


## Interpolação independente de framerate (decaimento exponencial).
## Substitui o clássico `lerp(a, b, k * delta)`, que varia com o FPS.
## `decay` útil entre ~1 (lento) e ~25 (rápido). Ref.: Freya Holmér, "Lerp smoothing is broken".
static func exp_decay(a: float, b: float, decay: float, delta: float) -> float:
	return b + (a - b) * exp(-decay * delta)


static func exp_decay_v2(a: Vector2, b: Vector2, decay: float, delta: float) -> Vector2:
	return b + (a - b) * exp(-decay * delta)


## Velocidade inicial de pulo para atingir `height` em `time_to_apex` segundos.
## De h = v·t - g·t²/2 com v = g·t no ápice  =>  v = 2h/t.
static func jump_velocity(height: float, time_to_apex: float) -> float:
	return 2.0 * height / time_to_apex


## Gravidade necessária para o arco acima: g = 2h/t².
static func jump_gravity(height: float, time_to_apex: float) -> float:
	return 2.0 * height / (time_to_apex * time_to_apex)
