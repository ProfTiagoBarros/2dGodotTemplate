extends Node
## Configurações do usuário, persistidas em user://settings.cfg (ConfigFile).
##
## Leitura:  Settings.get_value(Settings.GAME, Settings.HITSTOP)
## Escrita:  Settings.set_value(Settings.AUDIO, "Music", 0.5)  -> aplica e emite `changed`
## Use as constantes de seção/chave abaixo, nunca texto solto.
## Chame Settings.save() ao sair de uma tela de opções.

signal changed(section: String, key: String, value: Variant)

const PATH := "user://settings.cfg"

#region Seções e chaves
## Volumes. As chaves são os nomes dos buses (AudioManager.*_BUS).
const AUDIO := "audio"
const VIDEO := "video"
const GAME := "game"
## Atalhos remapeados (gerenciada pelo InputBindings; chave = ação).
const INPUT := "input"

const FULLSCREEN := "fullscreen"
const VSYNC := "vsync"
## "" = idioma do sistema.
const LOCALE := "locale"
const SCREEN_SHAKE := "screen_shake"
const HITSTOP := "hitstop"
## Um dos TOUCH_*.
const TOUCH_CONTROLS := "touch_controls"

## Valores de TOUCH_CONTROLS. AUTO = só quando o último input foi toque.
const TOUCH_AUTO := "auto"
const TOUCH_ALWAYS := "always"
const TOUCH_NEVER := "never"
#endregion

## Valores padrão. Adicione novas opções aqui; elas são mescladas com o
## arquivo salvo, então versões antigas do arquivo continuam funcionando.
const DEFAULTS := {
	AUDIO: {
		"Master": 1.0,
		"Music": 0.8,
		"SFX": 1.0,
		"UI": 1.0,
	},
	VIDEO: {
		FULLSCREEN: false,
		VSYNC: true,
	},
	GAME: {
		LOCALE: "",
		SCREEN_SHAKE: true,
		HITSTOP: true,
		TOUCH_CONTROLS: TOUCH_AUTO,
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
		Log.warn("Settings: falha ao salvar (%s)" % error_string(err))


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
	# NUNCA ConfigFile.load() direto em user://: pode executar código (ver SafeConfig).
	var saved := SafeConfig.load_file(PATH)
	if saved == null:
		Log.warn("Settings: arquivo inválido ou inseguro, usando padrões.")
		return
	for section: String in saved.get_sections():
		for key: String in saved.get_section_keys(section):
			var value: Variant = saved.get_value(section, key)
			if is_valid_value(section, key, value):
				_config.set_value(section, key, value)
			else:
				Log.warn("Settings: valor ignorado [%s] %s" % [section, key])


## Aceita só chaves conhecidas com o tipo do valor padrão (int vale onde se
## espera float). A seção INPUT (atalhos remapeados) aceita listas; o
## conteúdo é validado pelo InputBindings.
func is_valid_value(section: String, key: String, value: Variant) -> bool:
	if section == INPUT:
		return value is Array
	var section_defaults: Dictionary = DEFAULTS.get(section, {})
	if not section_defaults.has(key):
		return false
	var expected := typeof(section_defaults[key])
	return typeof(value) == expected or (expected == TYPE_FLOAT and value is int)


func _apply(section: String, key: String, value: Variant) -> void:
	match section:
		AUDIO:
			var bus := AudioServer.get_bus_index(key)
			if bus != -1:
				AudioServer.set_bus_volume_linear(bus, clampf(float(value), 0.0, 1.0))
		VIDEO:
			_apply_video(key, value)
		GAME:
			if key == LOCALE:
				var locale := str(value)
				TranslationServer.set_locale(locale if not locale.is_empty() else OS.get_locale())


func _apply_video(key: String, value: Variant) -> void:
	if not PlatformUtils.is_desktop() or DisplayServer.get_name() == "headless":
		return
	match key:
		FULLSCREEN:
			var mode := DisplayServer.window_get_mode()
			var is_fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
					or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
			if bool(value) and not is_fullscreen:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			elif not bool(value) and is_fullscreen:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		VSYNC:
			DisplayServer.window_set_vsync_mode(
					DisplayServer.VSYNC_ENABLED if bool(value) else DisplayServer.VSYNC_DISABLED)
