extends Node
## Log com níveis. Use no lugar de print/push_warning espalhados:
##
##   Log.debug("vel=%s" % velocity)      # detalhe de desenvolvimento
##   Log.info("Fase carregada: %s" % id)  # fluxo normal
##   Log.warn("Save inválido, usando backup")
##   Log.error("Falha ao abrir %s" % path)
##
## DEBUG/INFO vão para print(); WARN/ERROR para push_warning/push_error
## (aparecem no Debugger do editor com stack trace e no console F1).
## Em builds de release o nível mínimo padrão é WARN (menos ruído e custo).

enum LogLevel { DEBUG, INFO, WARN, ERROR }

const LEVEL_NAMES: Array[String] = ["DEBUG", "INFO", "WARN", "ERROR"]

var min_level := LogLevel.DEBUG if OS.is_debug_build() else LogLevel.WARN


func debug(message: String) -> void:
	_write(LogLevel.DEBUG, message)


func info(message: String) -> void:
	_write(LogLevel.INFO, message)


func warn(message: String) -> void:
	_write(LogLevel.WARN, message)


func error(message: String) -> void:
	_write(LogLevel.ERROR, message)


func level_from_name(level_name: String) -> int:
	return LEVEL_NAMES.find(level_name.to_upper())


func _write(level: LogLevel, message: String) -> void:
	if level < min_level:
		return
	var line := "[%s] %s: %s" % [Time.get_time_string_from_system(), LEVEL_NAMES[level], message]
	match level:
		LogLevel.WARN:
			push_warning(line)
		LogLevel.ERROR:
			push_error(line)
		_:
			print(line)
