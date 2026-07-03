shader_type spatial;
render_mode world_vertex_coords, depth_draw_always, cull_back;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float reflectance : hint_range(0.0, 1.0) = 0.2;

// =====================================================================
//  WAVE TRAINS
// =====================================================================

uniform vec4 wave_a = vec4( 1.00,  0.00,  0.32, 90.0);
uniform vec4 wave_b = vec4( 0.30,  1.00,  0.27, 72.0);
uniform vec4 wave_c = vec4(-0.70,  0.80,  0.25, 48.0);
uniform vec4 wave_d = vec4( 0.90, -0.60,  0.23, 26.0);
uniform vec4 wave_e = vec4( 0.20,  0.70,  0.16,  8.0);
uniform vec4 wave_f = vec4(-0.40, -0.90,  0.13,  4.0);
uniform vec4 wave_g = vec4( 0.60,  0.50,  0.10,  2.0);
uniform vec4 wave_h = vec4(-0.50,  0.60,  0.07,  8.1);

uniform float phase_a : hint_range(0.0, 6.28) = 0.00;
uniform float phase_b : hint_range(0.0, 6.28) = 1.13;
uniform float phase_c : hint_range(0.0, 6.28) = 2.71;
uniform float phase_d : hint_range(0.0, 6.28) = 4.05;
uniform float phase_e : hint_range(0.0, 6.28) = 5.32;
uniform float phase_f : hint_range(0.0, 6.28) = 0.87;
uniform float phase_g : hint_range(0.0, 6.28) = 3.14;
uniform float phase_h : hint_range(0.0, 6.28) = 1.57;

uniform float warp_strength : hint_range(0.0, 12.0) = 6.0;
uniform float warp_scale    : hint_range(0.001, 0.05) = 0.018;
uniform float warp_time_speed_a : hint_range(-0.2, 0.2) = 0.04;
uniform float warp_time_speed_b : hint_range(-0.2, 0.2) = -0.03;
uniform float warp_freq_mult_b  : hint_range(0.1, 5.0) = 2.1;
uniform vec2  warp_offset_b = vec2(5.2, 1.3);

// =====================================================================
//  VISUAL PARAMETERS
// =====================================================================

uniform vec4  color_shallow  : source_color = vec4(0.04, 0.18, 0.28, 1.0);
uniform vec4  color_deep     : source_color = vec4(0.01, 0.06, 0.14, 1.0);
uniform vec4  color_foam     : source_color = vec4(0.95, 0.97, 1.00, 1.0);
uniform vec4  color_sss      : source_color = vec4(0.10, 0.60, 0.50, 1.0);
uniform vec4  color_trough   : source_color = vec4(0.004, 0.012, 0.025, 1.0);
uniform float depth_distance : hint_range(0.1, 600.0) = 8.0;
uniform float roughness      : hint_range(0.0, 1.0)   = 0.08;
uniform float normal_strength: hint_range(0.0, 1.0)   = 1.0;
uniform float sss_strength   : hint_range(0.0, 4.0)   = 2.0;

uniform float ripple_scale_a  : hint_range(0.01, 4.0) = 0.06;
uniform float ripple_scale_b  : hint_range(0.01, 4.0) = 0.09;
uniform float ripple_strength : hint_range(0.0,  2.0) = 0.55;

// --- depth / trough shading ---
uniform float depth_height_offset : hint_range(0.0, 20.0) = 4.0;
uniform float depth_height_range  : hint_range(0.1, 40.0) = 8.0;
uniform float trough_height_offset : hint_range(0.0, 10.0) = 1.0;
uniform float trough_height_range  : hint_range(0.1, 20.0) = 3.0;
uniform float trough_darken_strength : hint_range(0.0, 1.0) = 0.88;

// --- water color patch variation ---
uniform float patch_scale_a : hint_range(0.001, 1.0) = 0.04;
uniform float patch_speed_a : hint_range(-0.1, 0.1) = 0.005;
uniform float patch_scale_b : hint_range(0.001, 1.0) = 0.09;
uniform float patch_speed_b : hint_range(-0.1, 0.1) = -0.003;
uniform vec2  patch_offset_b = vec2(3.7, 1.2);
uniform float patch_weight_a : hint_range(0.0, 1.0) = 0.6;
uniform float patch_weight_b : hint_range(0.0, 1.0) = 0.4;
uniform float deep_color_var_mix : hint_range(0.0, 1.0) = 0.5;
uniform float color_var_strength : hint_range(0.0, 1.0) = 0.25;

// --- ripple flow ---
uniform float flow_speed : hint_range(0.0, 1.0) = 0.06;
uniform float ripple_eps : hint_range(0.001, 0.2) = 0.02;

uniform float ripple_scale_d_mult : hint_range(0.1, 10.0) = 4.73;
uniform float ripple_speed_d_mult : hint_range(0.0, 5.0) = 0.5;
uniform vec2  ripple_offset_d = vec2(8.1, 2.4);

uniform float ripple_speed_a_mult : hint_range(0.0, 5.0) = 1.0;

uniform float ripple_speed_b_mult : hint_range(0.0, 5.0) = 0.7;

uniform float ripple_scale_c_mult : hint_range(0.1, 10.0) = 2.37;
uniform float ripple_speed_c_mult : hint_range(0.0, 5.0) = 1.3;
uniform vec2  ripple_offset_c = vec2(1.7, 3.1);

uniform float detail_n_weight_c : hint_range(0.0, 2.0) = 0.4;
uniform float detail_n_weight_d : hint_range(0.0, 2.0) = 0.2;
uniform float detail_n_normalize_div : hint_range(0.1, 5.0) = 2.4;
uniform float toksvig_base_roughness : hint_range(0.0, 1.0) = 0.0;

// --- normal / fresnel / roughness shaping ---
uniform float normal_distance_falloff : hint_range(0.0001, 0.02) = 0.003;
uniform float geo_roughness_scale : hint_range(0.0, 10.0) = 4.0;
uniform float fresnel_power : hint_range(1.0, 10.0) = 5.0;
uniform float slope_roughness_mult : hint_range(1.0, 10.0) = 3.5;
uniform float foam_roughness_target : hint_range(0.0, 1.0) = 0.8;

// --- foam ---
uniform float foam_crest_edge : hint_range(0.0, 1.0) = 0.72;
uniform float foam_streak_scale_a : hint_range(0.01, 5.0) = 0.5;
uniform float foam_streak_speed_a : hint_range(-0.2, 0.2) = 0.04;
uniform float foam_streak_scale_b : hint_range(0.01, 5.0) = 1.2;
uniform float foam_streak_speed_b : hint_range(-0.2, 0.2) = -0.025;
uniform vec2  foam_streak_offset_b = vec2(3.1, 1.7);
uniform float foam_streak_scale_c : hint_range(0.01, 5.0) = 2.8;
uniform float foam_streak_speed_c : hint_range(-0.2, 0.2) = 0.06;
uniform vec2  foam_streak_offset_c = vec2(0.9, 4.2);
uniform float foam_streak_weight_a : hint_range(0.0, 1.0) = 0.5;
uniform float foam_streak_weight_b : hint_range(0.0, 1.0) = 0.3;
uniform float foam_streak_weight_c : hint_range(0.0, 1.0) = 0.2;
uniform float foam_factor_edge_lo : hint_range(0.0, 1.0) = 0.15;
uniform float foam_factor_edge_hi : hint_range(0.0, 1.0) = 0.55;
uniform float foam_noise_base : hint_range(0.0, 2.0) = 0.7;
uniform float foam_noise_strength : hint_range(0.0, 2.0) = 0.6;
uniform float foam_trail_scale : hint_range(0.01, 2.0) = 0.18;
uniform float foam_trail_speed : hint_range(0.0, 0.2) = 0.03;
uniform float foam_trail_weight : hint_range(0.0, 1.0) = 0.3;
uniform float foam_trail_jacobian_mult : hint_range(0.0, 1.0) = 0.4;

// --- refraction / albedo blend ---
uniform float refract_offset_strength : hint_range(0.0, 0.2) = 0.02;
uniform float refracted_mix : hint_range(0.0, 1.0) = 0.5;
uniform float fresnel_dark_mix : hint_range(0.0, 1.0) = 0.4;

// --- SSS / lighting ---
uniform float sss_backscatter_power : hint_range(0.0, 10.0) = 3.0;
uniform float sss_grazing_power : hint_range(0.0, 10.0) = 2.0;
uniform float sss_height_offset : hint_range(0.0, 10.0) = 4.0;
uniform float sss_height_range : hint_range(0.1, 20.0) = 6.0;
uniform float sss_near_strength : hint_range(0.0, 2.0) = 0.3;
uniform float sss_near_power : hint_range(0.1, 5.0) = 1.5;

// =====================================================================
//  VARYINGS
// =====================================================================

varying float v_wave_height;
varying float v_foam_factor;
varying float v_fresnel;
varying vec3  v_world_pos;
varying vec3  v_normal_ws;
varying float v_jacobian;
varying vec3 v_sample_pos;
varying float v_toksvig;


// =====================================================================
//  GRADIENT NOISE
// =====================================================================

vec2 hash2(vec2 p) {
    // two independent hashes -> pseudo-random direction
    uvec2 q = uvec2(ivec2(p));
    q = q * uvec2(1597334677u, 3812015801u);
    q.x ^= q.y;
    q = q * uvec2(1597334677u, 3812015801u);
    vec2 r = vec2(q) * (1.0 / 4294967296.0);
    return normalize(r * 2.0 - 1.0 + 1e-6);
}

float gnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0); // quintic, smoother than smoothstep

    float a = dot(hash2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0));
    float b = dot(hash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
    float c = dot(hash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
    float d = dot(hash2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));

    float result = mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
    return result * 0.5 + 0.5; // remap from [-1,1]-ish to [0,1] to match vnoise's range
}

// =====================================================================
//  HELPERS
// =====================================================================

float toksvig_roughen(vec3 detail_n, float base_rough) {
    // length of the averaged detail normal shrinks as high-freq variance increases
    float len = length(detail_n);
    len = clamp(len, 0.01, 1.0);
    float variance = (1.0 - len) / len;
    float rough_sq = base_rough * base_rough + variance;
    return clamp(sqrt(rough_sq), base_rough, 1.0);
}

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

vec3 ripple_normal(vec2 uv, float eps) {
    float h0 = gnoise(uv);
    float hx = gnoise(uv + vec2(eps, 0.0));
    float hz = gnoise(uv + vec2(0.0, eps));
    return normalize(vec3(h0 - hx, eps * 6.0, h0 - hz));
}

vec2 domain_warp(vec2 xz, float time) {
    float s  = warp_scale;
    float n1 = gnoise(xz * s              + time * warp_time_speed_a);
    float n2 = gnoise(xz * s * warp_freq_mult_b - time * (-warp_time_speed_b) + warp_offset_b);
    return vec2(n1, n2) * warp_strength;
}

// =====================================================================
//  GERSTNER WAVE
// =====================================================================

vec3 gerstner_wave(
    vec4  wave,
    float phase,
    vec3  pos,
    float time,
    inout vec3 tangent,
    inout vec3 binormal
) {
    float steepness  = wave.z;
    float wavelength = wave.w;
    float k          = 2.0 * 3.14159265 / wavelength;
    float c          = sqrt(9.8 / k);
    vec2  d          = normalize(wave.xy);
    float f          = k * (dot(d, pos.xz) - c * time) + phase;
    float a          = steepness / k;

    tangent += vec3(
        -d.x * d.x * (steepness * sin(f)),
         d.x * (steepness * cos(f)),
        -d.x * d.y * (steepness * sin(f))
    );
    binormal += vec3(
        -d.x * d.y * (steepness * sin(f)),
         d.y * (steepness * cos(f)),
        -d.y * d.y * (steepness * sin(f))
    );

    return vec3(
        d.x * (a * cos(f)),
        a * sin(f),
        d.y * (a * cos(f))
    );
}

vec3 gerstner_normal_analytic(vec3 sample_pos, float time) {
    vec3 tangent  = vec3(1.0, 0.0, 0.0);
    vec3 binormal = vec3(0.0, 0.0, 1.0);

    // same accumulation as gerstner_wave's tangent/binormal output,
    // but we don't need the displacement return value here
    vec3 dummy;
    dummy = gerstner_wave(wave_a, phase_a, sample_pos, time, tangent, binormal);
    dummy = gerstner_wave(wave_b, phase_b, sample_pos, time, tangent, binormal);
    dummy = gerstner_wave(wave_c, phase_c, sample_pos, time, tangent, binormal);
    dummy = gerstner_wave(wave_d, phase_d, sample_pos, time, tangent, binormal);
    dummy = gerstner_wave(wave_e, phase_e, sample_pos, time, tangent, binormal);
    dummy = gerstner_wave(wave_f, phase_f, sample_pos, time, tangent, binormal);
    dummy = gerstner_wave(wave_g, phase_g, sample_pos, time, tangent, binormal);
    dummy = gerstner_wave(wave_h, phase_h, sample_pos, time, tangent, binormal);

    return normalize(cross(normalize(binormal), normalize(tangent)));
}

// =====================================================================
//  LIGHTING HELPERS
// =====================================================================

float smith_masking_shadowing(float cos_theta, float alpha) {
    float a    = cos_theta / (alpha * sqrt(1.0 - cos_theta * cos_theta));
    float a_sq = a * a;
    return a < 1.6
        ? (1.0 - 1.259 * a + 0.396 * a_sq) / (3.535 * a + 2.181 * a_sq)
        : 0.0;
}

float ggx_distribution(float cos_theta, float alpha) {
    float a_sq = alpha * alpha;
    float d    = 1.0 + (a_sq - 1.0) * cos_theta * cos_theta;
    return a_sq / (PI * d * d);
}

// =====================================================================
//  VERTEX
// =====================================================================

void vertex() {
    vec3 world_pos  = VERTEX;
    vec3 sample_pos = world_pos;

    vec3 tangent  = vec3(1.0, 0.0, 0.0);
    vec3 binormal = vec3(0.0, 0.0, 1.0);
	v_sample_pos = world_pos;
    vec3 displaced = world_pos;

    displaced += gerstner_wave(wave_a, phase_a, sample_pos, TIME, tangent, binormal);
    displaced += gerstner_wave(wave_b, phase_b, sample_pos, TIME, tangent, binormal);
    displaced += gerstner_wave(wave_c, phase_c, sample_pos, TIME, tangent, binormal);
    displaced += gerstner_wave(wave_d, phase_d, sample_pos, TIME, tangent, binormal);
    displaced += gerstner_wave(wave_e, phase_e, sample_pos, TIME, tangent, binormal);
    displaced += gerstner_wave(wave_f, phase_f, sample_pos, TIME, tangent, binormal);
    displaced += gerstner_wave(wave_g, phase_g, sample_pos, TIME, tangent, binormal);
    displaced += gerstner_wave(wave_h, phase_h, sample_pos, TIME, tangent, binormal);

    float j    = tangent.x * binormal.z - tangent.z * binormal.x;
    v_jacobian = clamp(j, 0.0, 1.0);

    tangent  = normalize(tangent);
    binormal = normalize(binormal);
    vec3 normal_ws = normalize(cross(binormal, tangent));

    float dist_factor = exp(-length(world_pos.xz - CAMERA_POSITION_WORLD.xz) * normal_distance_falloff);
    normal_ws         = normalize(mix(vec3(0.0, 1.0, 0.0), normal_ws, dist_factor * normal_strength));

    v_normal_ws   = normal_ws;
    v_wave_height = displaced.y;
    v_world_pos   = displaced;

    VERTEX   = displaced;
    NORMAL   = normal_ws;
    TANGENT  = normalize(tangent);
    BINORMAL = normalize(binormal);
}

// =====================================================================
//  FRAGMENT
// =====================================================================

void fragment() {


    // --- base water color — much darker, ocean is nearly black ---
    float depth_t  = 1.0 - clamp((v_wave_height + depth_height_offset) / depth_height_range, 0.0, 1.0);
    vec3  water_col = mix(color_shallow.rgb, color_deep.rgb, depth_t);

    // trough darkening — valleys go near black
    float trough_t = clamp((-v_wave_height - trough_height_offset) / trough_height_range, 0.0, 1.0);
    water_col = mix(water_col, color_trough.rgb, trough_t * trough_darken_strength);

    // subtle color variation — patches of deeper/lighter water
    float patch  = vnoise(v_world_pos.xz * patch_scale_a + TIME * patch_speed_a);
    float patch2 = vnoise(v_world_pos.xz * patch_scale_b + TIME * patch_speed_b + patch_offset_b);
    float color_var = patch * patch_weight_a + patch2 * patch_weight_b;
    water_col = mix(water_col, color_deep.rgb * deep_color_var_mix, color_var * color_var_strength);

    // --- ripple normals ---
    vec2 warp     = domain_warp(v_world_pos.xz, TIME);
    vec2 flow_dir = normalize(vec2(v_normal_ws.x, v_normal_ws.z) + vec2(0.001));

	vec2 dir_a = flow_dir;
	vec2 dir_b = vec2(-flow_dir.y, flow_dir.x); // rotated 90°
	vec2 dir_c = vec2(flow_dir.x * 0.707 - flow_dir.y * 0.707,
	                   flow_dir.x * 0.707 + flow_dir.y * 0.707); // rotated 45°

	vec2 dir_d = vec2(flow_dir.x * 0.342 - flow_dir.y * 0.940,
                   flow_dir.x * 0.940 + flow_dir.y * 0.342); // ~70° rotation, deliberately odd angle

	vec2 uv_d = (v_world_pos.xz + warp) * ripple_scale_a * ripple_scale_d_mult + dir_d * TIME * flow_speed * ripple_speed_d_mult + ripple_offset_d;
	vec3 rn_d = ripple_normal(uv_d, ripple_eps);


	vec2 uv_a = (v_world_pos.xz + warp) * ripple_scale_a              + dir_a * TIME * flow_speed * ripple_speed_a_mult;
	vec2 uv_b = (v_world_pos.xz + warp) * ripple_scale_b              - dir_b * TIME * flow_speed * ripple_speed_b_mult;
	vec2 uv_c = (v_world_pos.xz + warp) * ripple_scale_a * ripple_scale_c_mult + dir_c * TIME * flow_speed * ripple_speed_c_mult + ripple_offset_c;

    vec3 rn_a = ripple_normal(uv_a, ripple_eps);
    vec3 rn_b = ripple_normal(uv_b, ripple_eps);
    vec3 rn_c = ripple_normal(uv_c, ripple_eps);

	vec3 detail_n = rn_a + rn_b + rn_c * detail_n_weight_c + rn_d * detail_n_weight_d;
	float toksvig_factor = toksvig_roughen(detail_n / detail_n_normalize_div, toksvig_base_roughness);
	v_toksvig = toksvig_factor;
	vec3 base_normal = gerstner_normal_analytic(v_sample_pos, TIME);

	vec3 base_normal_view = normalize((VIEW_MATRIX * vec4(base_normal, 0.0)).xyz);
	vec3 normal_dx = dFdx(base_normal_view);
	vec3 normal_dy = dFdy(base_normal_view);
	float geo_variance = dot(normal_dx, normal_dx) + dot(normal_dy, normal_dy);
	float geo_rough = sqrt(clamp(geo_variance * geo_roughness_scale, 0.0, 1.0));

	vec3 blended_n = normalize(vec3(
	    base_normal.x + detail_n.x * ripple_strength,
	    base_normal.y,
	    base_normal.z + detail_n.z * ripple_strength
	));

	vec3 normal_view = normalize((VIEW_MATRIX * vec4(blended_n, 0.0)).xyz); // <-- this line, derived from blended_n

	// --- fresnel — aggressive, drives everything ---
	float vdn     = clamp(dot(VIEW, normal_view), 0.0, 1.0);
    float fresnel = pow(1.0 - vdn, fresnel_power);
    // at grazing: nearly 1.0 (mirror). straight down: ~0.02 (transparent)
    fresnel = mix(reflectance, 1.0, fresnel);

    // --- surface roughness varies by local slope ---
    // steep wave faces are smoother (more mirror), flat areas rougher
    float slope    = 1.0 - clamp(dot(base_normal, vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
	float surf_rough = mix(roughness, roughness * slope_roughness_mult, slope * slope);
	surf_rough = max(surf_rough, toksvig_factor);
	surf_rough = max(surf_rough, geo_rough);   // new
	surf_rough = mix(surf_rough, foam_roughness_target, v_foam_factor);

    // --- foam ---
    float foam_crest = 1.0 - smoothstep(0.0, foam_crest_edge, v_jacobian);
    float streak_a   = vnoise(v_world_pos.xz * foam_streak_scale_a + TIME * foam_streak_speed_a);
    float streak_b   = vnoise(v_world_pos.xz * foam_streak_scale_b + TIME * foam_streak_speed_b + foam_streak_offset_b);
    float streak_c   = vnoise(v_world_pos.xz * foam_streak_scale_c + TIME * foam_streak_speed_c + foam_streak_offset_c);
    float foam_noise = streak_a * foam_streak_weight_a + streak_b * foam_streak_weight_b + streak_c * foam_streak_weight_c;
    float foam_factor = smoothstep(foam_factor_edge_lo, foam_factor_edge_hi, foam_crest * (foam_noise_base + foam_noise * foam_noise_strength));
    float trail      = vnoise(v_world_pos.xz * foam_trail_scale - flow_dir * TIME * foam_trail_speed) * foam_trail_weight;
    foam_factor      = max(foam_factor, trail * (1.0 - v_jacobian) * foam_trail_jacobian_mult);

    // --- refraction ---
   vec2 refract_offset = normal_view.xz * refract_offset_strength * (1.0 - fresnel);
	vec4 refracted = texture(SCREEN_TEXTURE, SCREEN_UV);

    // water color blends toward refracted at low fresnel (looking down)
    // and toward dark at high fresnel (grazing, reflective)
		vec3 base_col = mix(
	    refracted.rgb * refracted_mix + water_col * (1.0 - refracted_mix),
	    water_col * fresnel_dark_mix,
	    fresnel * fresnel
	);
	base_col = mix(base_col, color_foam.rgb, foam_factor);
    vec3 final_col = mix(base_col, color_foam.rgb, foam_factor);

    v_foam_factor = foam_factor;
    v_fresnel     = fresnel;

    ALBEDO    = final_col;
    // low roughness = sharp specular. varies by slope and foam.
    ROUGHNESS = surf_rough;
    METALLIC  = 0.0;
    SPECULAR  = 1.0;
    NORMAL    = normal_view;
}

// =====================================================================
//  LIGHT
// =====================================================================

void light() {
    vec3  halfway = normalize(LIGHT + VIEW);
    float dot_nl  = max(dot(NORMAL, LIGHT),   2e-5);
    float dot_nv  = max(dot(NORMAL, VIEW),    2e-5);
    float dot_nh  = max(dot(NORMAL, halfway), 2e-5);

    // variable roughness per fragment for specular
    float slope     = 1.0 - clamp(dot(NORMAL, vec3(0.0, 0.0, 1.0)), 0.0, 1.0);
    float surf_rough = mix(roughness, roughness * slope_roughness_mult, slope * slope);
	surf_rough = max(surf_rough, v_toksvig);
	surf_rough = mix(surf_rough, foam_roughness_target, v_foam_factor);

    float light_mask = smith_masking_shadowing(dot_nv, surf_rough);
    float view_mask  = smith_masking_shadowing(dot_nl, surf_rough);
    float ggx        = ggx_distribution(dot_nh, surf_rough);
    float geom       = 1.0 / (1.0 + light_mask + view_mask);

    // specular — sharp needle glints at low roughness
    SPECULAR_LIGHT += v_fresnel * ggx * geom / (4.0 * dot_nv + 0.001) * ATTENUATION;

    // SSS — backlit crest glow, teal-green through thin water
    float sss_scatter = pow(max(dot(LIGHT, -VIEW), 0.0), sss_backscatter_power)
                      * pow(max(0.5 - 0.5 * dot(LIGHT, NORMAL), 0.0), sss_grazing_power)
                      * clamp((v_wave_height + sss_height_offset) / sss_height_range, 0.0, 1.0)
                      * sss_strength;

    // near-camera SSS — soft glow on wave faces toward viewer
    float sss_near = sss_near_strength * pow(dot_nv, sss_near_power);

    // no lambertian — water is not a diffuse surface
    // diffuse comes entirely from SSS and ambient
    DIFFUSE_LIGHT += mix(
        (sss_scatter + sss_near) * color_sss.rgb / (1.0 + light_mask),
        color_foam.rgb,
        v_foam_factor
    ) * (1.0 - v_fresnel) * ATTENUATION * LIGHT_COLOR;
}