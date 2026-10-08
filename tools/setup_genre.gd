@tool
extends EditorScript
## Setup de gênero pelo editor:
##   1. Ajuste GENRE abaixo ("platformer" ou "topdown").
##   2. Com este script aberto no editor de scripts: File > Run (Ctrl+Shift+X).
## Rode uma única vez, logo após criar o projeto a partir do template.

const GENRE := "platformer"

const GenreSetup := preload("res://tools/genre_setup.gd")


func _run() -> void:
	if GenreSetup.apply(GENRE) == OK:
		EditorInterface.get_resource_filesystem().scan()
		print("Pronto! Reinicie o editor (Project > Reload Current Project) para limpar o cache.")
