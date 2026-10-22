class_name PauseController
## Pausa coordenada por MOTIVOS. Vários sistemas podem pausar o jogo ao mesmo
## tempo (menu de pausa, console de debug, cutscene, diálogo...); o jogo só
## volta a rodar quando NENHUM motivo continua ativo.
##
##   PauseController.request(&"menu")   # pausa (ou mantém pausado)
##   PauseController.release(&"menu")   # despausa só se não houver outro motivo
##
## Nunca altere `get_tree().paused` direto: um sistema despausaria o jogo por
## cima de outro (ex.: fechar o console com o menu de pausa aberto).

static var _reasons: Dictionary[StringName, bool] = {}


static func request(reason: StringName) -> void:
	_reasons[reason] = true
	_apply()


static func release(reason: StringName) -> void:
	_reasons.erase(reason)
	_apply()


static func is_requested(reason: StringName) -> bool:
	return _reasons.has(reason)


static func is_paused() -> bool:
	return not _reasons.is_empty()


## Remove todos os motivos (ex.: ao trocar de cena, a nova começa rodando).
static func clear() -> void:
	_reasons.clear()
	_apply()


static func _apply() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.paused = not _reasons.is_empty()
