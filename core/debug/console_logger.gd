class_name ConsoleLogger
extends Logger
## Captura TODA a saída do engine (print, avisos, erros de script/engine) para
## exibir no console de debug. Registrado com OS.add_logger().
##
## Os métodos podem ser chamados de qualquer thread: só enfileira sob Mutex.
## Quem consome (DebugTools) drena a fila no thread principal.

const MAX_PENDING := 500

const COLOR_MESSAGE := Color(0.88, 0.88, 0.9)
const COLOR_DEBUG := Color(0.6, 0.6, 0.68)
const COLOR_STDERR := Color(1.0, 0.7, 0.45)
const COLOR_WARNING := Color(1.0, 0.85, 0.35)
const COLOR_ERROR := Color(1.0, 0.42, 0.42)

var _mutex := Mutex.new()
var _pending: Array[Dictionary] = []


func _log_message(message: String, error: bool) -> void:
	var text := message.strip_edges(false, true)
	var color := COLOR_STDERR if error else COLOR_MESSAGE
	if not error and "] DEBUG: " in text.substr(0, 20):
		color = COLOR_DEBUG
	_push(text, color)


func _log_error(function: String, file: String, line: int, code: String, rationale: String,
		_editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
	var text := rationale if not rationale.is_empty() else code
	var location := "%s:%d (%s)" % [file.get_file(), line, function]
	# Para erros vindos de GDScript, a posição útil é a do script, não a do C++.
	for backtrace: ScriptBacktrace in script_backtraces:
		if backtrace != null and backtrace.get_frame_count() > 0:
			location = "%s:%d (%s)" % [backtrace.get_frame_file(0), backtrace.get_frame_line(0),
					backtrace.get_frame_function(0)]
			break
	var is_warning := error_type == Logger.ERROR_TYPE_WARNING
	_push("%s %s\n    em %s" % ["AVISO:" if is_warning else "ERRO:", text, location],
			COLOR_WARNING if is_warning else COLOR_ERROR)


## Retorna e limpa as mensagens pendentes: [{text, color}, ...].
func drain() -> Array[Dictionary]:
	_mutex.lock()
	var result := _pending
	_pending = []
	_mutex.unlock()
	return result


func _push(text: String, color: Color) -> void:
	_mutex.lock()
	_pending.append({"text": text, "color": color})
	if _pending.size() > MAX_PENDING:
		_pending.pop_front()
	_mutex.unlock()
