extends RefCounted
## Assistente de configuração de um jogo novo a partir do template. Usado pela
## janela do editor (addons/project_wizard) e pela linha de comando
## (setup_project_cli.gd). Sem dependência de autoloads (roda em modo `-s`).
##
## Recebe as respostas num Dictionary (chaves OPT_*) e:
##   1. Dá nome ao jogo (project.godot, título do menu, arquivos do CI).
##   2. Escolhe o gênero (GenreSetup): apaga os módulos que não serão usados.
##   3. Mantém só as plataformas escolhidas (export_presets.cfg + CI).
##   4. Transforma as docs do template em docs do JOGO: README novo, CHANGELOG
##      zerado, CLAUDE.md enxuto (menos tokens por sessão) e, opcionalmente,
##      sem docs em inglês e sem arquivos de comunidade.
##   5. Corrige links que apontariam para arquivos removidos.
##   6. Opcionalmente remove as próprias ferramentas de setup.
##
## Tudo o que é apagado vai para a LIXEIRA do sistema. Mesmo assim, faça um
## commit antes: `git checkout -- . && git clean -fd` desfaz tudo.

const GenreSetup := preload("res://tools/genre_setup.gd")

const OPT_NAME := "name"
const OPT_GENRE := "genre"
const OPT_PLATFORMS := "platforms"
## true = o repositório vira um JOGO (docs do jogo, não do template).
const OPT_GAME_DOCS := "game_docs"
const OPT_ENGLISH_DOCS := "english_docs"
const OPT_COMMUNITY := "community_files"
const OPT_REMOVE_TOOLS := "remove_tools"

const PLATFORM_PC := "pc"
const PLATFORM_WEB := "web"
const PLATFORM_MOBILE := "mobile"
## Plataforma -> presets de export_presets.cfg.
const PLATFORM_PRESETS := {
	PLATFORM_PC: ["Windows Desktop", "Linux"],
	PLATFORM_WEB: ["Web"],
	PLATFORM_MOBILE: ["Android"],
}
## Preset -> nome da entrada na matrix do job de export do CI.
const CI_MATRIX_NAMES := {
	"Windows Desktop": "windows",
	"Linux": "linux",
	"Web": "web",
	"Android": "android",
}
const GENRE_LABELS := {
	"platformer": "side-scrolling / metroidvania",
	"topdown": "top-down",
	GenreSetup.BASE: "só a base, sem módulo de gênero",
}

## Nome do projeto enquanto ainda é o template (o assistente pede um nome novo).
const TEMPLATE_NAME := "Godot 2D Template"
const EXPORT_PRESETS_FILE := "res://export_presets.cfg"
const CI_FILE := "res://.github/workflows/ci.yml"
const TRANSLATIONS_FILE := "res://localization/translations.csv"
const WIZARD_PLUGIN := "res://addons/project_wizard/plugin.cfg"
const SETUP_DIRS: Array[String] = ["res://tools", "res://addons/project_wizard"]
const ENGLISH_DOCS: Array[String] = ["res://README.en.md", "res://MANUAL.en.md", "res://REVIEW_GUIDE.en.md"]
const COMMUNITY_FILES: Array[String] = [
	"res://CONTRIBUTING.md", "res://SECURITY.md", "res://.github/ISSUE_TEMPLATE",
	"res://.github/pull_request_template.md", "res://.github/CODEOWNERS",
]


static func default_options() -> Dictionary:
	var genres := GenreSetup.available_genres()
	return {
		OPT_NAME: "Meu Jogo",
		OPT_GENRE: genres[0],
		OPT_PLATFORMS: [PLATFORM_PC, PLATFORM_WEB, PLATFORM_MOBILE],
		OPT_GAME_DOCS: true,
		OPT_ENGLISH_DOCS: false,
		OPT_COMMUNITY: false,
		OPT_REMOVE_TOOLS: true,
	}


## Mensagem de erro, ou "" se as opções são válidas.
static func validate(options: Dictionary) -> String:
	if str(options.get(OPT_NAME, "")).strip_edges().is_empty():
		return "Dê um nome ao jogo."
	if str(options.get(OPT_GENRE, "")) not in GenreSetup.available_genres():
		return "Gênero indisponível. Opções: %s" % ", ".join(GenreSetup.available_genres())
	var platforms: Array = options.get(OPT_PLATFORMS, [])
	if platforms.is_empty():
		return "Escolha ao menos uma plataforma."
	for platform: Variant in platforms:
		if not PLATFORM_PRESETS.has(str(platform)):
			return "Plataforma desconhecida: %s" % platform
	return ""


## O que `apply` vai fazer, em texto (prévia da janela e `--dry-run`).
## `git` = resultado de git_state() já consultado (evita rodar git a cada tecla).
static func plan(options: Dictionary, git: String = "") -> PackedStringArray:
	var steps := PackedStringArray()
	var genre := str(options[OPT_GENRE])
	steps.append("Nome do jogo: \"%s\" (project.godot, título do menu e arquivos do CI)." % options[OPT_NAME])
	steps.append("Gênero: %s." % GENRE_LABELS.get(genre, genre))
	for other: String in GenreSetup.GENRES:
		if other != genre and DirAccess.dir_exists_absolute("res://game/" + other):
			steps.append("  Lixeira: game/%s/" % other)
	if genre == GenreSetup.BASE:
		steps.append("  Cria a fase vazia %s." % GenreSetup.BASE_LEVEL)
	var removed := _removed_presets(options[OPT_PLATFORMS])
	if removed.is_empty():
		steps.append("Plataformas: todas (Windows, Linux, Web, Android).")
	else:
		steps.append("Plataformas: remove %s (export e CI)." % ", ".join(removed))
	if options[OPT_GAME_DOCS]:
		steps.append("Docs do jogo: README.md novo, README do template vira TEMPLATE.md, CHANGELOG zerado.")
		steps.append("CLAUDE.md enxuto: sem as regras de manutenção do template.")
		if not options[OPT_ENGLISH_DOCS]:
			steps.append("  Lixeira: docs em inglês (*.en.md).")
		if not options[OPT_COMMUNITY]:
			steps.append("  Lixeira: CONTRIBUTING, SECURITY, modelos de issue/PR, CODEOWNERS.")
	if options[OPT_REMOVE_TOOLS]:
		steps.append("Lixeira: ferramentas de setup (tools/ e este assistente).")
	match git if not git.is_empty() else git_state():
		"dirty":
			steps.append("ATENÇÃO: há mudanças sem commit. Faça um commit antes para poder desfazer.")
		"none":
			steps.append("ATENÇÃO: o projeto não está no Git. Os arquivos removidos vão para a lixeira.")
	return steps


static func apply(options: Dictionary) -> Error:
	var problem := validate(options)
	if not problem.is_empty():
		push_error("ProjectSetup: " + problem)
		return ERR_INVALID_PARAMETER
	var name := str(options[OPT_NAME]).strip_edges()

	ProjectSettings.set_setting("application/config/name", name)
	_set_game_title(name)
	_replace_in_file(CI_FILE, 'GAME_SLUG: "[^"]*"', 'GAME_SLUG: "%s"' % slugify(name))

	# GenreSetup salva o project.godot (com o nome novo) e limpa o CLAUDE.md.
	var err := GenreSetup.apply(str(options[OPT_GENRE]))
	if err != OK:
		return err

	err = _keep_platforms(options[OPT_PLATFORMS])
	if err != OK:
		return err

	if options[OPT_GAME_DOCS]:
		_convert_docs(options)
	fix_broken_links()

	if options[OPT_REMOVE_TOOLS]:
		_remove_setup_tools()
	err = ProjectSettings.save()
	if err != OK:
		push_error("ProjectSetup: falha ao salvar project.godot (%s)" % error_string(err))
		return err
	print("ProjectSetup: \"%s\" configurado. Reabra o projeto (ou rode --import) para atualizar o cache." % name)
	return OK


## "Meu Jogo Incrível!" -> "meu-jogo-incrivel"
static func slugify(text: String) -> String:
	var ascii := text.to_lower().strip_edges()
	for pair: Array in [["áàâãä", "a"], ["éèêë", "e"], ["íìîï", "i"], ["óòôõö", "o"], ["úùûü", "u"], ["ç", "c"]]:
		for accented: String in str(pair[0]).split(""):
			ascii = ascii.replace(accented, pair[1])
	var slug := RegEx.create_from_string("[^a-z0-9]+").sub(ascii, "-", true).trim_prefix("-").trim_suffix("-")
	return slug if not slug.is_empty() else "jogo"


## "clean", "dirty" ou "none" (sem Git ou sem o comando git).
static func git_state() -> String:
	var output := []
	var code := OS.execute("git", ["-C", ProjectSettings.globalize_path("res://"), "status", "--porcelain"], output, true)
	if code != 0:
		return "none"
	return "clean" if str(output[0]).strip_edges().is_empty() else "dirty"


## Troca [texto](arquivo-inexistente) por "texto" em todos os .md do projeto.
static func fix_broken_links() -> void:
	var link := RegEx.create_from_string("(!?)\\[([^\\]]*)\\]\\(([^)\\s#]+)(#[^)]*)?\\)")
	for path: String in _markdown_files("res://"):
		var text := FileAccess.get_file_as_string(path)
		var result := ""
		var last := 0
		for found: RegExMatch in link.search_all(text):
			var target := found.get_string(3)
			if "://" in target or target.begins_with("mailto:"):
				continue
			var resolved := path.get_base_dir().path_join(target).simplify_path()
			if FileAccess.file_exists(resolved) or DirAccess.dir_exists_absolute(resolved):
				continue
			result += text.substr(last, found.get_start() - last)
			if found.get_string(1).is_empty():
				result += found.get_string(2)
			last = found.get_end()
		if last > 0:
			GenreSetup.write_text(path, result + text.substr(last))


#region Passos

static func _set_game_title(name: String) -> void:
	var quoted := "\"%s\"" % name.replace("\"", "\"\"")
	_replace_in_file(TRANSLATIONS_FILE, "(?m)^GAME_TITLE,.*$", "GAME_TITLE,%s,%s" % [quoted, quoted])


static func _removed_presets(platforms: Array) -> PackedStringArray:
	var removed := PackedStringArray()
	for platform: String in PLATFORM_PRESETS:
		if platform not in platforms:
			for preset: String in PLATFORM_PRESETS[platform]:
				removed.append(preset)
	return removed


## Reescreve export_presets.cfg só com os presets mantidos (renumerados: o
## Godot para de ler no primeiro número que faltar) e tira o resto do CI.
static func _keep_platforms(platforms: Array) -> Error:
	var removed := _removed_presets(platforms)
	if removed.is_empty():
		return OK
	# Arquivo do próprio repositório (confiável), não de user://.
	var source := ConfigFile.new()
	var err := source.load(EXPORT_PRESETS_FILE)
	if err != OK:
		push_error("ProjectSetup: não consegui ler %s (%s)" % [EXPORT_PRESETS_FILE, error_string(err)])
		return err
	var target := ConfigFile.new()
	var index := 0
	var next := 0
	while source.has_section("preset.%d" % index):
		var section := "preset.%d" % index
		if str(source.get_value(section, "name", "")) not in removed:
			for suffix: String in ["", ".options"]:
				if source.has_section(section + suffix):
					for key: String in source.get_section_keys(section + suffix):
						target.set_value("preset.%d%s" % [next, suffix], key, source.get_value(section + suffix, key))
			next += 1
		index += 1
	err = target.save(EXPORT_PRESETS_FILE)
	if err != OK:
		return err
	for preset: String in removed:
		var entry := str(CI_MATRIX_NAMES.get(preset, ""))
		_replace_in_file(CI_FILE, "(?m)^ *- name: %s\\n *preset: .*\\n *file: .*\\n" % entry, "")
	return OK


static func _convert_docs(options: Dictionary) -> void:
	var name := str(options[OPT_NAME]).strip_edges()
	var genre := str(options[OPT_GENRE])
	var english: bool = options[OPT_ENGLISH_DOCS]

	if not english:
		for path: String in ENGLISH_DOCS:
			_trash(path)
	if not options[OPT_COMMUNITY]:
		for path: String in COMMUNITY_FILES:
			_trash(path)
	# O README do template continua como referência da arquitetura.
	_rename("res://README.md", "res://TEMPLATE.md")
	_rename("res://README.en.md", "res://TEMPLATE.en.md")
	for path: String in _markdown_files("res://"):
		var text := FileAccess.get_file_as_string(path)
		var updated := text.replace("README.en.md", "TEMPLATE.en.md").replace("README.md", "TEMPLATE.md")
		if not english:
			updated = RegEx.create_from_string("(?m)^\\*\\*Português\\*\\* · \\[English\\]\\([^)]*\\)\\n\\n?").sub(updated, "", true)
		if updated != text:
			GenreSetup.write_text(path, updated)

	GenreSetup.write_text("res://README.md", _game_readme(name, genre, options[OPT_PLATFORMS]))
	GenreSetup.write_text("res://CHANGELOG.md", _game_changelog(genre))
	_slim_claude_md(name, genre, options[OPT_PLATFORMS])


## Tira as regras de manutenção do template e troca a apresentação do projeto.
static func _slim_claude_md(name: String, genre: String, platforms: Array) -> void:
	var path := GenreSetup.CLAUDE_FILE
	if not FileAccess.file_exists(path):
		return
	var text := FileAccess.get_file_as_string(path)
	var intro := ("%s: 2D game built in Godot **4.7** (GDScript only) from the 2D template (%s), "
			+ "targeting %s. Comments, docs and UI translation values are in **Brazilian Portuguese**; "
			+ "identifiers are English. `TEMPLATE.md` documents the architecture inherited from the template, "
			+ "`MANUAL.md` has step-by-step recipes and `IMPROVEMENTS.md` lists template features not implemented yet. "
			+ "Record user-visible changes in `CHANGELOG.md`.\n") % [name, GENRE_LABELS.get(genre, genre), ", ".join(PackedStringArray(platforms))]
	text = RegEx.create_from_string("(?s)<!-- project-intro -->.*?<!-- /project-intro -->\\n?").sub(text, intro)
	text = RegEx.create_from_string("(?s)\\n?<!-- template-only -->.*?<!-- /template-only -->").sub(text, "", true)
	GenreSetup.write_text(path, text)


static func _game_readme(name: String, genre: String, platforms: Array) -> String:
	return """# %s

Jogo 2D feito em **Godot 4.7** a partir do Godot 2D Template (%s).

## Como rodar

- Abra o projeto no Godot 4.7 e aperte **F5**.
- Testes automáticos: `godot --headless --path . res://tests/smoke_test.tscn`
- Plataformas: %s.

## Documentação

- [TEMPLATE.md](TEMPLATE.md): arquitetura e sistemas herdados do template.
- [MANUAL.md](MANUAL.md): receitas passo a passo (fases, inimigos, habilidades, builds).
- [REVIEW_GUIDE.md](REVIEW_GUIDE.md): boas práticas e checklist de revisão de código.
- [CLAUDE.md](CLAUDE.md): contexto do projeto para o Claude Code.
- [CHANGELOG.md](CHANGELOG.md): histórico de mudanças.

## Créditos

Baseado no Godot 2D Template, desenvolvido com assistência de IA (Claude, da Anthropic). Veja [TEMPLATE.md](TEMPLATE.md#créditos-e-uso-de-ia).
""" % [name, GENRE_LABELS.get(genre, genre), ", ".join(PackedStringArray(platforms))]


static func _game_changelog(genre: String) -> String:
	return """# Changelog

Mudanças relevantes do jogo ([Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/), [SemVer](https://semver.org/lang/pt-BR/)).

## [Não lançado]

### Adicionado

- Projeto criado a partir do Godot 2D Template (%s).
""" % GENRE_LABELS.get(genre, genre)


static func _remove_setup_tools() -> void:
	var plugins: PackedStringArray = ProjectSettings.get_setting("editor_plugins/enabled", PackedStringArray())
	var index := plugins.find(WIZARD_PLUGIN)
	if index != -1:
		plugins.remove_at(index)
		ProjectSettings.set_setting("editor_plugins/enabled", plugins if not plugins.is_empty() else null)
	for dir: String in SETUP_DIRS:
		_trash(dir)

#endregion


#region Arquivos

static func _replace_in_file(path: String, pattern: String, replacement: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var text := FileAccess.get_file_as_string(path)
	var updated := RegEx.create_from_string(pattern).sub(text, replacement, true)
	if updated != text:
		GenreSetup.write_text(path, updated)


static func _trash(path: String) -> void:
	if not FileAccess.file_exists(path) and not DirAccess.dir_exists_absolute(path):
		return
	var err := OS.move_to_trash(ProjectSettings.globalize_path(path))
	if err == OK:
		print("ProjectSetup: lixeira <- %s" % path)
	else:
		push_warning("ProjectSetup: não foi possível remover %s (%s)." % [path, error_string(err)])


static func _rename(from: String, to: String) -> void:
	if FileAccess.file_exists(from) and not FileAccess.file_exists(to):
		DirAccess.rename_absolute(from, to)


## .md da raiz e de .github/ (o resto do projeto não tem docs).
static func _markdown_files(root: String) -> PackedStringArray:
	var files := PackedStringArray()
	for dir: String in [root, root.path_join(".github")]:
		if not DirAccess.dir_exists_absolute(dir):
			continue
		for file: String in DirAccess.get_files_at(dir):
			if file.ends_with(".md"):
				files.append(dir.path_join(file))
	return files

#endregion
