class_name DebugConsole
extends CanvasLayer
## Console de comandos (F1/`). Mostra a saída do engine (via ConsoleLogger) e
## executa comandos registrados no DebugTools.
## ↑/↓ navegam no histórico, Tab completa o nome do comando, Esc fecha.

const MAX_LINES := 400
const COLOR_ECHO := Color(0.55, 0.75, 1.0)
const COLOR_OUTPUT := Color(0.95, 0.95, 0.95)

var _history: Array[String] = []
var _history_index := -1

@onready var _output: RichTextLabel = %Output
@onready var _input: LineEdit = %Input


func _ready() -> void:
	hide()
	_input.text_submitted.connect(submit)
	_input.gui_input.connect(_on_input_gui_input)


func open() -> void:
	show()
	_input.clear()
	# Adiado: evita que a tecla que abriu o console seja digitada no campo.
	_input.grab_focus.call_deferred()


func close() -> void:
	_input.release_focus()
	hide()


func clear() -> void:
	_output.clear()


func get_text() -> String:
	return _output.get_parsed_text()


func print_line(text: String, color: Color = COLOR_OUTPUT) -> void:
	_output.push_color(color)
	_output.add_text(text)
	_output.pop()
	_output.newline()
	while _output.get_paragraph_count() > MAX_LINES:
		_output.remove_paragraph(0)


## Executa uma linha como se tivesse sido digitada.
func submit(text: String) -> void:
	_input.clear()
	var line := text.strip_edges()
	if line.is_empty():
		return
	if _history.is_empty() or _history[-1] != line:
		_history.append(line)
	_history_index = -1
	print_line("> " + line, COLOR_ECHO)
	var output := DebugTools.execute(line)
	if not output.is_empty():
		print_line(output)


func _on_input_gui_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.is_pressed()):
		return
	match (event as InputEventKey).keycode:
		KEY_UP:
			_browse_history(-1)
		KEY_DOWN:
			_browse_history(1)
		KEY_TAB:
			_autocomplete()
		_:
			return
	_input.accept_event()


func _browse_history(step: int) -> void:
	if _history.is_empty():
		return
	if _history_index == -1:
		_history_index = _history.size()
	_history_index = clampi(_history_index + step, 0, _history.size())
	_input.text = _history[_history_index] if _history_index < _history.size() else ""
	_input.caret_column = _input.text.length()


func _autocomplete() -> void:
	var prefix := _input.text.strip_edges().to_lower()
	var matches := DebugTools.get_command_names().filter(
			func(command_name: String) -> bool: return command_name.begins_with(prefix))
	if matches.size() == 1:
		_input.text = str(matches[0]) + " "
		_input.caret_column = _input.text.length()
	elif matches.size() > 1:
		print_line("  ".join(matches), COLOR_ECHO)
