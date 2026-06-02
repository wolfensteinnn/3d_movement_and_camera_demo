extends CharacterBody3D
@onready var camera_mount: Node3D = $CameraMount
@onready var camera_main: Camera3D = $CameraMount/Camera3D
@onready var meshes: Skeleton3D = $duck/Armature/Skeleton3D
@onready var ledge_cast: RayCast3D = $RayCast3D

var debug_velocity

#UI
var stamina_bar
var cursor

# FOV AND CAMERA STUFF
const FOV_DEFAULT = 70.0
const FOV_SPRINT = 66.0
const FOV_LERP_SPEED = 8.0
const FOV_CLIMB = 70.0
const CLIMB_TILT_STRENGTH = 0.04
const CLIMB_TILT_SPEED = 6.0


#FOR CUSTOM MULTIPLAYER SPAWNING
var is_master: bool
var initial_transform: Vector3

# MOVEMENT AND PHYSICS
var SPEED = 0.8
var ACCELERATION = 10.0


# NEW NEW CLIMBING (WITH PROBES)
const WALL_PROBE_LENGTH = 0.18
const WALL_PROBE_SPREAD = 0.055
const WALL_NORMAL_DIVERGENCE_THRESHOLD = 0.85  # dot product — below this means corner/edge
const WALL_ACQUISITION_LENGTH = 0.15           # more generous for input acquisition
const WALL_ACQUISITION_VERTICAL_SPREAD = 0.08  # vertical tolerance for acquisition
const CLIMB_DETACH_GRACE = 0.4  # seconds of lost contact before detaching
const CLIMB_REACQUIRE_COOLDOWN = 0.12
var climb_detach_timer: float = 0.0
var climb_reacquire_timer: float = 0.0
var wall_nudge_timer: float = 0.0
var wall_nudge_dir: Vector3 = Vector3.ZERO
const WALL_NUDGE_DURATION = 0.15
const WALL_NUDGE_STRENGTH = 0.45
var prev_wall_normal: Vector3 = Vector3.ZERO

# NEW CLIMBING
var climb_wall_normal: Vector3 = Vector3.ZERO
var current_wall_normal: Vector3 = Vector3.ZERO #FOR INTERPOLATION

# CLIMBING
var is_climbing = false
var climb_speed: float = 0.28
var climb_tilt: float = 0.0

#SPRINT
const SPRINT_SPEED = 1.5
const SPRINT_AIR_ACCELERATION = 0.8
const STAMINA_SPRINT_COST = 18.0
var is_sprinting: bool = false
var jumped_while_sprinting: bool = false

# STAMINA
const STAMINA_MAX = 200.0
const STAMINA_MOMENTUM_BOOST_EMPTY = 1.08

const STAMINA_REGEN_RATE = 52.0        # per second
const STAMINA_REGEN_DELAY = 1.4        # seconds after last use before regen starts
const STAMINA_JUMP_COST = 30.0
const STAMINA_CLIMB_COST = 0.5 # weaker boost when out of stamina

var stamina: float = 100.0
var stamina_regen_timer: float = 0.0

# GRAVITY
const GRAVITY_UP = -7.0
const GRAVITY_DOWN = -12.0

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

# CAMERA AND LOOKING
const LOOK_SMOOTHING = 17.0
const MOUSE_SENSITIVITY = 0.002

# CAMERA BOB
const BOB_FREQUENCY = 13.6
const BOB_AMPLITUDE_Y = 0.018
const BOB_AMPLITUDE_X = 0.01
var bob_time: float = 0.0

# LOOK TARGETS
var target_rotation_y: float = 0.0
var target_rotation_x: float = 0.0

##ANIMATIONS
#@onready var animation_tree: AnimationTree = $duck/AnimationTree


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

func _unhandled_input(event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		target_rotation_y -= event.relative.x * MOUSE_SENSITIVITY
		target_rotation_x += event.relative.y * MOUSE_SENSITIVITY
		target_rotation_x = clamp(target_rotation_x, deg_to_rad(-75), deg_to_rad(75))
			
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
		global_position + (-climb_wall_normal * 0.4)
	)
	query.exclude = [self]
	return space_state.intersect_ray(query)

func _start_climb() -> void:
	climb_detach_timer = 0.0 
	current_wall_normal = climb_wall_normal
	_set_cursor_climb()
	is_climbing = true
	#set_collision_mask_value(1, false)
	var hit = _maintain_climb()
	if hit:
		global_position = hit.position + climb_wall_normal * 0.08
	velocity = Vector3.ZERO

func _stop_climb() -> void:
	is_climbing = false
	climb_detach_timer = 0.0
	climb_reacquire_timer = CLIMB_REACQUIRE_COOLDOWN

#FANCY CLIMBING NEW
func _get_wall_manifold() -> Dictionary:
	var space = get_world_3d().direct_space_state
	var forward = -climb_wall_normal if is_climbing else global_basis.z #SO THAT WE CASH THE LAST PROPER NORMAL
	var right = global_basis.x
	var origin = global_position

	var probe_origins = [
	origin,                                    # center
	origin + right * WALL_PROBE_SPREAD,        # right
	origin - right * WALL_PROBE_SPREAD,        # left
	origin + right * WALL_PROBE_SPREAD * 2.0,  # far right
	origin - right * WALL_PROBE_SPREAD * 2.0,  # far left
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

	# collect valid normals and points
	var normals = []
	var points = []
	for h in hits:
		if not h.is_empty():
			normals.append(h.normal)
			points.append(h.position)

	# average normal and point
	var avg_normal = Vector3.ZERO
	var avg_point = Vector3.ZERO
	for n in normals:
		avg_normal += n
	for p in points:
		avg_point += p
	avg_normal = (avg_normal / normals.size()).normalized()
	avg_point = avg_point / points.size()

	# check normal divergence — are probes seeing drastically different surfaces?
	var divergent = false
	if normals.size() > 1:
		for i in range(normals.size() - 1):
			if normals[i].dot(normals[i + 1]) < WALL_NORMAL_DIVERGENCE_THRESHOLD:
				divergent = true
				break

	# reject floor/ceiling — only climbable if normal is mostly horizontal
	if avg_normal.y > 0.45 or avg_normal.y < -0.45:
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

#SEARCHING FOR THE WALL DURING ANGLE ROUNDING
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
		if not hit.is_empty() and hit.normal.y < 0.45 and hit.normal.y > -0.45:
			# score by how different from previous normal — new surfaces score higher
			var diff = 1.0 - prev_wall_normal.dot(hit.normal)
			if diff > best_score:
				best_score = diff
				best_hit = hit
	
	return best_hit

func _try_acquire_wall() -> Dictionary:
	var space = get_world_3d().direct_space_state
	var forward = global_basis.z
	var origin = global_position

	# three vertically spread rays — center, slightly up, slightly down
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
		if not hit.is_empty() and hit.normal.y < 0.45 and hit.normal.y > -0.45:
			return hit  # first valid hit wins

	return {}

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
	
	
	if climb_reacquire_timer > 0.0:
		climb_reacquire_timer -= delta
	

	var target_fov = FOV_SPRINT if is_sprinting else (FOV_CLIMB if is_climbing else FOV_DEFAULT)
	camera_main.fov = lerp(camera_main.fov, target_fov, FOV_LERP_SPEED * delta)
	
	if is_instance_valid(debug_velocity):
		debug_velocity.text = "%.2f" % Vector2(velocity.x, velocity.z).length()

	# WE ARE NOT ROTATING OUR MODEL WHEN WE ARE CLIMBING
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

	# Jump buffer countdown
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
			velocity.x = clamp(velocity.x, -SPEED * 0.1, SPEED * 0.1) #PUNISH NO STAMINA JUMPS WITH A 0.1 SPEED MULTIPLIER
			velocity.z = clamp(velocity.z, -SPEED * 0.1, SPEED * 0.1)
		stamina_regen_timer = STAMINA_REGEN_DELAY
		jump_grace_timer = 0.0
		jump_buffer_timer = 0.0

	# Movement
	
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(-input.x, 0, -input.y)).normalized()
	var forward = global_basis.z
	var dot = direction.dot(forward) #THIS IS THE DOT PRODUCT WHIHC BASICALLY TELLS US HOW FORWARD DO WE LOOK (CAN WE SPRINT LIKE THAT)
	is_sprinting = Input.is_action_pressed("sprint") and stamina > 0.0 and is_on_floor() and dot > 0.5
	var current_speed = SPRINT_SPEED if is_sprinting else SPEED

	if is_sprinting:
		stamina = max(stamina - STAMINA_SPRINT_COST * delta, 0.0)
		stamina_regen_timer = STAMINA_REGEN_DELAY
	
	# CAMERA MOUNT TILT (ON CLIMBING)
	var horizontal_input = Input.get_axis("move_right", "move_left")
	climb_tilt = lerp(climb_tilt, horizontal_input * CLIMB_TILT_STRENGTH if is_climbing else 0.0, CLIMB_TILT_SPEED * delta)
	camera_mount.rotation.z = climb_tilt


	if is_climbing:
		var hit = _maintain_climb()
		var climbing_input = Vector2(Input.get_axis("move_right", "move_left"), Input.get_axis("move_forward", "move_back"))
		current_wall_normal = current_wall_normal.lerp(climb_wall_normal, 8.0 * delta)

		var right_dir = current_wall_normal.cross(Vector3.UP).normalized()
		var up_dir = right_dir.cross(current_wall_normal).normalized()
		
		if not hit.is_empty():
			var desired_pos = hit.position + current_wall_normal * 0.08
			desired_pos.y = global_position.y

		velocity.x = (right_dir.x * climbing_input.x + up_dir.x * -climbing_input.y) * climb_speed
		velocity.y = (right_dir.y * climbing_input.x + up_dir.y * -climbing_input.y) * climb_speed
		velocity.z = (right_dir.z * climbing_input.x + up_dir.z * -climbing_input.y) * climb_speed
		
		if wall_nudge_timer > 0.0:
			wall_nudge_timer -= delta
			velocity += wall_nudge_dir * WALL_NUDGE_STRENGTH

		if stamina > 0.0:
			stamina = max(stamina - STAMINA_CLIMB_COST * delta, 0.0)
			stamina_regen_timer = STAMINA_REGEN_DELAY
		else:
			_stop_climb()
			velocity.y = -2.0

	else:
		var current_air_accel = SPRINT_AIR_ACCELERATION if jumped_while_sprinting else AIR_ACCELERATION
		var accel = ACCELERATION if is_on_floor() else current_air_accel
		if direction:
			velocity.x = move_toward(velocity.x, direction.x * current_speed, accel * delta)
			velocity.z = move_toward(velocity.z, direction.z * current_speed, accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, accel * delta) if not is_on_floor() else 0
			velocity.z = move_toward(velocity.z, 0, accel * delta) if not is_on_floor() else 0
	
	
	_update_bob(delta)
	move_and_slide()
	_update_stamina(delta)
	
	#NEW CLIMBING
	var manifold = _get_wall_manifold()

	if manifold.hit:
		_set_cursor_active()
	else:
		if not is_climbing:
			_set_cursor_base()

	if not Input.is_action_pressed("climb"):
		if is_climbing:
			_stop_climb()
	elif not is_climbing and climb_reacquire_timer <= 0.0:
		var acquisition = _try_acquire_wall()
		if not acquisition.is_empty():
			climb_wall_normal = acquisition.normal
			_start_climb()

	if is_climbing:
		var manifold_check = _get_wall_manifold()
		if not manifold_check.hit:
			# actively search for adjacent surface during grace
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
	
	
func _update_bob(delta: float) -> void:
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	var speed_ratio = clamp(horizontal_speed / SPEED, 0.0, 1.0)
	var bob_offset_y = 0.0
	var bob_offset_x = 0.0
	if horizontal_speed > 0.1 and is_on_floor():
		bob_time += delta * BOB_FREQUENCY * horizontal_speed
		bob_offset_y = sin(bob_time) * BOB_AMPLITUDE_Y * speed_ratio
		bob_offset_x = cos(bob_time * 0.5) * BOB_AMPLITUDE_X * speed_ratio

	landing_dip = lerp(landing_dip, 0.0, LANDING_DIP_SPEED * delta)
	camera_mount.global_position = global_position + Vector3(bob_offset_x, bob_offset_y + landing_dip, 0.0)
