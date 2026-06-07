extends CharacterBody3D
@onready var camera_mount: Node3D = $CameraMount
@onready var camera_main: Camera3D = $CameraMount/Camera3D
@onready var meshes: Skeleton3D = $duck/Armature/Skeleton3D
@onready var grab_cast: RayCast3D = $CameraMount/GrabCast

var debug_velocity

#UI
var stamina_bar
var cursor

# CAMERA GENERAL
const CAMERA_ATTACH_SMOOTH_SPEED = 8.6
const CAMERA_DEFAULT_SMOOTH_SPEED = 16.0
var camera_smooth_pos: Vector3 = Vector3.ZERO
const LOOK_SMOOTHING = 17.0
const MOUSE_SENSITIVITY = 0.002

# CAMERA BOB
const BOB_FREQUENCY = 20.6
const BOB_AMPLITUDE_Y = 0.018
const BOB_AMPLITUDE_X = 0.01
var bob_time: float = 0.0

# FOV AND CAMERA STUFF
const FOV_DEFAULT = 70.0
const FOV_SPRINT = 66.0
const FOV_LERP_SPEED = 2.8
const FOV_CLIMB = 78.0
const CLIMB_TILT_STRENGTH = 0.04
const CLIMB_TILT_SPEED = 6.0

const CLIMB_CAMERA_TILT_UP = -0.08
const CLIMB_CAMERA_TILT_SPEED = 2.5
var climb_camera_tilt: float = 0.0
const CLIMB_CAMERA_TILT_TARGET: float = -0.08
const CLIMB_CAMERA_TILT_OVERSHOOT: float = -0.18
var climb_camera_tilt_target: float = 0.0

#FOR CUSTOM MULTIPLAYER SPAWNING
var is_master: bool
var initial_transform: Vector3

# MOVEMENT AND PHYSICS
var SPEED = 0.58
var ACCELERATION = 6.0

#SPRINT
const SPRINT_SPEED = 0.65
const SPRINT_AIR_ACCELERATION = 0.8
const STAMINA_SPRINT_COST = 18.0
var is_sprinting: bool = false
var jumped_while_sprinting: bool = false

# MANTLING
var is_mantling: bool = false
var mantle_timer: float = 0.0
const MANTLE_DURATION = 0.68        # total time of the mantle
const MANTLE_LERP_SPEED = 0.12      # lower = floatier, higher = snappier
var mantle_target: Vector3 = Vector3.ZERO
const MANTLE_DISTANCE = 0.08 #around 25% of the duck
var mantle_reacquire_timer: float = 0.0
const MANTLE_REACQUIRE_COOLDOWN = 0.48

# CLIMB INIT
var is_climb_attaching: bool = false
var climb_attach_timer: float = 0.0
const CLIMB_ATTACH_DURATION = 0.12
var climb_attach_target: Vector3 = Vector3.ZERO
# CLIMB BOOST
var climb_attach_boost: float = 0.0
const CLIMB_ATTACH_BOOST_STRENGTH = 0.24
const CLIMB_ATTACH_BOOST_DECAY = 8.8
# CLIMB CAMERA DIP
var camera_attach_smooth_timer: float = 0.0
const CAMERA_ATTACH_SMOOTH_DURATION = 0.48


# NEW NEW CLIMBING (WITH PROBES)
const WALL_PROBE_LENGTH = 0.18
const WALL_PROBE_SPREAD = 0.055
const WALL_NORMAL_DIVERGENCE_THRESHOLD = 0.85
const WALL_ACQUISITION_LENGTH = 0.21
const WALL_ACQUISITION_VERTICAL_SPREAD = 0.08
const CLIMB_DETACH_GRACE = 0.4
const CLIMB_REACQUIRE_COOLDOWN = 0.12
var climb_detach_timer: float = 0.0
var climb_reacquire_timer: float = 0.0
var wall_nudge_timer: float = 0.0
var wall_nudge_dir: Vector3 = Vector3.ZERO
const WALL_NUDGE_DURATION = 0.14
const WALL_NUDGE_STRENGTH = 0.55
var prev_wall_normal: Vector3 = Vector3.ZERO

# CLIMBABLE SURFACE ANGLE THRESHOLDS
# normal.y > CLIMB_FLOOR_THRESHOLD  → too floor-like, reject
# normal.y < CLIMB_CEIL_THRESHOLD   → too ceiling-like, reject
# overhangs (negative normal.y) are given a little more leniency
# than floors so surfaces that aren't walkable can still be climbed
const CLIMB_FLOOR_THRESHOLD = 0.629   #  DEGREES
const CLIMB_CEIL_THRESHOLD  = -0.99   # BASSICALLY ANYTHING

# WALL DISTANCE
# how far the player sits from the wall surface on attach and maintain
const CLIMB_WALL_OFFSET = 0.045       # offset on _start_climb snap
const CLIMB_MAINTAIN_DEPTH = 0.4     # how deep _maintain_climb casts into wall

# NEW CLIMBING
var climb_wall_normal: Vector3 = Vector3.ZERO
var current_wall_normal: Vector3 = Vector3.ZERO

# CLIMBING
var is_climbing = false
var climb_speed: float = 0.28
var climb_tilt: float = 0.0

# STAMINA
const STAMINA_MAX = 200.0
const STAMINA_MOMENTUM_BOOST_EMPTY = 1.08
const STAMINA_REGEN_RATE = 52.0
const STAMINA_REGEN_DELAY = 1.4
const STAMINA_JUMP_COST = 30.0
const STAMINA_CLIMB_COST = 0.5

var stamina: float = 100.0
var stamina_regen_timer: float = 0.0

# GRAVITY
const GRAVITY_UP = -7.0
const GRAVITY_DOWN = -3.0
const GRAVITY_PEAK_THRESHOLD = 1.0
const GRAVITY_PEAK_MULTIPLIER = 0.4

#JUMP
const JUMP_VELOCITY = 1.48
const JUMP_GRACE_TIME = 0.07
const JUMP_BUFFER_TIME = 0.12
var jump_grace_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var AIR_ACCELERATION = 5.6
const JUMP_MOMENTUM_BOOST = 1.36

# LANDING DIP
const LANDING_DIP_STRENGTH = 0.1
const LANDING_DIP_SPEED = 14.0
var landing_dip: float = 0.0
var was_on_floor: bool = true

# THROWING
var held_player: CharacterBody3D = null
var is_held: bool = false
var holder_authority: int = -1
@export var grab_range: float = 0.2
var throw_charge: float = 0.0
var max_throw_force: float = 100.00
var charge_speed: float = 5.0
var held_player_original_authority: int = -1
var is_thrown: bool = false

# LOOK TARGETS
var target_rotation_y: float = 0.0
var target_rotation_x: float = 0.0


func _is_climbable_normal(n: Vector3) -> bool:
	return n.y < CLIMB_FLOOR_THRESHOLD and n.y > CLIMB_CEIL_THRESHOLD


func _set_cursor(a_cursor):
	cursor = a_cursor

func _set_cursor_active():
	if !is_climbing:
		cursor.texture = preload("res://CrossHairActive.png")

func _set_cursor_base():
	if !is_climbing:
		cursor.texture = preload("res://CrossHair.png")

func _set_cursor_climb():
	cursor.texture = preload("res://CrossHairClimb.png")

func _set_stamina_bar(a_bar):
	stamina_bar = a_bar

func _set_debug_velocityLabel(a_label):
	debug_velocity = a_label

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	camera_smooth_pos = global_position
	velocity = Vector3.ZERO
	if is_multiplayer_authority():
		global_position = initial_transform
		camera_main.current = true
		camera_main.set_cull_mask_value(2, false)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		for any in meshes.get_children():
			any.set_layer_mask_value(1, false)
			any.set_layer_mask_value(2, true)
		target_rotation_y = rotation.y
		target_rotation_x = camera_mount.rotation.x

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
# Re-lock mouse when clicking into window
	if event is InputEventMouseButton and event.pressed:
		if get_window().has_focus() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if name.to_int() != multiplayer.get_unique_id():
			return
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and get_window().has_focus():
			target_rotation_x += event.relative.y * MOUSE_SENSITIVITY
			target_rotation_x = clamp(target_rotation_x, deg_to_rad(-75), deg_to_rad(75))
			target_rotation_y -= event.relative.x * MOUSE_SENSITIVITY
			if is_held:  # only bother broadcasting when held, normally sync handles it
				rpc_id(holder_authority, "sync_look_rotation", target_rotation_x, target_rotation_y)
		return
	if !is_multiplayer_authority():
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	#if event is InputEventMouseMotion:
		#target_rotation_y -= event.relative.x * MOUSE_SENSITIVITY
		#target_rotation_x += event.relative.y * MOUSE_SENSITIVITY
		#target_rotation_x = clamp(target_rotation_x, deg_to_rad(-75), deg_to_rad(75))

	if event.is_action_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME

func _update_stamina(delta: float) -> void:
	if stamina_regen_timer > 0.0:
		stamina_regen_timer -= delta
	else:
		stamina = min(stamina + STAMINA_REGEN_RATE * delta, STAMINA_MAX)
	if is_instance_valid(stamina_bar):
		stamina_bar.value = max(stamina, 0)

func _maintain_climb() -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + (-climb_wall_normal * CLIMB_MAINTAIN_DEPTH)
	)
	query.exclude = [self]
	return space_state.intersect_ray(query)

func _start_climb() -> void:
	climb_camera_tilt = 0.08   # push down first
	climb_camera_tilt_target = CLIMB_CAMERA_TILT_OVERSHOOT  # target is up
	camera_attach_smooth_timer = CAMERA_ATTACH_SMOOTH_DURATION
	climb_attach_boost = CLIMB_ATTACH_BOOST_STRENGTH
	landing_dip = 0.0
	climb_detach_timer = 0.0
	current_wall_normal = climb_wall_normal
	_set_cursor_climb()
	is_climbing = true
	is_climb_attaching = true
	climb_attach_timer = CLIMB_ATTACH_DURATION
	var hit = _maintain_climb()
	if hit:
		climb_attach_target = hit.position + climb_wall_normal * CLIMB_WALL_OFFSET
		climb_attach_target.y = global_position.y + 0.09  # preserve vertical position + slight nudge upwards
	else:
		climb_attach_target = global_position

func _stop_climb() -> void:
	is_climbing = false
	climb_detach_timer = 0.0
	climb_reacquire_timer = CLIMB_REACQUIRE_COOLDOWN

func _get_wall_manifold() -> Dictionary:
	var space = get_world_3d().direct_space_state
	var forward = -climb_wall_normal if is_climbing else global_basis.z
	var right = global_basis.x
	var origin = global_position

	var probe_origins = [
		origin,
		origin + right * WALL_PROBE_SPREAD,
		origin - right * WALL_PROBE_SPREAD,
		origin + right * WALL_PROBE_SPREAD * 2.0,
		origin - right * WALL_PROBE_SPREAD * 2.0,
	]

	var params = PhysicsRayQueryParameters3D.new()
	params.exclude = [self]
	params.collision_mask = 1

	var hits = []
	for probe in probe_origins:
		params.from = probe
		params.to = probe + forward * WALL_PROBE_LENGTH
		var hit = space.intersect_ray(params)
		hits.append(hit)

	var center = hits[0]
	var right_hit = hits[1]
	var left_hit = hits[2]
	var far_right_hit = hits[3]
	var far_left_hit = hits[4]

	if center.is_empty() and right_hit.is_empty() and left_hit.is_empty() and far_right_hit.is_empty() and far_left_hit.is_empty():
		return { "hit": false }

	var normals = []
	var points = []
	for h in hits:
		if not h.is_empty():
			normals.append(h.normal)
			points.append(h.position)

	var avg_normal = Vector3.ZERO
	var avg_point = Vector3.ZERO
	for n in normals:
		avg_normal += n
	for p in points:
		avg_point += p
	avg_normal = (avg_normal / normals.size()).normalized()
	avg_point = avg_point / points.size()

	var divergent = false
	if normals.size() > 1:
		for i in range(normals.size() - 1):
			if normals[i].dot(normals[i + 1]) < WALL_NORMAL_DIVERGENCE_THRESHOLD:
				divergent = true
				break

	if not _is_climbable_normal(avg_normal):
		return { "hit": false }

	return {
		"hit": true,
		"normal": avg_normal,
		"point": avg_point,
		"center_hit": not center.is_empty(),
		"right_hit": not right_hit.is_empty() or not far_right_hit.is_empty(),
		"left_hit": not left_hit.is_empty() or not far_left_hit.is_empty(),
		"divergent": divergent,
	}

func _search_for_wall() -> Dictionary:
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.exclude = [self]
	params.collision_mask = 1

	var search_angles = [-90.0, -60.0, -30.0, 0.0, 30.0, 60.0, 90.0]
	var best_hit = {}
	var best_score = -1.0

	for angle_deg in search_angles:
		var rotated_dir = -climb_wall_normal.rotated(Vector3.UP, deg_to_rad(angle_deg))
		params.from = global_position
		params.to = global_position + rotated_dir * WALL_PROBE_LENGTH * 3.0
		var hit = space.intersect_ray(params)
		if not hit.is_empty() and _is_climbable_normal(hit.normal):
			var diff = 1.0 - prev_wall_normal.dot(hit.normal)
			if diff > best_score:
				best_score = diff
				best_hit = hit

	return best_hit

func _try_acquire_wall() -> Dictionary:
	var space = get_world_3d().direct_space_state
	var forward = global_basis.z
	var origin = global_position

	var probe_origins = [
		origin,
		origin + Vector3.UP * WALL_ACQUISITION_VERTICAL_SPREAD,
		origin - Vector3.UP * WALL_ACQUISITION_VERTICAL_SPREAD,
	]

	var params = PhysicsRayQueryParameters3D.new()
	params.exclude = [self]
	params.collision_mask = 1

	for probe in probe_origins:
		params.from = probe
		params.to = probe + forward * WALL_ACQUISITION_LENGTH
		var hit = space.intersect_ray(params)
		if not hit.is_empty() and _is_climbable_normal(hit.normal):
			if is_on_floor() and hit.position.y < global_position.y - 0.05:
				continue
			return hit
	return {}

func _sliding_into_walls_check():
	if is_on_floor():
		return
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var n = col.get_normal()
		if n.dot(climb_wall_normal) < 0.5 and _is_climbable_normal(n):
			prev_wall_normal = climb_wall_normal
			climb_wall_normal = n
			current_wall_normal = n
			climb_detach_timer = 0.0
			break

func _try_mantle() -> Dictionary:
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.exclude = [self]
	params.collision_mask = 1
	
	# cast forward at chest height to find the wall face
	var forward = -climb_wall_normal
	params.from = global_position
	params.to = global_position + forward * (CLIMB_WALL_OFFSET + 0.1)
	var wall_hit = space.intersect_ray(params)
	
	
	if wall_hit.is_empty():
		return {}
	
	# cast down from above the ledge to find the top surface
	var ledge_top_origin = wall_hit.position + Vector3.UP * 0.25 + forward * 0.05
	params.from = ledge_top_origin
	params.to = ledge_top_origin + Vector3.DOWN * 0.25
	var ledge_hit = space.intersect_ray(params)
	
	
	if ledge_hit.is_empty():
		return {}
	
	var ledge_height_diff = ledge_hit.position.y - global_position.y
	if ledge_height_diff > 0.12 or ledge_height_diff < -0.05:
		return {}
	
	# confirm the landing spot is walkable
	if ledge_hit.normal.y < 0.629:
		return {}
	
	return { "position": ledge_hit.position }

#GRABBING PLAYERS ---------------------------------------------- GRABBING PLAYERS
func _try_grab() -> void:
	grab_cast.force_raycast_update()

	if grab_cast.is_colliding():
		var hold_target = grab_cast.get_collider()
		if hold_target is CharacterBody3D and hold_target != self:
			if hold_target.is_held:
				rpc_id(hold_target.holder_authority, "force_release_held")
			held_player = hold_target
			held_player_original_authority = hold_target.name.to_int()
			held_player.set_multiplayer_authority((get_multiplayer_authority()))
			held_player.rpc("set_held", true, get_multiplayer_authority())

@rpc("any_peer", "reliable")
func set_held(held: bool, holder_id: int) -> void:
	is_held = held
	holder_authority = holder_id
	if not held:
		holder_authority = -1
		set_multiplayer_authority(name.to_int())
	else:
		set_multiplayer_authority(holder_id)

@rpc("any_peer", "reliable")
func force_release_held() -> void:
	held_player = null
	throw_charge = 0.0

func _throw_player() -> void:
	if held_player == null:
		return
	var throw_direction = -camera_main.global_transform.basis.z.normalized()
	var throw_velocity = throw_direction * throw_charge
	throw_velocity.y = throw_charge * 0.5
	held_player.set_multiplayer_authority(held_player_original_authority)
	held_player.rpc("set_held", false, -1)
	held_player.rpc("receive_throw", throw_velocity)
	throw_charge = 0.0
	held_player = null

@rpc("any_peer", "unreliable")
func sync_look_rotation(rot_x: float, rot_y: float) -> void:
	target_rotation_x = rot_x
	target_rotation_y = rot_y

func _update_held_player() -> void:
	if held_player == null:
		return
	if held_player.get_multiplayer_authority() != get_multiplayer_authority():
		held_player = null
		return
	if not held_player.is_multiplayer_authority():
		return
	var hold_position = global_position + (global_basis.z * 0.1)
	hold_position.y = global_position.y + 0.2
	held_player.global_position = hold_position
	held_player.velocity = Vector3.ZERO
	#held_player.rpc("_move_camera_on_held",held_player_original_authority)

@rpc("any_peer", "reliable")
func receive_throw(throw_velocity: Vector3) -> void:
	if is_multiplayer_authority():
		is_thrown = true
		velocity = throw_velocity

@rpc("any_peer","reliable")
func _move_camera_on_held(delta):
	velocity = Vector3.ZERO
	rotation.y = lerp_angle(rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
	camera_mount.rotation.y = lerp_angle(camera_mount.rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
	camera_mount.rotation.x = lerp_angle(camera_mount.rotation.x, target_rotation_x, LOOK_SMOOTHING * delta)
	move_and_slide()
	_update_bob(delta)
	

	
func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		if is_held:
			velocity = Vector3.ZERO
			rotation.y = lerp_angle(rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
			camera_mount.rotation.y = lerp_angle(camera_mount.rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
			camera_mount.rotation.x = lerp_angle(camera_mount.rotation.x, target_rotation_x, LOOK_SMOOTHING * delta)
			move_and_slide()
			_update_bob(delta)
		return
			
			#velocity = Vector3.ZERO
			#rotation.y = lerp_angle(rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
			#camera_mount.rotation.y = lerp_angle(camera_mount.rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
			#camera_mount.rotation.x = lerp_angle(camera_mount.rotation.x, target_rotation_x, LOOK_SMOOTHING * delta)
			#move_and_slide()
			#_update_bob(delta)
		#if is_held:
			#velocity = Vector3.ZERO
			#rotation.y = lerp_angle(rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
			#print(rotation.y)
			#camera_mount.rotation.y = lerp_angle(camera_mount.rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
			#camera_mount.rotation.x = lerp_angle(camera_mount.rotation.x, target_rotation_x, LOOK_SMOOTHING * delta)
			#_update_bob(delta)


	if climb_reacquire_timer > 0.0:
		climb_reacquire_timer -= delta
	
	if mantle_reacquire_timer > 0.0:
		mantle_reacquire_timer -= delta

	var target_fov = FOV_SPRINT if is_sprinting else (FOV_CLIMB if is_climbing else FOV_DEFAULT)
	camera_main.fov = lerp(camera_main.fov, target_fov, FOV_LERP_SPEED * delta)

	if is_instance_valid(debug_velocity):
		debug_velocity.text = "%.2f" % Vector2(velocity.x, velocity.z).length()

	if is_climbing:
		var target_wall_facing = atan2(climb_wall_normal.x, climb_wall_normal.z) + PI
		rotation.y = lerp_angle(rotation.y, target_wall_facing, 8.0 * delta)
		camera_mount.rotation.y = lerp_angle(camera_mount.rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
		camera_mount.rotation.x = lerp_angle(camera_mount.rotation.x, target_rotation_x, LOOK_SMOOTHING * delta)
	else:
		rotation.y = lerp_angle(rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
		camera_mount.rotation.y = lerp_angle(camera_mount.rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
		camera_mount.rotation.x = lerp_angle(camera_mount.rotation.x, target_rotation_x, LOOK_SMOOTHING * delta)

	# Gravity
	if not is_on_floor() and not is_climbing:
		jump_grace_timer -= delta
		var grav: float
		if velocity.y > GRAVITY_PEAK_THRESHOLD:
			grav = GRAVITY_UP
		elif velocity.y > -GRAVITY_PEAK_THRESHOLD:
			grav = GRAVITY_UP * GRAVITY_PEAK_MULTIPLIER
		else:
			grav = GRAVITY_DOWN
		velocity.y += grav * delta
	else:
		jump_grace_timer = JUMP_GRACE_TIME

	# Landing
	var on_floor_now = is_on_floor()
	if on_floor_now and not was_on_floor:
		landing_dip = -LANDING_DIP_STRENGTH
		jumped_while_sprinting = false
	was_on_floor = on_floor_now

	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	# Jump
	if jump_buffer_timer > 0.0 and jump_grace_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		jumped_while_sprinting = is_sprinting
		if stamina >= STAMINA_JUMP_COST:
			stamina = max(stamina - STAMINA_JUMP_COST, 0.0)
			velocity.x *= JUMP_MOMENTUM_BOOST
			velocity.z *= JUMP_MOMENTUM_BOOST
		else:
			stamina = max(stamina - STAMINA_JUMP_COST, 0.0)
			velocity.x *= STAMINA_MOMENTUM_BOOST_EMPTY
			velocity.z *= STAMINA_MOMENTUM_BOOST_EMPTY
			velocity.x = clamp(velocity.x, -SPEED * 0.1, SPEED * 0.1)
			velocity.z = clamp(velocity.z, -SPEED * 0.1, SPEED * 0.1)
		stamina_regen_timer = STAMINA_REGEN_DELAY
		jump_grace_timer = 0.0
		jump_buffer_timer = 0.0

	# Movement
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(-input.x, 0, -input.y)).normalized()
	var forward = global_basis.z
	var dot = direction.dot(forward)
	is_sprinting = Input.is_action_pressed("sprint") and stamina > 0.0 and is_on_floor() and dot > 0.5
	var current_speed = SPRINT_SPEED if is_sprinting else SPEED

	if is_sprinting:
		stamina = max(stamina - STAMINA_SPRINT_COST * delta, 0.0)
		stamina_regen_timer = STAMINA_REGEN_DELAY
	
	#CAMERA TILT HORIZONTAL
	var horizontal_input = Input.get_axis("move_right", "move_left")
	climb_tilt = lerp(climb_tilt, horizontal_input * CLIMB_TILT_STRENGTH if is_climbing else 0.0, CLIMB_TILT_SPEED * delta)
	camera_mount.rotation.z = climb_tilt
	
	#CAMERA TILT VERTICAL
	var tilt_target: float = CLIMB_CAMERA_TILT_TARGET if is_climbing else 0.0
	if camera_attach_smooth_timer > 0.0:
		climb_camera_tilt_target = lerp(climb_camera_tilt_target, tilt_target, 3.5 * delta)
	else:
		climb_camera_tilt_target = lerp(climb_camera_tilt_target, tilt_target, CLIMB_CAMERA_TILT_SPEED * delta)
	climb_camera_tilt = lerp(climb_camera_tilt, climb_camera_tilt_target, 12.0 * delta)
	var tilt_speed = 8.0 if camera_attach_smooth_timer > 0.0 else CLIMB_CAMERA_TILT_SPEED
	camera_mount.rotation.x = lerp_angle(camera_mount.rotation.x, target_rotation_x + climb_camera_tilt, LOOK_SMOOTHING * delta)

	if is_climbing:
		
		# PREVENTS A BUG WITH A FLOOR AND A WALL CLIPPING CAMERA - DONT TOUCH THAT
		landing_dip = 0
		
		#CLIMB ATTACH
		if is_climb_attaching:
			climb_attach_timer -= delta
			var t = 1.0 - clamp(climb_attach_timer / CLIMB_ATTACH_DURATION, 0.0, 1.0)
			global_position = global_position.lerp(climb_attach_target, t * 0.35)
			velocity = velocity.lerp(Vector3.ZERO, t * 0.5)
			if climb_attach_timer <= 0.0:
				is_climb_attaching = false
		
		#CLIMB ITSELF
		var hit = _maintain_climb()
		var climbing_input = Vector2(Input.get_axis("move_right", "move_left"), Input.get_axis("move_forward", "move_back"))
		current_wall_normal = current_wall_normal.lerp(climb_wall_normal, 8.0 * delta)

		var right_dir = current_wall_normal.cross(Vector3.UP).normalized()
		var up_dir = right_dir.cross(current_wall_normal).normalized()

		if not hit.is_empty():
			var desired_pos = hit.position + current_wall_normal * CLIMB_WALL_OFFSET
			desired_pos.y = global_position.y

		velocity.x = (right_dir.x * climbing_input.x + up_dir.x * -climbing_input.y) * climb_speed
		velocity.y = (right_dir.y * climbing_input.x + up_dir.y * -climbing_input.y) * climb_speed
		velocity.z = (right_dir.z * climbing_input.x + up_dir.z * -climbing_input.y) * climb_speed
		
		velocity.y += climb_attach_boost
		climb_attach_boost = lerp(climb_attach_boost, 0.0, CLIMB_ATTACH_BOOST_DECAY * delta)

		if wall_nudge_timer > 0.0:
			wall_nudge_timer -= delta
			velocity += wall_nudge_dir * WALL_NUDGE_STRENGTH

		if stamina > 0.0:
			stamina = max(stamina - STAMINA_CLIMB_COST * delta, 0.0)
			stamina_regen_timer = STAMINA_REGEN_DELAY
		else:
			_stop_climb()
			velocity.y = -2.0
		
		if not is_climb_attaching and not is_mantling and not is_on_floor():
			if climbing_input.y < -0.3:  # player pushing up
				var mantle = _try_mantle()
				if not mantle.is_empty():
					mantle_target = mantle.position + Vector3.UP * MANTLE_DISTANCE  # half duck height
					is_mantling = true
					mantle_timer = MANTLE_DURATION
					is_climbing = false
					is_climb_attaching = false
					climb_reacquire_timer = MANTLE_DURATION + 0.4  # outlast the mantle
					_stop_climb()

	elif not is_thrown:
		var current_air_accel = SPRINT_AIR_ACCELERATION if jumped_while_sprinting else AIR_ACCELERATION
		var accel = ACCELERATION if is_on_floor() else current_air_accel
		if direction:
			velocity.x = move_toward(velocity.x, direction.x * current_speed, accel * delta)
			velocity.z = move_toward(velocity.z, direction.z * current_speed, accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, accel * delta) if not is_on_floor() else 0
			velocity.z = move_toward(velocity.z, 0, accel * delta) if not is_on_floor() else 0
	
	if is_mantling:
		mantle_timer -= delta
		var t_raw = 1.0 - clamp(mantle_timer / MANTLE_DURATION, 0.0, 1.0)
		var t = t_raw * t_raw
		global_position = global_position.lerp(mantle_target, t * MANTLE_LERP_SPEED)
		velocity = Vector3.ZERO
		if mantle_timer <= 0.0:
			is_mantling = false
			mantle_reacquire_timer = MANTLE_REACQUIRE_COOLDOWN
	
	if is_thrown and is_on_floor():
		is_thrown = false

	_update_bob(delta)
	move_and_slide()

	# THIS IS USED FOR DIVERGENT (OR CLIPPING) WALLS + ANTI WALL CLIPPING CAMERA SCRIPT
	if is_climbing:
		_sliding_into_walls_check()
		_update_camera_clip()
		
	_update_stamina(delta)

	# NEW CLIMBING
	var manifold = _get_wall_manifold()

	if manifold.hit:
		_set_cursor_active()
	else:
		if not is_climbing:
			_set_cursor_base()

	if not Input.is_action_pressed("climb"):
		if is_climbing:
			_stop_climb()
			
	elif not is_climbing and climb_reacquire_timer <= 0.0 and not is_mantling and mantle_reacquire_timer <= 0.0:
		var acquisition = _try_acquire_wall()
		if not acquisition.is_empty():
			climb_wall_normal = acquisition.normal
			_start_climb()

	if is_climbing:
		var manifold_check = _get_wall_manifold()
		if not manifold_check.hit:
			var search_hit = _search_for_wall()
			if not search_hit.is_empty():
				prev_wall_normal = climb_wall_normal
				climb_wall_normal = search_hit.normal
				climb_detach_timer = 0.0
				wall_nudge_timer = WALL_NUDGE_DURATION
				wall_nudge_dir = -search_hit.normal
			else:
				climb_detach_timer += delta
				if climb_detach_timer >= CLIMB_DETACH_GRACE:
					_stop_climb()
		else:
			climb_detach_timer = 0.0
			prev_wall_normal = climb_wall_normal
			climb_wall_normal = manifold_check.normal

	if not Input.is_action_pressed("climb"):
		if is_climbing:
			_stop_climb()

	# THROW
	if Input.is_action_just_pressed("grab") and held_player == null:
		_try_grab()

	if Input.is_action_pressed("climb") and held_player != null:
		throw_charge = min(throw_charge + charge_speed * delta, max_throw_force)

	if Input.is_action_just_released("climb") and held_player != null:
		_throw_player()

	if held_player != null:
		_update_held_player()

func _update_camera_clip() -> void:
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(
		camera_mount.global_position,
		camera_main.global_position
	)
	params.exclude = [self]
	var hit = space.intersect_ray(params)
	if hit and hit.normal.y < 0.629:  # ignore floors
		camera_main.global_position = hit.position + hit.normal * 0.05

func _update_bob(delta: float) -> void:
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	var speed_ratio = clamp(horizontal_speed / SPEED, 0.0, 1.0)
	var bob_offset_y = 0.0
	var bob_offset_x = 0.0
	if horizontal_speed > 0.4 and is_on_floor():
		bob_time += delta * BOB_FREQUENCY * horizontal_speed
		bob_offset_y = sin(bob_time) * BOB_AMPLITUDE_Y * speed_ratio
		bob_offset_x = cos(bob_time * 0.5) * BOB_AMPLITUDE_X * speed_ratio
	
	landing_dip = 0
	
	if camera_attach_smooth_timer > 0.0:
		camera_attach_smooth_timer -= delta

	var target_pos = global_position + Vector3(bob_offset_x, bob_offset_y + landing_dip, 0.0)
	var smooth_speed = CAMERA_ATTACH_SMOOTH_SPEED if camera_attach_smooth_timer > 0.0 else CAMERA_DEFAULT_SMOOTH_SPEED
	camera_smooth_pos = camera_smooth_pos.lerp(target_pos, smooth_speed * delta)
	camera_mount.global_position = camera_smooth_pos
