class_name PlatformUtils
## Consultas de plataforma baseadas em feature tags (funcionam em export e no editor).
## https://docs.godotengine.org/en/stable/tutorials/export/feature_tags.html


static func is_desktop() -> bool:
	return OS.has_feature("pc")


static func is_mobile() -> bool:
	return OS.has_feature("mobile")


static func is_web() -> bool:
	return OS.has_feature("web")


static func is_mobile_web() -> bool:
	return OS.has_feature("web_android") or OS.has_feature("web_ios")


## Dispositivo cuja entrada principal é toque (celular nativo ou navegador mobile).
static func is_touch_primary() -> bool:
	return is_mobile() or is_mobile_web()


## Apps iOS não devem ter botão "Sair" (diretrizes da Apple); na web não há para onde sair.
static func can_quit() -> bool:
	return is_desktop() or OS.has_feature("android")
