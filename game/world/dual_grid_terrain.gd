@tool
class_name DualGridTerrain
extends TileMapLayer
## Camada VISUAL para tilesets de cantos ("Wang" de 16 tiles, como os gerados
## pelo PixelLab). Você pinta só a camada lógica `source`, e esta camada escolhe
## sozinha o tile de cada borda e canto ("dual grid").
##
## Como funciona: esta camada fica deslocada meio tile em relação à `source`.
## Assim, cada tile visual cobre o encontro de 4 células lógicas, e os 4 cantos
## dele dizem qual dos 16 tiles desenhar. A borda visual cai exatamente na borda
## das células pintadas, então a colisão (que fica na `source`) bate com a arte.
##
## Na `source`, o tile LOWER_MARKER marca o terreno "de baixo" (ex.: rua) e
## qualquer outro tile marca o terreno "de cima" (ex.: bloco, calçada). A
## `source` some ao rodar o jogo, mas continua com a colisão dos tiles dela.

enum FillMode {
	## Desenha só onde há terreno "de cima" (platformer: blocos no vazio).
	UPPER_ONLY,
	## Desenha toda a área pintada, com os dois terrenos (top-down: chão inteiro).
	PAINTED_AREA,
}

## Layout padrão das folhas do PixelLab: o tile de máscara N (NO=8, NE=4, SO=2,
## SE=1; 1 = terreno de cima) é o "wang_N" do metadata, nesta posição do atlas.
const PIXELLAB_LAYOUT: Array[Vector2i] = [
	Vector2i(2, 1), Vector2i(3, 1), Vector2i(2, 2), Vector2i(1, 2),
	Vector2i(2, 0), Vector2i(3, 2), Vector2i(0, 1), Vector2i(3, 3),
	Vector2i(1, 1), Vector2i(2, 3), Vector2i(1, 0), Vector2i(0, 2),
	Vector2i(3, 0), Vector2i(0, 0), Vector2i(1, 3), Vector2i(0, 3),
]
## Tile da `source` que marca o terreno de baixo.
const LOWER_MARKER := Vector2i(0, 0)
## Opacidade da camada lógica no editor (para ver o que foi pintado).
const EDITOR_SOURCE_ALPHA := 0.35
## Intervalo entre checagens de mudança na `source`, só no editor (s).
const EDITOR_POLL_INTERVAL := 0.2

enum Terrain { NONE = -1, LOWER = 0, UPPER = 1 }

## Camada lógica pintada à mão (tem a colisão, quando o tileset dela tiver).
@export var source: TileMapLayer:
	set(value):
		source = value
		rebuild()
@export var fill_mode := FillMode.UPPER_ONLY:
	set(value):
		fill_mode = value
		rebuild()
## Tilesets em que o terreno pintado é o "lower" do metadata. Os tilesets
## laterais (sidescroller) do PixelLab são assim: lower = bloco, upper = ar.
@export var painted_is_lower := false:
	set(value):
		painted_is_lower = value
		rebuild()
## Atlas de cada máscara de cantos (16 entradas). Troque se o seu tileset de
## cantos usar outra ordem.
@export var tiles_by_mask: Array[Vector2i] = PIXELLAB_LAYOUT.duplicate()
@export var atlas_source_id := 0

var _last_source_data := PackedByteArray()
var _poll_left := 0.0


func _ready() -> void:
	if source != null and not Engine.is_editor_hint():
		source.self_modulate.a = 0.0
	rebuild()
	set_process(Engine.is_editor_hint())


func _process(delta: float) -> void:
	# No editor: refaz o visual quando alguém pinta a `source`.
	_poll_left -= delta
	if _poll_left > 0.0 or source == null:
		return
	_poll_left = EDITOR_POLL_INTERVAL
	if source.tile_map_data != _last_source_data:
		rebuild()


func rebuild() -> void:
	if not is_inside_tree():
		return
	clear()
	if source == null or tile_set == null or tiles_by_mask.size() < 16:
		return
	_last_source_data = source.tile_map_data
	if Engine.is_editor_hint():
		source.self_modulate.a = EDITOR_SOURCE_ALPHA
	position = source.position - Vector2(tile_set.tile_size) * 0.5
	var used := source.get_used_rect()
	for y in range(used.position.y, used.end.y + 1):
		for x in range(used.position.x, used.end.x + 1):
			_place(Vector2i(x, y))


## Máscara de cantos do tile visual `cell` (-1 = não desenhar).
func mask_at(cell: Vector2i) -> int:
	var corners: Array[int] = [
		terrain_at(cell + Vector2i(-1, -1)), terrain_at(cell + Vector2i(0, -1)),
		terrain_at(cell + Vector2i(-1, 0)), terrain_at(cell),
	]
	if fill_mode == FillMode.PAINTED_AREA and Terrain.NONE in corners:
		return -1
	var mask := 0
	for i in corners.size():
		if corners[i] == Terrain.UPPER:
			mask |= 8 >> i
	if fill_mode == FillMode.UPPER_ONLY and mask == 0:
		return -1
	return (~mask & 15) if painted_is_lower else mask


func terrain_at(cell: Vector2i) -> Terrain:
	if source.get_cell_source_id(cell) == -1:
		return Terrain.NONE
	return Terrain.LOWER if source.get_cell_atlas_coords(cell) == LOWER_MARKER else Terrain.UPPER


func _place(cell: Vector2i) -> void:
	var mask := mask_at(cell)
	if mask != -1:
		set_cell(cell, atlas_source_id, tiles_by_mask[mask])
