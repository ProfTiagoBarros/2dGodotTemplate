class_name ScenePaths
## Caminhos de cenas centralizados (evita strings mágicas espalhadas).

const MAIN_MENU := "res://ui/main_menu/main_menu.tscn"
const GAME := "res://game/game.tscn"

## Primeira fase carregada por game.tscn. O script tools/genre_setup.gd reescreve
## esta linha ao escolher o gênero; troque à mão para testar o outro gênero.
const FIRST_LEVEL := "res://game/platformer/levels/platformer_level_01.tscn"
