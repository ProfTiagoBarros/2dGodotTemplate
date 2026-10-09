// Pisca o sprite numa cor sólida (padrão: branco) preservando o alpha.
// Controlado por HitFlashComponent via `flash_amount` (0 = normal, 1 = cor cheia).
shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(mix(base.rgb, flash_color.rgb, flash_amount), base.a);
}
