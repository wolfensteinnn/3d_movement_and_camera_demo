shader_type spatial;
render_mode world_vertex_coords;

// =====================================================================
//  DAY/NIGHT BLEND  (0 = tropical day, 1 = atlantic night)
// =====================================================================
uniform float time_of_day : hint_range(0.0, 1.0) = 0.0;

// =====================================================================
//  TROPICAL PALETTE
// =====================================================================
uniform vec4 color_sand_shallow_day  : source_color = vec4(0.85, 0.78, 0.52, 1.0);
uniform vec4 color_sand_deep_day     : source_color = vec4(0.18, 0.28, 0.32, 1.0);
uniform vec4 color_rock_day          : source_color = vec4(0.38, 0.32, 0.22, 1.0);
uniform vec4 color_sediment_day      : source_color = vec4(0.12, 0.18, 0.20, 1.0);

// =====================================================================
//  ATLANTIC NIGHT PALETTE
// =====================================================================
uniform vec4 color_sand_shallow_night : source_color = vec4(0.22, 0.20, 0.16, 1.0);
uniform vec4 color_sand_deep_night    : source_color = vec4(0.04, 0.05, 0.06, 1.0);
uniform vec4 color_rock_night         : source_color = vec4(0.10, 0.10, 0.09, 1.0);
uniform vec4 color_sediment_night     : source_color = vec4(0.03, 0.04, 0.05, 1.0);

// =====================================================================
//  SHARED PARAMS
// =====================================================================
uniform float shallow_depth  : hint_range(0.0, 50.0)  = 5.0;
uniform float deep_depth     : hint_range(0.0, 200.0) = 40.0;
uniform float detail_scale   : hint_range(0.01, 2.0)  = 0.18;
uniform float ripple_scale   : hint_range(0.01, 2.0)  = 0.8;
uniform float rock_threshold : hint_range(0.0, 1.0)   = 0.72;
uniform float roughness      : hint_range(0.0, 1.0)   = 0.95;

varying vec3 v_world_pos;

float hash(vec2 p) {
    uvec2 q = uvec2(ivec2(p));
    q.x ^= q.y * 2747636419u;
    q.x *= 2654435761u;
    q.x ^= q.x >> 16u;
    return float(q.x) * (1.0 / 4294967296.0);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i + vec2(0,0)), hash(i + vec2(1,0)), u.x),
        mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), u.x),
        u.y
    );
}

float fbm(vec2 p, int octaves) {
    float val  = 0.0;
    float amp  = 0.5;
    float freq = 1.0;
    for (int i = 0; i < octaves; i++) {
        val  += vnoise(p * freq) * amp;
        amp  *= 0.5;
        freq *= 2.1;
    }
    return val;
}

void vertex() {
    v_world_pos = VERTEX;
}

void fragment() {
    vec2 xz = v_world_pos.xz;

    // depth factor
    float depth   = -v_world_pos.y;
    float depth_t = clamp((depth - shallow_depth) / (deep_depth - shallow_depth), 0.0, 1.0);
    depth_t = depth_t * depth_t * (3.0 - 2.0 * depth_t);

    // noise layers
    float base     = fbm(xz * detail_scale * 0.3, 4);
    float mid      = fbm(xz * detail_scale, 5);
    float fine     = vnoise(xz * detail_scale * 4.0);
    float fine_amt = 1.0 - depth_t;
    float ripple   = pow(vnoise(xz * ripple_scale + vec2(0.3, 0.7)), 2.0) * (1.0 - depth_t * 0.85);
    float sand_val = base * 0.5 + mid * 0.35 + fine * fine_amt * 0.15;
    float rock_val = fbm(xz * detail_scale * 0.6 + vec2(3.1, 7.4), 3);
    float rock_mask = smoothstep(rock_threshold, rock_threshold + 0.12, rock_val);

    // --- tropical ---
    vec3 sand_day = mix(color_sand_shallow_day.rgb, color_sand_deep_day.rgb, depth_t);
    sand_day      = mix(sand_day, sand_day * (0.8 + sand_val * 0.4), 0.8);
    sand_day     += vec3(0.10, 0.08, 0.04) * ripple * fine_amt;
    vec3 rock_day = mix(color_rock_day.rgb, color_rock_day.rgb * 0.6, base);
    sand_day      = mix(sand_day, rock_day, rock_mask);
    sand_day      = mix(sand_day, color_sediment_day.rgb, depth_t * (0.6 + base * 0.4) * 0.7);

    // --- atlantic night ---
    vec3 sand_night = mix(color_sand_shallow_night.rgb, color_sand_deep_night.rgb, depth_t);
    sand_night      = mix(sand_night, sand_night * (0.8 + sand_val * 0.4), 0.8);
    sand_night     += vec3(0.02, 0.02, 0.03) * ripple * fine_amt;
    vec3 rock_night = mix(color_rock_night.rgb, color_rock_night.rgb * 0.5, base);
    sand_night      = mix(sand_night, rock_night, rock_mask);
    sand_night      = mix(sand_night, color_sediment_night.rgb, depth_t * (0.6 + base * 0.4) * 0.7);

    // blend palettes
    vec3 sand_col = mix(sand_day, sand_night, time_of_day);

    // wet darkening
    float wet        = depth_t;
	// exponential depth fade — goes to void black
	float void_t = 1.0 - exp(-depth * 0.08);
	sand_col *= mix(1.0, 0.02, void_t);

	// also kill specular completely in the void
	float surf_rough = mix(roughness, 1.0, void_t);
	float spec = mix(mix(0.1, 0.35, wet), 0.0, void_t);;
    sand_col        *= mix(1.0, 0.55, wet * 0.6);

    // normals
    float eps = 0.5;
    float h0  = fbm(xz * detail_scale, 4);
    float hx  = fbm((xz + vec2(eps, 0.0)) * detail_scale, 4);
    float hz  = fbm((xz + vec2(0.0, eps)) * detail_scale, 4);
    vec3 bump = normalize(vec3(h0 - hx, eps * 2.0, h0 - hz));
    vec3 normal_view = normalize((VIEW_MATRIX * vec4(bump, 0.0)).xyz);

    ALBEDO    = sand_col;
	ROUGHNESS = surf_rough;
	METALLIC  = 0.0;
	SPECULAR  = spec;
	NORMAL    = normal_view;
}