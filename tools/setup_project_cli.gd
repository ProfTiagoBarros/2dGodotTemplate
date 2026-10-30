extends SceneTree
## Assistente de projeto pela linha de comando (automação/CI). No editor, use a
## janela: Project > Tools > "Configurar novo jogo…".
##
##   godot --headless --path . -s res://tools/setup_project_cli.gd -- \
##       --name="Meu Jogo" --genre=topdown --platforms=pc,mobile --dry-run
##
## Opções (todas opcionais; o padrão é o mesmo da janela):
##   --name=<texto>            nome do jogo
##   --genre=<gênero>          platformer | topdown | base
##   --platforms=<lista>       pc,web,mobile
##   --keep-template-docs      não transforma as docs em docs do jogo
##   --english-docs            mantém as docs em inglês
##   --community-files         mantém CONTRIBUTING, SECURITY, modelos de issue/PR
##   --keep-tools              não remove as ferramentas de setup
##   --dry-run                 só mostra o que seria feito

const ProjectSetup := preload("res://tools/project_setup.gd")


func _initialize() -> void:
	var options := ProjectSetup.default_options()
	var dry_run := false
	for arg: String in OS.get_cmdline_user_args():
		var key := arg.get_slice("=", 0)
		var value := arg.substr(key.length() + 1)
		match key:
			"--name":
				options[ProjectSetup.OPT_NAME] = value
			"--genre":
				options[ProjectSetup.OPT_GENRE] = value
			"--platforms":
				options[ProjectSetup.OPT_PLATFORMS] = Array(value.split(",", false))
			"--keep-template-docs":
				options[ProjectSetup.OPT_GAME_DOCS] = false
			"--english-docs":
				options[ProjectSetup.OPT_ENGLISH_DOCS] = true
			"--community-files":
				options[ProjectSetup.OPT_COMMUNITY] = true
			"--keep-tools":
				options[ProjectSetup.OPT_REMOVE_TOOLS] = false
			"--dry-run":
				dry_run = true
			_:
				push_error("Opção desconhecida: %s" % arg)
				quit(1)
				return

	var problem := ProjectSetup.validate(options)
	if not problem.is_empty():
		push_error(problem)
		quit(1)
		return
	for step: String in ProjectSetup.plan(options):
		print(step)
	if dry_run:
		quit(0)
		return
	quit(0 if ProjectSetup.apply(options) == OK else 1)
