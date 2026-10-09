class_name DebugOverlay
extends CanvasLayer
## Overlay F3: métricas do engine + "watches" registrados no DebugTools.
## Atualiza poucas vezes por segundo para não pesar (e ficar legível).

const REFRESH_INTERVAL := 0.25

var _elapsed := REFRESH_INTERVAL

@onready var _label: Label = %StatsLabel


func _ready() -> void:
	hide()


func _process(delta: float) -> void:
	if not visible:
		return
	_elapsed += delta
	if _elapsed < REFRESH_INTERVAL:
		return
	_elapsed = 0.0
	_label.text = "\n".join(_build_lines())


func _build_lines() -> Array[String]:
	var fps := Performance.get_monitor(Performance.TIME_FPS)
	var frame_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var scene := get_tree().current_scene
	var lines: Array[String] = [
		"FPS %d  |  frame %.1f ms  |  física %.1f ms" % [fps, frame_ms, physics_ms],
		"Draw calls %d  |  nós %d  |  objetos %d" % [
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			Performance.get_monitor(Performance.OBJECT_COUNT),
		],
		"Memória %.1f MB  |  time_scale %.2f" % [
			Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, Engine.time_scale],
		"Cena: %s" % (scene.scene_file_path.get_file() if scene != null else "-"),
		"Input: %s%s" % [
			InputManager.Device.keys()[InputManager.current_device],
			" (mouse)" if InputManager.using_mouse else "",
		],
	]
	lines.append_array(DebugTools.get_watch_lines())
	return lines
