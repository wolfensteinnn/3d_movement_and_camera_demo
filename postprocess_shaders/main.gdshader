shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

#include "dither.gdshaderinc"

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 pixel_coord = FRAGCOORD.xy;

	vec3 color = texture(screen_texture, uv).rgb;

	if (u_dither_mode != 0) {
		color = apply_dithering_by_mode(color, pixel_coord, u_dither_blue_noise_texture);
	}

	COLOR = vec4(color, 1.0);
}