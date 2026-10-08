extends Node
## Configurações do usuário, persistidas em user://settings.cfg (ConfigFile).
##
## Leitura:  Settings.get_value("audio", "Music")
## Escrita:  Settings.set_value("audio", "Music", 0.5)  -> aplica e emite `changed`
## Chame Settings.save() ao sair de uma tela de opções.

signal changed(section: String, key: String, value: Variant)

const PATH := "user://settings.cfg"

## Valores padrão. Adicione novas opções aqui; elas são mescladas com o
## arquivo salvo, então versões antigas do arquivo continuam funcionando.
const DEFAULTS := {
	"audio": {
		"Master": 1.0,
		"Music": 0.8,
		"SFX": 1.0,
		"UI": 1.0,
	},
	"video": {
		"fullscreen": false,
		"vsync": true,
	},
	"game": {
		"locale": "", # "" = idioma do sistema
		"screen_shake": true,
		"touch_controls": "auto", # auto | always | never
	},
}

var _config := ConfigFile.new()


func _ready() -> void:
	_load()
	apply_all()


func get_value(section: String, key: String) -> Variant:
	if _config.has_section_key(section, key):
		return _config.get_value(section, key)
	var section_defaults: Dictionary = DEFAULTS.get(section, {})
	return section_defaults.get(key)


func set_value(section: String, key: String, value: Variant, persist: bool = false) -> void:
	_config.set_value(section, key, value)
	_apply(section, key, value)
	changed.emit(section, key, value)
	if persist:
		save()


func erase_value(section: String, key: String) -> void:
	if _config.has_section_key(section, key):
		_config.erase_section_key(section, key)


func save() -> void:
	var err := _config.save(PATH)
	if err != OK:
		push_warning("Settings: falha ao salvar (%s)" % error_string(err))


func apply_all() -> void:
	for section: String in _config.get_sections():
		for key: String in _config.get_section_keys(section):
			_apply(section, key, _config.get_value(section, key))


func _load() -> void:
	for section: String in DEFAULTS:
		var values: Dictionary = DEFAULTS[section]
		for key: String in values:
			_config.set_value(section, key, values[key])

	if not FileAccess.file_exists(PATH):
		return
	var saved := ConfigFile.new()
	if saved.load(PATH) != OK:
		push_warning("Settings: arquivo corrompido, usando padrões.")
		return
	for section: String in saved.get_sections():
		for key: String in saved.get_section_keys(section):
			_config.set_value(section, key, saved.get_value(section, key))


func _apply(section: String, key: String, value: Variant) -> void:
	match section:
		"audio":
			var bus := AudioServer.get_bus_index(key)
			if bus != -1:
				AudioServer.set_bus_volume_linear(bus, float(value))
		"video":
			_apply_video(key, value)
		"game":
			if key == "locale":
				var locale := str(value)
				TranslationServer.set_locale(locale if not locale.is_empty() else OS.get_locale())


func _apply_video(key: String, value: Variant) -> void:
	if not PlatformUtils.is_desktop() or DisplayServer.get_name() == "headless":
		return
	match key:
		"fullscreen":
			var mode := DisplayServer.window_get_mode()
			var is_fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
					or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
			if bool(value) and not is_fullscreen:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			elif not bool(value) and is_fullscreen:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		"vsync":
			DisplayServer.window_set_vsync_mode(
					DisplayServer.VSYNC_ENABLED if bool(value) else DisplayServer.VSYNC_DISABLED)
