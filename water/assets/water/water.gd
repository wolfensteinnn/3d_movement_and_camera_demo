@tool
extends MeshInstance3D
## Handles updating the displacement/normal maps for the water material as well as
## managing wave generation pipelines.

const WATER_MAT := preload('res://water/assets/water/mat_water.tres')
const SPRAY_MAT := preload('res://water/assets/water/mat_spray.tres')
const WATER_MESH_HIGH := preload('res://water/assets/water/clipmap_high.obj')
const WATER_MESH_LOW := preload('res://water/assets/water/clipmap_low.obj')


@export_tool_button("Bake Placeholder Maps") var bake_action : Callable

enum MeshQuality { LOW, HIGH }

@export_group('Wave Parameters')
@export_color_no_alpha var water_color : Color = Color(0.1, 0.15, 0.18) :
	set(value): water_color = value; RenderingServer.global_shader_parameter_set(&'water_color', water_color.srgb_to_linear())

@export_color_no_alpha var foam_color : Color = Color(0.73, 0.67, 0.62) :
	set(value): foam_color = value; RenderingServer.global_shader_parameter_set(&'foam_color', foam_color.srgb_to_linear())

## The parameters for wave cascades. Each parameter set represents one cascade.
## Recreates all compute piplines whenever a cascade is added or removed!
@export var parameters : Array[WaveCascadeParameters] :
	set(value):
		var new_size := len(value)
		# All below logic is basically just required for using in the editor!
		for i in range(new_size):
			# Ensure all values in the array have an associated cascade
			if not value[i]: value[i] = WaveCascadeParameters.new()
			if not value[i].is_connected(&'scale_changed', _update_scales_uniform):
				value[i].scale_changed.connect(_update_scales_uniform)
			value[i].spectrum_seed = Vector2i(rng.randi_range(-10000, 10000), rng.randi_range(-10000, 10000))
			value[i].time = 120.0 + PI*i # We make sure to choose a time offset such that cascades don't interfere!
		parameters = value
		_setup_wave_generator()
		_update_scales_uniform()

@export_group('Performance Parameters')
@export_enum('128x128:128', '256x256:256', '512x512:512', '1024x1024:1024') var map_size := 1024 :
	set(value):
		map_size = value
		_setup_wave_generator()

@export var mesh_quality := MeshQuality.HIGH :
	set(value):
		mesh_quality = value
		mesh = WATER_MESH_HIGH if mesh_quality == MeshQuality.HIGH else WATER_MESH_LOW

## How many times the wave simulation should update per second.
## Note: This doesn't reduce the frame stutter caused by FFT calculation, only
##       minimizes GPU time taken by it!
@export_range(0, 60) var updates_per_second := 50.0 :
	set(value):
		next_update_time = next_update_time - (1.0/(updates_per_second + 1e-10) - 1.0/(value + 1e-10))
		updates_per_second = value

var wave_generator : WaveGenerator :
	set(value):
		if wave_generator: wave_generator.queue_free()
		wave_generator = value
		add_child(wave_generator)
var rng = RandomNumberGenerator.new()
var time := 0.0
var next_update_time := 0.0

var displacement_maps := Texture2DArrayRD.new()
var normal_maps := Texture2DArrayRD.new()

func bake_placeholder_maps() -> void:
	if not wave_generator or not wave_generator.context:
		push_warning("Wave generator not initialized yet — open the scene and let it tick a few frames first.")
		return
	_bake_array_rd(wave_generator.descriptors[&'displacement_map'], "res://water/assets/water/placeholder_displacement.tres")
	_bake_array_rd(wave_generator.descriptors[&'normal_map'], "res://water/assets/water/placeholder_normal.tres")
	print("Baked placeholder texture arrays.")

func _bake_array_rd(descriptor, save_path : String) -> void:
	var rd := RenderingServer.get_rendering_device()
	var rid : RID = descriptor.rid
	var format := rd.texture_get_format(rid)

	var images : Array[Image] = []
	for layer in format.array_layers:
		var data := rd.texture_get_data(rid, layer)
		var img := Image.create_from_data(format.width, format.height, false, Image.FORMAT_RGBAH, data)
		images.append(img)

	var tex_array := Texture2DArray.new()
	tex_array.create_from_images(images)
	var err := ResourceSaver.save(tex_array, save_path)
	if err != OK:
		push_error("Failed to save %s: %s" % [save_path, err])
	else:
		print("Saved %s (%d layers, %dx%d)" % [save_path, format.array_layers, format.width, format.height])

func _init() -> void:
	rng.set_seed(1234) # This seed gives big waves!
	bake_action = bake_placeholder_maps

func _ready() -> void:
	RenderingServer.global_shader_parameter_set(&'water_color', water_color.srgb_to_linear())
	RenderingServer.global_shader_parameter_set(&'foam_color', foam_color.srgb_to_linear())

func _process(delta : float) -> void:
	# Update waves once every 1.0/updates_per_second.
	if updates_per_second == 0 or time >= next_update_time:
		var target_update_delta := 1.0 / (updates_per_second + 1e-10)
		var update_delta := delta if updates_per_second == 0 else target_update_delta + (time - next_update_time)
		next_update_time = time + target_update_delta
		_update_water(update_delta)
	time += delta

	if not Engine.is_editor_hint():
		_manage_cpu_displacement_textures_updates(delta)

func _setup_wave_generator() -> void:
	if parameters.size() <= 0: return
	for param in parameters:
		param.should_generate_spectrum = true

	wave_generator = WaveGenerator.new()
	wave_generator.map_size = map_size
	wave_generator.init_gpu(maxi(2, parameters.size())) # FIXME: This is needed because my RenderContext API sucks...

	displacement_maps.texture_rd_rid = RID()
	normal_maps.texture_rd_rid = RID()
	displacement_maps.texture_rd_rid = wave_generator.descriptors[&'displacement_map'].rid
	normal_maps.texture_rd_rid = wave_generator.descriptors[&'normal_map'].rid

	RenderingServer.global_shader_parameter_set(&'num_cascades', parameters.size())
	RenderingServer.global_shader_parameter_set(&'displacements', displacement_maps)
	RenderingServer.global_shader_parameter_set(&'normals', normal_maps)

	_setup_cpu_displacement_textures()

func _update_scales_uniform() -> void:
	var map_scales : PackedVector4Array; map_scales.resize(len(parameters))
	for i in len(parameters):
		var params := parameters[i]
		var uv_scale := Vector2.ONE / params.tile_length
		map_scales[i] = Vector4(uv_scale.x, uv_scale.y, params.displacement_scale, params.normal_scale)
	# No global shader parameter for arrays :(
	WATER_MAT.set_shader_parameter(&'map_scales', map_scales)
	SPRAY_MAT.set_shader_parameter(&'map_scales', map_scales)

func _update_water(delta : float) -> void:
	if wave_generator == null: _setup_wave_generator()
	wave_generator.update(delta, parameters)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		displacement_maps.texture_rd_rid = RID()
		normal_maps.texture_rd_rid = RID()

# =============================================================================
#  displacement textures loading from gpu
#
#  NOTE: GPU texture readback (texture_get_data) can only happen on the
#  thread that owns the RenderingDevice (main thread, with the project's
#  Thread Model set to Single-Safe). We throttle to one cascade layer's
#  readback per interval to keep the per-frame cost small, at the cost of a
#  small stutter on the frame a readback happens.
# =============================================================================
var mutex : Mutex = Mutex.new()

# The set of cascade indices actually worth reading back (displacement > 0).
# Populated once in _setup_cpu_displacement_textures(), read elsewhere.
var _actually_used_textures_idx : Array = []

var _cpu_displacement_textures : Dictionary = {} # idx -> Image, read by get_height()
var _displacement_textures_total_update_interval : float = 1.0 / 120.0
var _displacement_textures_update_time : float = 0.0
var _texture_loading_index : int = 0

func _setup_cpu_displacement_textures() -> void:
	_actually_used_textures_idx.clear()
	for i in range(len(parameters)):
		if parameters[i].displacement_scale > 0.001:
			_actually_used_textures_idx.append(i)

	if _actually_used_textures_idx.is_empty():
		mutex.lock()
		_cpu_displacement_textures.clear()
		mutex.unlock()
		return

	var rid_displacement_map = wave_generator.descriptors[&'displacement_map'].rid
	var device : RenderingDevice = RenderingServer.get_rendering_device()

	mutex.lock()
	_cpu_displacement_textures.clear()
	for i in _actually_used_textures_idx:
		var tex := device.texture_get_data(rid_displacement_map, i) # layer == cascade index
		var img := Image.create_from_data(wave_generator.map_size, wave_generator.map_size, false, Image.FORMAT_RGBAH, tex)
		_cpu_displacement_textures[i] = img
	mutex.unlock()

func _manage_cpu_displacement_textures_updates(delta : float) -> void:
	if _cpu_displacement_textures.is_empty():
		return

	_displacement_textures_update_time += delta

	var time_per_texture := _displacement_textures_total_update_interval / float(_actually_used_textures_idx.size())
	if _displacement_textures_update_time < time_per_texture:
		return
	_displacement_textures_update_time = 0.0

	_texture_loading_index = (_texture_loading_index + 1) % _actually_used_textures_idx.size()
	var idx = _actually_used_textures_idx[_texture_loading_index]

	var rid_displacement_map = wave_generator.descriptors[&'displacement_map'].rid
	var device : RenderingDevice = RenderingServer.get_rendering_device()
	var tex := device.texture_get_data(rid_displacement_map, idx)
	var img := Image.create_from_data(wave_generator.map_size, wave_generator.map_size, false, Image.FORMAT_RGBAH, tex)

	mutex.lock()
	_cpu_displacement_textures[idx] = img
	mutex.unlock()

func _world_to_uv(W : Vector2, tile_length : Vector2) -> Vector2:
	return Vector2(
		(W[0] - tile_length.x * floor(W[0] / tile_length.x)) / tile_length.x,
		(W[1] - tile_length.y * floor(W[1] / tile_length.y)) / tile_length.y)

func get_height(world_pos : Vector3, steps : int = 3) -> float:
	var world_pos_xz := Vector2(world_pos.x, world_pos.z)
	var summed_height := 0.0

	mutex.lock()
	# Snapshot keys/images we need while holding the lock, then release it
	# before doing the iterative solve below (which doesn't touch shared state).
	var snapshot : Dictionary = {}
	for k in _cpu_displacement_textures.keys():
		snapshot[k] = _cpu_displacement_textures[k]
	mutex.unlock()

	for cascade_index in snapshot.keys():
		var displacement_scale : float = parameters[cascade_index].displacement_scale
		var tile_length : Vector2 = parameters[cascade_index].tile_length
		var img : Image = snapshot[cascade_index]
		var x := world_pos_xz
		var y_raw := Color.BLACK
		# Iteratively approximate the UV that produced this XZ displacement.
		for i in range(steps):
			var img_v := Vector2i(_world_to_uv(x, tile_length) * map_size)
			img_v.x = clampi(img_v.x, 0, map_size - 1)
			img_v.y = clampi(img_v.y, 0, map_size - 1)
			y_raw = img.get_pixelv(img_v)
			var y := Vector2(y_raw.r, y_raw.b)
			x = world_pos_xz - y
		summed_height += y_raw.g * displacement_scale
	return summed_height
