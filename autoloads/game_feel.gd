extends Node
## Kit de "game feel" (juice). Peças:
##   - Hitstop ............ GameFeel.hitstop(0.06)            (este autoload)
##   - Efeitos pontuais ... GameFeel.spawn_effect(GameFeel.DUST, pos)
##   - Screen shake ....... EventBus.camera_shake_requested.emit(0.4)  (GameCamera)
##   - Flash de dano ...... nó HitFlashComponent (core/feel/)
##   - Squash & stretch ... nó SquashStretch (core/feel/)
##
## Regra prática: impactos pequenos = flash + faísca; médios = + hitstop curto;
## grandes = + shake. Exagerar tudo em todo golpe cansa.

## Útil para sincronizar áudio/efeitos com o impacto (e para testes).
signal hitstop_started(duration: float)

const DUST := preload("res://core/feel/effects/dust_puff.tscn")
const HIT_SPARKS := preload("res://core/feel/effects/hit_sparks.tscn")

var _hitstop_end_ms := 0
var _time_scale_before := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


## Congela (quase) o jogo por `duration` segundos de tempo REAL, sem ser afetado
## pelo próprio time_scale. Chamadas sobrepostas estendem até o maior fim.
## Respeita a opção "Pausa de Impacto" (Settings: game/hitstop).
func hitstop(duration: float = 0.06, slow_scale: float = 0.05) -> void:
	if duration <= 0.0 or not Settings.get_value("game", "hitstop"):
		return
	if not is_hitstop_active():
		_time_scale_before = Engine.time_scale
	Engine.time_scale = _time_scale_before * slow_scale
	_hitstop_end_ms = maxi(_hitstop_end_ms, Time.get_ticks_msec() + int(duration * 1000.0))
	set_process(true)
	hitstop_started.emit(duration)


func is_hitstop_active() -> bool:
	return _hitstop_end_ms > 0


## Instancia um efeito (ex.: GameFeel.DUST) na cena atual, em coordenadas globais.
func spawn_effect(effect: PackedScene, at: Vector2, rotation: float = 0.0) -> Node2D:
	var scene := get_tree().current_scene
	if effect == null or scene == null:
		return null
	var node := effect.instantiate() as Node2D
	scene.add_child(node)
	node.global_position = at
	node.rotation = rotation
	return node


func _process(_delta: float) -> void:
	if Time.get_ticks_msec() >= _hitstop_end_ms:
		Engine.time_scale = _time_scale_before
		_hitstop_end_ms = 0
		set_process(false)
