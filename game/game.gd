class_name Game
extends Node
## Cena de gameplay: monta fase + HUD + controles de toque + pausa
## e cuida do fluxo de jogo (morte, reinício). Não conhece o gênero:
## a fase (Level) diz quais ações os botões de toque disparam.

## Fase carregada ao iniciar. Padrão: ScenePaths.FIRST_LEVEL (definido pelo setup de gênero).
@export_file("*.tscn") var level_path := ScenePaths.FIRST_LEVEL
@export var respawn_delay := 1.0

@onready var _world: Node2D = %World
@onready var _touch_controls: TouchControls = %TouchControls


func _ready() -> void:
	var packed := load(level_path) as PackedScene
	assert(packed != null, "Fase não encontrada: %s" % level_path)
	var level := packed.instantiate() as Level
	_world.add_child(level)
	_touch_controls.configure(level.touch_primary_action, level.touch_secondary_action)
	EventBus.player_died.connect(_on_player_died)


func _on_player_died() -> void:
	# Exemplo de uso do SaveSystem: contador de mortes persistente.
	SaveSystem.data["deaths"] = int(SaveSystem.data.get("deaths", 0)) + 1
	SaveSystem.save_game()
	await get_tree().create_timer(respawn_delay, false).timeout
	SceneLoader.reload_current_scene()
