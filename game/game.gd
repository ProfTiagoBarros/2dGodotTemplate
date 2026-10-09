class_name Game
extends Node
## Cena de gameplay: monta fase + HUD + controles de toque + pausa
## e cuida do fluxo de jogo (morte, reinício). Não conhece o gênero:
## a fase (Level) diz quais ações os botões de toque disparam.

## Fase carregada ao iniciar. Padrão: ScenePaths.FIRST_LEVEL (definido pelo setup de gênero).
@export_file("*.tscn") var level_path := ScenePaths.FIRST_LEVEL
@export var respawn_delay := 1.0

## Se definido, substitui `level_path` (usado pelo comando de debug `level`;
## persiste entre recarregamentos da cena até ser limpo).
static var level_override := ""

@onready var _world: Node2D = %World
@onready var _touch_controls: TouchControls = %TouchControls
@onready var _hud: GameHUD = %HUD


func _ready() -> void:
	if not level_override.is_empty():
		level_path = level_override
	var packed := load(level_path) as PackedScene
	assert(packed != null, "Fase não encontrada: %s" % level_path)
	Log.info("Fase carregada: %s" % level_path.get_file())
	var level := packed.instantiate() as Level
	_world.add_child(level)
	_touch_controls.configure(level.touch_actions)
	_hud.set_hint_actions(level.hud_hint_actions)
	EventBus.player_died.connect(_on_player_died)


func _on_player_died() -> void:
	# Exemplo de uso do SaveSystem: contador de mortes persistente.
	SaveSystem.data["deaths"] = SaveSystem.get_int("deaths") + 1
	SaveSystem.save_game()
	await get_tree().create_timer(respawn_delay, false).timeout
	SceneLoader.reload_current_scene()
