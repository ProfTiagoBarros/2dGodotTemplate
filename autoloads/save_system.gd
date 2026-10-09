extends Node
## Sistema de save em JSON com versão de schema, escrita atômica e backup.
##
## Fluxo:
##   - `data` é o estado persistente do jogo (Dictionary serializável em JSON).
##   - Nós no grupo "persist" podem implementar `save_state(data)` e
##     `load_state(data)` para gravar/ler seu próprio estado.
##   - Atenção: JSON converte int em float. Use int(...) ao ler números.

signal game_saved(slot: int)
signal game_loaded(slot: int)

const SAVE_VERSION := 1
const SAVE_DIR := "user://saves"
const PERSIST_GROUP := &"persist"

var data: Dictionary = {}
var current_slot := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func new_game(slot: int = 0) -> void:
	current_slot = slot
	data = {}


func has_save(slot: int = 0) -> bool:
	return FileAccess.file_exists(_slot_path(slot))


func save_game(slot: int = current_slot) -> bool:
	current_slot = slot
	get_tree().call_group(PERSIST_GROUP, &"save_state", data)

	var payload := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(true),
		"data": data,
	}
	var path := _slot_path(slot)
	var tmp_path := path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		Log.error("SaveSystem: falha ao abrir %s (%s)" % [tmp_path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()

	# Escrita atômica: o save anterior vira .bak e o .tmp assume o lugar.
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(path + ".bak")
		DirAccess.rename_absolute(path, path + ".bak")
	var err := DirAccess.rename_absolute(tmp_path, path)
	if err != OK:
		Log.error("SaveSystem: falha ao finalizar save (%s)" % error_string(err))
		return false

	Log.debug("SaveSystem: slot %d salvo" % slot)
	game_saved.emit(slot)
	return true


func load_game(slot: int = 0) -> bool:
	var path := _slot_path(slot)
	var payload := _read_json(path)
	if payload.is_empty():
		payload = _read_json(path + ".bak")
	if payload.is_empty():
		return false

	payload = _migrate(payload)
	# Save é entrada NÃO confiável (pode ser editado à mão): valide os tipos.
	var loaded: Variant = payload.get("data", {})
	if not loaded is Dictionary:
		Log.warn("SaveSystem: campo 'data' inválido no slot %d" % slot)
		return false
	data = loaded
	current_slot = slot
	get_tree().call_group(PERSIST_GROUP, &"load_state", data)
	Log.debug("SaveSystem: slot %d carregado" % slot)
	game_loaded.emit(slot)
	return true


## Lê um número inteiro de `data` com segurança (JSON guarda números como
## float, e um save editado pode trazer texto/listas no lugar).
func get_int(key: String, default: int = 0) -> int:
	var value: Variant = data.get(key, default)
	return int(value) if value is int or value is float else default


func delete_save(slot: int = 0) -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		var path := _slot_path(slot) + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	Log.warn("SaveSystem: save inválido em %s" % path)
	return {}


## Atualiza saves antigos para o schema atual, um passo de versão por vez.
func _migrate(payload: Dictionary) -> Dictionary:
	var version := int(payload.get("version", 0))
	while version < SAVE_VERSION:
		match version:
			0:
				pass # Exemplo: renomear/converter campos da v0 para a v1.
		version += 1
	payload["version"] = SAVE_VERSION
	return payload
