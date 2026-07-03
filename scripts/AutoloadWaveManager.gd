extends Node

@onready var water: MeshInstance3D = $"../Water"

const ANGLE_KEY := &"wind_direction"

# ---------------------------------------------------------------------------
# Valid ranges per parameter — enforced after all layers combine.
# ---------------------------------------------------------------------------
var param_ranges : Dictionary = {
	wind_speed         = Vector2(0.0, 25.0),
	fetch_length       = Vector2(0.0, 2000.0),
	swell              = Vector2(0.0, 2.0),
	spread             = Vector2(0.0, 1.0),
	detail             = Vector2(0.0, 1.0),
	whitecap           = Vector2(0.0, 2.0),
	foam_amount        = Vector2(0.0, 10.0),
	displacement_scale = Vector2(0.0, 2.0),
	normal_scale       = Vector2(0.0, 2.0),
}

# ---------------------------------------------------------------------------
# 1) STATE LAYER — intensity only. NO wind_direction in here anymore;
#    direction is fully decoupled, see WIND DIRECTION LAYER below.
#    Paste captured snapshots from the ImGui panel in here (minus wind_direction).
# ---------------------------------------------------------------------------
var presets : Dictionary = {
	&"super_calm": [
	{ wind_speed = 2.000, fetch_length = 195.001, swell = 0.800, spread = 0.200, detail = 1.000, whitecap = 0.500, foam_amount = 5.449, displacement_scale = 0.125, normal_scale = 1.000 },
	{ wind_speed = 3.000, fetch_length = 150.000, swell = 0.800, spread = 0.400, detail = 1.000, whitecap = 0.500, foam_amount = 0.000, displacement_scale = 0.094, normal_scale = 1.000 },
	{ wind_speed = 3.000, fetch_length = 550.000, swell = 0.800, spread = 0.400, detail = 1.000, whitecap = 0.250, foam_amount = 3.000, displacement_scale = 0.021, normal_scale = 0.771 },
	],
	&"calm_1": [
	{ wind_speed = 3.000, fetch_length = 150.000, swell = 0.800, spread = 0.200, detail = 1.000, whitecap = 0.500, foam_amount = 3.990, displacement_scale = 0.365, normal_scale = 1.000 },
	{ wind_speed = 5.000, fetch_length = 150.000, swell = 0.800, spread = 0.400, detail = 1.000, whitecap = 0.500, foam_amount = 0.000, displacement_scale = 0.094, normal_scale = 1.000 },
	{ wind_speed = 8.000, fetch_length = 550.000, swell = 0.800, spread = 0.400, detail = 1.000, whitecap = 0.250, foam_amount = 3.000, displacement_scale = 0.052, normal_scale = 0.250 },
	],
	&"rogue_wave_calm": [
	{ wind_speed = 11.000, fetch_length = 150.000, swell = 1.417, spread = 0.312, detail = 1.000, whitecap = 0.500, foam_amount = 4.041, displacement_scale = 1.302, normal_scale = 0.990 },
	{ wind_speed = 3.000, fetch_length = 150.000, swell = 0.800, spread = 0.400, detail = 1.000, whitecap = 0.500, foam_amount = 0.000, displacement_scale = 0.083, normal_scale = 1.000 },
	{ wind_speed = 2.000, fetch_length = 550.000, swell = 0.800, spread = 0.400, detail = 1.000, whitecap = 0.250, foam_amount = 3.000, displacement_scale = 0.042, normal_scale = 0.250 },
	],
	&"medium_1": [
	{ wind_speed = 4.000, fetch_length = 150.000, swell = 0.800, spread = 0.200, detail = 1.000, whitecap = 0.500, foam_amount = 4.531, displacement_scale = 0.490, normal_scale = 1.000 },
	{ wind_speed = 11.000, fetch_length = 150.000, swell = 0.800, spread = 0.400, detail = 1.000, whitecap = 0.500, foam_amount = 0.000, displacement_scale = 0.323, normal_scale = 1.000 },
	{ wind_speed = 20.000, fetch_length = 550.000, swell = 0.800, spread = 0.400, detail = 1.000, whitecap = 0.250, foam_amount = 3.000, displacement_scale = 0.000, normal_scale = 0.250 },
	],
	&"rogue_medium": [
	{ wind_speed = 3.000, fetch_length = 150.000, swell = 0.800, spread = 0.200, detail = 1.000, whitecap = 0.500, foam_amount = 6.458, displacement_scale = 0.802, normal_scale = 1.000 },
	{ wind_speed = 9.000, fetch_length = 150.000, swell = 2.000, spread = 0.120, detail = 1.000, whitecap = 0.500, foam_amount = 1.458, displacement_scale = 1.469, normal_scale = 1.000 },
	{ wind_speed = 20.000, fetch_length = 550.000, swell = 0.800, spread = 0.400, detail = 1.000, whitecap = 0.250, foam_amount = 3.000, displacement_scale = 0.000, normal_scale = 0.250 },
	],
	&"stormy": [
	{ wind_speed = 10.000, fetch_length = 150.000, swell = 0.800, spread = 0.200, detail = 1.000, whitecap = 0.500, foam_amount = 6.906, displacement_scale = 1.073, normal_scale = 1.000 },
	{ wind_speed = 5.000, fetch_length = 150.000, swell = 0.800, spread = 0.400, detail = 1.000, whitecap = 0.500, foam_amount = 0.000, displacement_scale = 0.750, normal_scale = 1.000 },
	{ wind_speed = 20.000, fetch_length = 550.000, swell = 0.800, spread = 0.400, detail = 1.000, whitecap = 0.250, foam_amount = 3.000, displacement_scale = 0.000, normal_scale = 0.250 },
	],
	&"stormy_rogue": [
	{ wind_speed = 10.000, fetch_length = 150.000, swell = 0.989, spread = 0.000, detail = 1.000, whitecap = 0.500, foam_amount = 6.906, displacement_scale = 1.802, normal_scale = 1.229 },
	{ wind_speed = 1.000, fetch_length = 150.000, swell = 0.800, spread = 0.400, detail = 1.000, whitecap = 0.500, foam_amount = 0.000, displacement_scale = 0.750, normal_scale = 1.000 },
	{ wind_speed = 20.000, fetch_length = 550.000, swell = 0.800, spread = 0.400, detail = 1.000, whitecap = 0.250, foam_amount = 3.000, displacement_scale = 0.000, normal_scale = 0.250 },
	],
	&"serious_storm": [
	{ wind_speed = 14.000, fetch_length = 150.000, swell = 0.800, spread = 0.200, detail = 1.000, whitecap = 0.500, foam_amount = 5.552, displacement_scale = 1.292, normal_scale = 1.000 },
	{ wind_speed = 12.000, fetch_length = 150.000, swell = 0.800, spread = 0.400, detail = 1.000, whitecap = 0.500, foam_amount = 0.000, displacement_scale = 1.031, normal_scale = 1.000 },
	{ wind_speed = 20.000, fetch_length = 550.000, swell = 0.800, spread = 0.400, detail = 1.000, whitecap = 0.250, foam_amount = 3.000, displacement_scale = 0.000, normal_scale = 0.250 },
	],
	&"serious_storm_rogue": [
	{ wind_speed = 12.000, fetch_length = 150.000, swell = 1.635, spread = 0.094, detail = 1.000, whitecap = 0.500, foam_amount = 5.833, displacement_scale = 1.552, normal_scale = 1.000 },
	{ wind_speed = 7.000, fetch_length = 150.000, swell = 0.800, spread = 0.177, detail = 1.000, whitecap = 0.677, foam_amount = 0.365, displacement_scale = 1.448, normal_scale = 1.000 },
	{ wind_speed = 20.000, fetch_length = 550.000, swell = 0.800, spread = 0.400, detail = 1.000, whitecap = 0.250, foam_amount = 3.000, displacement_scale = 0.000, normal_scale = 0.250 },
]
	
}

var current_state_name : StringName = &"super_calm"
var _state_current : Array = []
var _state_target : Array = presets[current_state_name]
@export var state_smoothing_speed := 0.0015

# ---------------------------------------------------------------------------
# 2) SHORE LAYER — unchanged.
# ---------------------------------------------------------------------------
var shore_factor := 0.0
var _shore_target := 0.0
@export var shore_smoothing_speed := 0.2

var shore_modifiers : Dictionary = {
	fetch_length = -600.0,
	swell        = -0.4,
	whitecap     =  0.25,
	spread       =  0.25,
}

# ---------------------------------------------------------------------------
# 3) WIND DIRECTION LAYER — fully independent of state/shore.
#    World manager calls set_wind_direction() whenever it decides the wind
#    should shift; this layer handles the "how" (hyper-slow chase + wobble).
# ---------------------------------------------------------------------------
@export var wind_direction_chase_speed := 0.015      # deliberately much slower than state/shore chases
@export var wind_direction_wobble_amplitude := 6.0    # degrees of slow organic wander around current
@export var wind_direction_wobble_speed := 0.02       # how fast that wobble itself drifts

## Fixed per-cascade offset from the base direction (degrees). Index 0 = wind-sea
## (follows base directly), index 1 = swell (trails behind — swell is a memory
## of a distant system, doesn't snap to local wind instantly). Add more entries
## if you add more cascades.
var cascade_direction_offset : Array[float] = [0.0, 5.0, 0.05]


var _wind_direction_target := 0.0
var _wind_direction_current := 0.0
var _wind_direction_noise : FastNoiseLite

# ---------------------------------------------------------------------------
# 4) AMBIENT LAYER — intensity-side wobble only now; direction wobble moved
#    into the wind direction layer above where it belongs.
# ---------------------------------------------------------------------------
var ambient_amplitude : Dictionary = {
	wind_speed = 0.4,
	swell      = 0.05,
	spread     = 0.05,
	whitecap   = 0.08,
}
var ambient_speed := 0.05
var _ambient_time := 0.0
var _noise_by_param : Dictionary = {}

# ---------------------------------------------------------------------------
func _ready() -> void:
	set_multiplayer_authority(1)
	for key in ambient_amplitude.keys():
		var n := FastNoiseLite.new()
		n.seed = hash(key)
		n.frequency = 1.0
		_noise_by_param[key] = n

	_wind_direction_noise = FastNoiseLite.new()
	_wind_direction_noise.seed = hash(&"wind_direction_wobble")
	_wind_direction_noise.frequency = 1.0

	_state_current = _snapshot_current_state()
	_wind_direction_current = water.parameters[0].wind_direction if water.parameters.size() > 0 else 0.0
	_wind_direction_target = _wind_direction_current

func _process(delta : float) -> void:
	_ambient_time += delta * ambient_speed
	_chase_state(delta)
	_chase_shore(delta)
	_chase_wind_direction(delta)
	_apply_layers()

# --- State ------------------------------------------------------------
func set_state(state_name : StringName) -> void:
	if not multiplayer.is_server():
		push_warning("set_state() called on a non-server peer; ignored.")
		return
	if not presets.has(state_name):
		push_warning("Unknown wave state: %s" % state_name)
		return
	current_state_name = state_name
	_retarget_state.rpc(presets[state_name])

@rpc("authority", "call_local", "reliable")
func _retarget_state(target : Array) -> void:
	_state_target = target

func _chase_state(delta : float) -> void:
	var t := 1.0 - exp(-state_smoothing_speed * delta * 60.0)
	for i in range(_state_current.size()):
		var current : Dictionary = _state_current[i]
		var target : Dictionary = _state_target[i] if i < _state_target.size() else _state_target[_state_target.size() - 1]
		for key in target.keys():
			current[key] = lerpf(current.get(key, target[key]), target[key], t)

# --- Shore --------------------------------------------------------------
func set_shore_factor(value : float) -> void:
	if not multiplayer.is_server():
		push_warning("set_shore_factor() called on a non-server peer; ignored.")
		return
	_retarget_shore.rpc(clampf(value, 0.0, 1.0))

@rpc("authority", "call_local", "reliable")
func _retarget_shore(value : float) -> void:
	_shore_target = value

func _chase_shore(delta : float) -> void:
	var t := 1.0 - exp(-shore_smoothing_speed * delta * 60.0)
	shore_factor = lerpf(shore_factor, _shore_target, t)

# --- Wind direction -------------------------------------------------------
## Called by your world manager whenever it decides the wind should shift
## (random timer, scripted event, whatever — this layer doesn't care why).
func set_wind_direction(degrees : float) -> void:
	if not multiplayer.is_server():
		push_warning("set_wind_direction() called on a non-server peer; ignored.")
		return
	_retarget_wind_direction.rpc(fposmod(degrees, 360.0))

@rpc("authority", "call_local", "reliable")
func _retarget_wind_direction(degrees : float) -> void:
	_wind_direction_target = degrees

func _chase_wind_direction(delta : float) -> void:
	var t := 1.0 - exp(-wind_direction_chase_speed * delta * 60.0)
	_wind_direction_current = rad_to_deg(lerp_angle(deg_to_rad(_wind_direction_current), deg_to_rad(_wind_direction_target), t))

# --- Combine everything, clamp, write to cascades --------------------------
func _apply_layers() -> void:
	var wobble := _wind_direction_noise.get_noise_1d(_ambient_time * (wind_direction_wobble_speed / ambient_speed)) * wind_direction_wobble_amplitude

	for i in range(water.parameters.size()):
		var current : Dictionary = _state_current[i] if i < _state_current.size() else {}
		var params : Variant = water.parameters[i]

		for key in current.keys():
			var value : float = current[key]
			if shore_modifiers.has(key):
				value += shore_modifiers[key] * shore_factor
			if ambient_amplitude.has(key):
				var n : FastNoiseLite = _noise_by_param[key]
				value += n.get_noise_1d(_ambient_time) * ambient_amplitude[key]
			if param_ranges.has(key):
				var r : Vector2 = param_ranges[key]
				value = clampf(value, r.x, r.y)
			params.set(key, value)

		var offset := cascade_direction_offset[i] if i < cascade_direction_offset.size() else 0.0
		params.set(ANGLE_KEY, fposmod(_wind_direction_current + offset + wobble, 360.0))

func _snapshot_current_state() -> Array:
	var snapshot : Array = []
	for params in water.parameters:
		snapshot.append({
			wind_speed = params.wind_speed, fetch_length = params.fetch_length, swell = params.swell,
			spread = params.spread, detail = params.detail, whitecap = params.whitecap,
			foam_amount = params.foam_amount, displacement_scale = params.displacement_scale,
			normal_scale = params.normal_scale,
		})
	return snapshot
