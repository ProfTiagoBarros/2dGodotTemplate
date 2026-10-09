extends CanvasLayer
## Troca de cenas com fade e carregamento em background (ResourceLoader threaded).
##
## SceneLoader.change_scene(ScenePaths.GAME)
## SceneLoader.reload_current_scene()

signal scene_change_started(path: String)
signal scene_change_finished(path: String)
signal load_progress(progress: float)

const DEFAULT_FADE_TIME := 0.25

var is_changing := false

var _fade: ColorRect


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)


func change_scene(path: String, fade_time: float = DEFAULT_FADE_TIME) -> void:
	if is_changing:
		Log.warn("SceneLoader: troca de cena já em andamento.")
		return
	if not ResourceLoader.exists(path):
		Log.error("SceneLoader: cena não encontrada: %s" % path)
		return

	is_changing = true
	Log.debug("SceneLoader: carregando %s" % path)
	scene_change_started.emit(path)
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP

	# Começa a carregar em paralelo enquanto a tela escurece.
	ResourceLoader.load_threaded_request(path, "PackedScene")
	await _tween_fade(1.0, fade_time)

	var packed: PackedScene = await _wait_for_load(path)
	if packed != null:
		get_tree().paused = false
		get_tree().change_scene_to_packed(packed)
		await get_tree().process_frame

	await _tween_fade(0.0, fade_time)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_changing = false
	scene_change_finished.emit(path)


func reload_current_scene(fade_time: float = DEFAULT_FADE_TIME) -> void:
	var scene := get_tree().current_scene
	if scene != null and not scene.scene_file_path.is_empty():
		change_scene(scene.scene_file_path, fade_time)


func _wait_for_load(path: String) -> PackedScene:
	var progress: Array = []
	while true:
		var status := ResourceLoader.load_threaded_get_status(path, progress)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			load_progress.emit(1.0)
			return ResourceLoader.load_threaded_get(path) as PackedScene
		if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			Log.error("SceneLoader: falha ao carregar %s" % path)
			return null
		load_progress.emit(float(progress[0]) if not progress.is_empty() else 0.0)
		await get_tree().process_frame
	return null


func _tween_fade(target_alpha: float, duration: float) -> void:
	if duration <= 0.0:
		_fade.modulate.a = target_alpha
		return
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", target_alpha, duration)
	await tween.finished
