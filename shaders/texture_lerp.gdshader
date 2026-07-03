shader_type canvas_item;

uniform sampler2D texture_b : source_color;
uniform float blend : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 a = texture(TEXTURE, UV);        // current (base) texture
    vec4 b = texture(texture_b, UV);      // target texture
    COLOR = mix(a, b, blend);
}