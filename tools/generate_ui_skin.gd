extends SceneTree
## Gera as peças PADRÃO da skin de interface (pixel art, tema "Template
## Chronicles": cyberpunk com toque de fantasia) em assets/ui/.
##
##   godot --headless --path . -s res://tools/generate_ui_skin.gd
##
## Você NÃO precisa rodar isto para trocar o visual: basta substituir os PNGs
## de assets/ui/ por outros com o mesmo nome (veja assets/ui/README.md). Este
## script só recria os originais. Fundo e emblema vêm do Canva e não são gerados
## aqui. Sem dependência de autoloads (roda em modo `-s`).

const OUT_DIR := "res://assets/ui"

const NAVY := Color("0a0f24")
const NAVY_LIGHT := Color("13204a")
const CYAN := Color("2ef2ff")
const CYAN_DIM := Color("1a7a99")
const MAGENTA := Color("ff2fa8")
const MAGENTA_DIM := Color("7a1a5e")
const PURPLE := Color("8a3cff")
const GREY := Color("3a4466")
const CLEAR := Color(0, 0, 0, 0)


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_save("panel", _panel())
	_save("button", _button(NAVY.lerp(NAVY_LIGHT, 0.4), CYAN_DIM, CYAN_DIM.darkened(0.3)))
	_save("button_hover", _button(NAVY_LIGHT, CYAN, CYAN_DIM))
	_save("button_pressed", _button(MAGENTA_DIM.darkened(0.4), MAGENTA, MAGENTA_DIM))
	_save("button_focus", _focus_frame())
	_save("bar_frame", _bar_frame())
	_save("bar_fill", _bar_fill(MAGENTA, PURPLE))
	_save("slider_track", _bar_frame())
	_save("slider_fill", _bar_fill(CYAN, CYAN_DIM))
	_save("slider_grabber", _grabber())
	_save("toggle_on", _toggle(true))
	_save("toggle_off", _toggle(false))
	print("UI skin gerada em %s" % OUT_DIR)
	quit()


#region Peças

## 32x32, cantos chanfrados de 5 px. Margens de 9-slice: 8.
func _panel() -> Image:
	var img := _new(32, 32)
	_cut_shape(img, 5, Color(NAVY, 0.92))
	_cut_outline(img, 5, CYAN, 0)
	_cut_outline(img, 5, Color(CYAN_DIM, 0.6), 2)
	# Detalhes de "circuito" magenta nos cantos opostos.
	for i in 3:
		img.set_pixel(3 + i, 1, MAGENTA)
		img.set_pixel(28 - i, 30, MAGENTA)
	img.set_pixel(1, 3, MAGENTA)
	img.set_pixel(30, 28, MAGENTA)
	return img


## 32x16, cantos chanfrados de 3 px, brilho na borda de cima. Margens: 6.
func _button(fill: Color, border: Color, inner: Color) -> Image:
	var img := _new(32, 16)
	_cut_shape(img, 3, fill)
	_cut_outline(img, 3, border, 0)
	for x in range(5, 27):
		img.set_pixel(x, 2, Color(inner, 0.8))
	return img


## Moldura sem preenchimento (desenhada POR CIMA do texto quando há foco).
func _focus_frame() -> Image:
	var img := _new(32, 16)
	_cut_outline(img, 3, MAGENTA, 0)
	_cut_outline(img, 3, Color(MAGENTA, 0.35), 1)
	return img


## 16x8, fundo escuro com borda ciano. Margens: 3.
func _bar_frame() -> Image:
	var img := _new(16, 8)
	_cut_shape(img, 1, Color(NAVY, 0.95))
	_cut_outline(img, 1, CYAN_DIM, 0)
	return img


## 8x8 com 2 px transparentes em volta: a ProgressBar desenha o preenchimento
## no mesmo retângulo do fundo, então o recuo fica na própria imagem. Margens: 3.
func _bar_fill(top: Color, bottom: Color) -> Image:
	var img := _new(8, 8)
	for y in range(2, 6):
		var color := top.lerp(bottom, float(y - 2) / 3.0)
		for x in range(2, 6):
			img.set_pixel(x, y, color)
	return img


## 8x12, losango ciano com núcleo magenta.
func _grabber() -> Image:
	var img := _new(8, 12)
	for y in 12:
		var half := 4 - absi(y - 6) * 4 / 6
		for x in range(4 - half, 4 + half):
			var edge := x == 4 - half or x == 3 + half or y == 0 or y == 11
			img.set_pixel(x, y, CYAN if edge else NAVY_LIGHT)
	for y in range(4, 8):
		img.set_pixel(3, y, MAGENTA)
		img.set_pixel(4, y, MAGENTA)
	return img


## 24x12, chave liga/desliga.
func _toggle(on: bool) -> Image:
	var img := _new(24, 12)
	_cut_shape(img, 3, Color(CYAN_DIM, 0.55) if on else Color(NAVY, 0.95))
	_cut_outline(img, 3, CYAN if on else GREY, 0)
	var knob_x := 13 if on else 3
	for y in range(3, 9):
		for x in range(knob_x, knob_x + 8):
			img.set_pixel(x, y, CYAN if on else GREY)
	if on:
		for y in range(5, 7):
			for x in range(knob_x + 3, knob_x + 5):
				img.set_pixel(x, y, MAGENTA)
	return img

#endregion


#region Desenho

func _new(width: int, height: int) -> Image:
	var img := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)
	return img


## O pixel (x, y) está dentro do retângulo com cantos chanfrados em `cut` px?
func _inside(img: Image, x: int, y: int, cut: int, inset: int) -> bool:
	var w := img.get_width() - 1 - inset
	var h := img.get_height() - 1 - inset
	if x < inset or y < inset or x > w or y > h:
		return false
	var dx := mini(x - inset, w - x)
	var dy := mini(y - inset, h - y)
	return dx + dy >= cut


func _cut_shape(img: Image, cut: int, color: Color) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if _inside(img, x, y, cut, 0):
				img.set_pixel(x, y, color)


## Contorno de 1 px da forma chanfrada, recuado `inset` px.
func _cut_outline(img: Image, cut: int, color: Color, inset: int) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if not _inside(img, x, y, cut, inset):
				continue
			var edge := false
			for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if not _inside(img, x + offset.x, y + offset.y, cut, inset):
					edge = true
			if edge:
				img.set_pixel(x, y, color)


func _save(file_name: String, img: Image) -> void:
	var path := "%s/%s.png" % [OUT_DIR, file_name]
	var err := img.save_png(path)
	if err != OK:
		push_error("Falha ao salvar %s (%s)" % [path, error_string(err)])

#endregion
