@tool
extends EditorPlugin
## Adiciona Project > Tools > "Configurar novo jogo…", que abre o assistente.

const MENU_ITEM := "Configurar novo jogo…"
const WizardDialog := preload("res://addons/project_wizard/wizard_dialog.gd")

var _dialog: ConfirmationDialog


func _enter_tree() -> void:
	add_tool_menu_item(MENU_ITEM, _open)


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_ITEM)
	if is_instance_valid(_dialog):
		_dialog.queue_free()


func _open() -> void:
	if not is_instance_valid(_dialog):
		_dialog = WizardDialog.new()
		EditorInterface.get_base_control().add_child(_dialog)
	_dialog.refresh()
	_dialog.popup_centered(Vector2i(680, 620))
