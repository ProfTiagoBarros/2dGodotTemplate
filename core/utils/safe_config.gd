class_name SafeConfig
## Carrega ConfigFile de fontes NÃO confiáveis (user://, arquivos trocados
## entre jogadores, mods).
##
## ATENÇÃO: ConfigFile.load() / parse() constroem objetos e carregam scripts a
## partir do texto (`Object(RefCounted,"script":Resource("...gd"))`), ou seja,
## um arquivo adulterado pode EXECUTAR CÓDIGO no jogo. O mesmo vale para
## str_to_var() e bytes_to_var() com objetos. Aqui o texto é inspecionado ANTES
## do parse e qualquer construtor de objeto/recurso é recusado.
##
## Para dados de jogo (saves), prefira JSON: ele só produz tipos primitivos.

const _FORBIDDEN_PATTERN := "\\b(Object|Resource|ExtResource|SubResource)\\s*\\("

static var _forbidden: RegEx


## Retorna null se o arquivo não existir, for inválido ou contiver objetos.
static func load_file(path: String) -> ConfigFile:
	if not FileAccess.file_exists(path):
		return null
	return parse(FileAccess.get_file_as_string(path))


static func parse(text: String) -> ConfigFile:
	if _forbidden == null:
		_forbidden = RegEx.create_from_string(_FORBIDDEN_PATTERN)
	if _forbidden.search(text) != null:
		push_warning("SafeConfig: arquivo recusado (contém construtor de objeto/recurso).")
		return null
	var config := ConfigFile.new()
	if config.parse(text) != OK:
		return null
	return config
