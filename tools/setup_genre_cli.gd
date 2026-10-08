extends SceneTree
## Setup de gênero pela linha de comando:
##   godot --headless --path . -s res://tools/setup_genre_cli.gd -- topdown

const GenreSetup := preload("res://tools/genre_setup.gd")


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var genre := args[0] if not args.is_empty() else ""
	quit(0 if GenreSetup.apply(genre) == OK else 1)
