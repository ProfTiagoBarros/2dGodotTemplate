extends SceneTree
## Importa animações quadro a quadro (ex.: as baixadas do PixelLab) para o Godot:
## junta os quadros de cada animação numa tira PNG e gera um SpriteFrames.
##
##   godot --headless --path . -s res://tools/import_frames.gd -- \
##       <pasta_quadros> <pasta_saida> <nome> [fps] [anims_sem_loop]
##
## <pasta_quadros> tem uma subpasta por animação, com 0.png, 1.png… (o formato
## em que o PixelLab entrega cada direção). O nome da subpasta vira o nome da
## animação (ex.: idle, run, walk_east). Quadros de tamanhos diferentes entre
## animações são permitidos: o AnimatedSprite2D centraliza cada quadro.
##
## Saída: <nome>_<animação>.png (tiras) e <nome>_frames.tres. Depois rode o
## import do Godot (abrir o editor ou `--import`) para ele importar as tiras.
## [anims_sem_loop]: lista separada por vírgula (padrão: as que começam com
## "attack", mais "jump" e "dash"). Sem dependência de autoloads (modo `-s`).

const DEFAULT_FPS := 10.0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		push_error("Uso: -- <pasta_quadros> <pasta_saida> <nome> [fps] [anims_sem_loop]")
		quit(1)
		return
	var frames_dir := args[0]
	var out_dir := args[1]
	var base_name := args[2]
	var fps := float(args[3]) if args.size() > 3 else DEFAULT_FPS
	var no_loop := PackedStringArray(args[4].split(",", false)) if args.size() > 4 else PackedStringArray()
	quit(0 if import_frames(frames_dir, out_dir, base_name, fps, no_loop) == OK else 1)


static func import_frames(frames_dir: String, out_dir: String, base_name: String,
		fps: float, no_loop: PackedStringArray) -> Error:
	if not DirAccess.dir_exists_absolute(frames_dir):
		push_error("Pasta de quadros não existe: %s" % frames_dir)
		return ERR_FILE_NOT_FOUND
	DirAccess.make_dir_recursive_absolute(out_dir)
	var animations := DirAccess.get_directories_at(frames_dir)
	animations.sort()
	var ext_resources := PackedStringArray()
	var sub_resources := PackedStringArray()
	var animation_entries := PackedStringArray()
	for anim: String in animations:
		var frames := _load_frames(frames_dir.path_join(anim))
		if frames.is_empty():
			continue
		var size := frames[0].get_size()
		var strip := Image.create_empty(size.x * frames.size(), size.y, false, Image.FORMAT_RGBA8)
		for i in frames.size():
			strip.blit_rect(frames[i], Rect2i(Vector2i.ZERO, size), Vector2i(size.x * i, 0))
		var strip_path := out_dir.path_join("%s_%s.png" % [base_name, anim])
		var err := strip.save_png(strip_path)
		if err != OK:
			push_error("Falha ao salvar %s" % strip_path)
			return err
		var tex_id := "tex_%s" % anim
		ext_resources.append('[ext_resource type="Texture2D" path="%s" id="%s"]' % [strip_path, tex_id])
		var frame_refs := PackedStringArray()
		for i in frames.size():
			var atlas_id := "atlas_%s_%d" % [anim, i]
			sub_resources.append('[sub_resource type="AtlasTexture" id="%s"]\natlas = ExtResource("%s")\nregion = Rect2(%d, 0, %d, %d)\n'
					% [atlas_id, tex_id, size.x * i, size.x, size.y])
			frame_refs.append('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % atlas_id)
		var loops := not (anim in no_loop or (no_loop.is_empty() and _is_one_shot(anim)))
		animation_entries.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}'
				% [", ".join(frame_refs), "true" if loops else "false", anim, fps])
		print("  %s: %d quadros %dx%d%s" % [anim, frames.size(), size.x, size.y, "" if loops else " (sem loop)"])
	if animation_entries.is_empty():
		push_error("Nenhuma animação encontrada em %s" % frames_dir)
		return ERR_FILE_NOT_FOUND
	var text := '[gd_resource type="SpriteFrames" format=3]\n\n'
	text += "\n".join(ext_resources) + "\n\n" + "\n".join(sub_resources) + "\n"
	text += "[resource]\nanimations = [%s]\n" % ", ".join(animation_entries)
	var tres_path := out_dir.path_join("%s_frames.tres" % base_name)
	var file := FileAccess.open(tres_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	print("SpriteFrames: %s (%d animações)" % [tres_path, animation_entries.size()])
	return OK


static func _is_one_shot(anim: String) -> bool:
	return anim.begins_with("attack") or anim.begins_with("jump") or anim.begins_with("dash")


static func _load_frames(dir: String) -> Array[Image]:
	var frames: Array[Image] = []
	var i := 0
	while FileAccess.file_exists(dir.path_join("%d.png" % i)):
		var img := Image.load_from_file(dir.path_join("%d.png" % i))
		img.convert(Image.FORMAT_RGBA8)
		frames.append(img)
		i += 1
	return frames
