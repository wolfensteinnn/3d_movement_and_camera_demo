shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
// CHROMATIC ABERRATION
uniform float aberration : hint_range(0.0, 1.0) = 0.0;
// VIGNETTE
uniform float vignette_radius :    hint_range(0.0, 1.0) = 0.22;
uniform float vignette_softness :  hint_range(0.0, 1.0) = 0.38;
uniform float vignette_intensity : hint_range(0.0, 3.0) = 0.0;
uniform float vignette_contrast :  hint_range(0.5, 4.0) = 2.20;
uniform vec4  vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
// SHAKE
uniform float shake_strength :   hint_range(0.0, 1.0) = 0.0;
uniform vec2  shake_factor_a =   vec2(100.0, 100.0);
uniform vec2  shake_factor_b =   vec2(1.0, 1.0);
uniform vec2  shake_magnitude =  vec2(0.004, 0.004);
// FAST SHAKE
uniform float fast_shake_intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// SHAKE
	vec2 uv = SCREEN_UV;
	uv -= 0.5;
	uv *= 1.0 - 2.0 * shake_magnitude.x;
	uv += 0.5;
	vec2 dt;
	dt.x = sin(TIME * shake_factor_a.x + shake_factor_b.x) * shake_magnitude.x;
	dt.y = cos(TIME * shake_factor_a.y + shake_factor_b.y) * shake_magnitude.y;
	vec2 shaken_uv = uv + (dt * shake_strength);
	
	// FAST SHAKE
	vec2 fast_dt;
	fast_dt.x = sin(TIME * 100.0) * 0.024;
	fast_dt.y = cos(TIME * 100.0) * 0.008;
	shaken_uv += (fast_dt * fast_shake_intensity);
	
	// CHROMATIC ABERRATION
	float scaled = pow(aberration, 2.5) * 0.012;
	vec4 text;
	text.r = texture(SCREEN_TEXTURE, shaken_uv + vec2(scaled, 0.0)).r;
	text.g = texture(SCREEN_TEXTURE, shaken_uv - vec2(scaled, 0.0)).g;
	text.b = texture(SCREEN_TEXTURE, shaken_uv).b;
	text.a = 1.0;
	// VIGNETTE
	vec2 centered = UV - vec2(0.5);
	float edge_box    = max(abs(centered.x) * 2.0, abs(centered.y) * 2.0);
	float edge_radial = length(centered) * 2.0;
	float shape = mix(edge_box, edge_radial, 0.25);
	float v = pow(smoothstep(vignette_radius, vignette_radius + vignette_softness, shape), vignette_contrast);
	float vig_alpha = clamp(v * vignette_intensity, 0.0, 1.0);
	text.rgb = mix(text.rgb, vignette_color.rgb, vig_alpha);
	COLOR = text;
}