extends CharacterBody3D
@onready var camera_mount: Node3D = $CameraMount
@onready var camera_main: Camera3D = $CameraMount/Camera3D
@onready var meshes: Skeleton3D = $duck/Armature/Skeleton3D
@onready var grab_cast: RayCast3D = $CameraMount/GrabCast
@onready var hit_detector: Area3D = $HitDetector
@onready var hold_point: Node3D = $CameraMount/HoldPoint


var debug_velocity
var test_projectile: RigidBody3D = null

#UI
var stamina_bar
var cursor

# CAMERA GENERAL
const CAMERA_ATTACH_SMOOTH_SPEED = 10.6
const CAMERA_DEFAULT_SMOOTH_SPEED = 16.0
var camera_smooth_pos: Vector3 = Vector3.ZERO
const LOOK_SMOOTHING = 17.0
const MOUSE_SENSITIVITY = 0.002
const EYE_HEIGHT = 0.111
const EYE_HEIGHT_LANDING_DIP = 0.009
var eye_height_current: float = 0.111


# CAMERA BOB
const BOB_FREQUENCY = 20.6
const BOB_AMPLITUDE_Y = 0.018
const BOB_AMPLITUDE_X = 0.01
var bob_time: float = 0.0
var idle_bob_time: float = 0.0
const IDLE_BOB_FREQUENCY = 0.3
const IDLE_BOB_RADIUS = 0.052
var idle_bob_blend: float = 0.0
var idle_check:bool = false
var idle_timer = 0.0

# FOV AND CAMERA STUFF
const FOV_DEFAULT = 68.0
const FOV_SPRINT = 63.0
const FOV_LERP_SPEED = 2.8
const FOV_CLIMB = 80.0
const CLIMB_TILT_STRENGTH = 0.04
const CLIMB_TILT_SPEED = 6.0

const CLIMB_CAMERA_TILT_UP = -0.08
const CLIMB_CAMERA_TILT_SPEED = 2.5
const CLIMB_CAMERA_TILT_ROT = 2.6
var climb_camera_tilt: float = 0.0
const CLIMB_CAMERA_TILT_TARGET: float = -0.12
const CLIMB_CAMERA_TILT_OVERSHOOT: float = -0.28
var climb_camera_tilt_target: float = 0.0

const MANTLE_CAMERA_TILT = 0.14
var mantle_camera_tilt: float = 0.0
var mantle_camera_tilt_target: float = -0.05 #FOR SLIGHT OVERSHOOT

#FOR CUSTOM MULTIPLAYER SPAWNING
var is_master: bool
var initial_transform: Vector3

# MOVEMENT AND PHYSICS
const SPEED = 0.36
var speed_target: float = 0.48
var horizontal_speed: float = 0.0 #USED FOR THE ANIMATIONS AND BOBS (PURELY AS A READ VALUE)
const ACCELERATION = 18.0
const DECELERATION = 28.0
var accel: float = 6.0
var decel: float = 28.0
var move_input_smooth: Vector2 = Vector2.ZERO  # add with other vars

# CROUCH
const CROUCH_EYE_HEIGHT = 0.04
const CROUCH_CAMERA_TILT = 0.06
const CROUCH_CAMERA_TILT_SPEED = 8.0
var is_crouching: bool = false
var crouch_tilt: float = 0.0
var crouch_tilt_velocity: float = 0.0

#SPRINT
const SPRINT_SPEED = 0.48
const STAMINA_SPRINT_COST = 18.0
var is_sprinting: bool = false
var jumped_while_sprinting: bool = false
var just_jumped: bool = false

# MANTLING
var is_mantling: bool = false
var mantle_timer: float = 0.0
const MANTLE_DURATION = 0.64        # total time of the mantle
const MANTLE_LERP_SPEED = 0.16      # lower = floatier, higher = snappier
var mantle_target: Vector3 = Vector3.ZERO
const MANTLE_DISTANCE = 0.075 #around 45% of the duck
var mantle_reacquire_timer: float = 0.0
const MANTLE_REACQUIRE_COOLDOWN = 0.48


# CLIMB INIT
var is_climb_attaching: bool = false
var climb_attach_timer: float = 0.0
const CLIMB_ATTACH_DURATION = 0.15
var climb_attach_target: Vector3 = Vector3.ZERO
# CLIMB BOOST
var climb_attach_boost: float = 0.0
const CLIMB_ATTACH_BOOST_STRENGTH = 0.48
const CLIMB_ATTACH_BOOST_DECAY = 8.8
# CLIMB CAMERA DIP
var camera_attach_smooth_timer: float = 0.0
const CAMERA_ATTACH_SMOOTH_DURATION = 0.72


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
var climb_speed: float = 0.22
var climb_tilt: float = 0.0

# STAMINA
const STAMINA_MAX = 100.0
const STAMINA_MOMENTUM_BOOST_EMPTY = 0.2
const STAMINA_REGEN_RATE = 52.0
const STAMINA_REGEN_DELAY = 1.4
const STAMINA_JUMP_COST = 30.0
const STAMINA_CLIMB_COST = 12.0

var stamina: float = 100.0
var stamina_regen_timer: float = 0.0

# GRAVITY
const GRAVITY_UP = -2.4
const GRAVITY_DOWN = -3.6
const GRAVITY_PEAK_THRESHOLD = 1.2
const TERMINAL_VELOCITY = -9.4

#Falling
var fall_start_y: float = 0.0
var is_falling: bool = false
var fall_distance: float = 0.0

#AIR
const AIR_ACCELERATION = 3.2
const SPRINT_AIR_ACCELERATION = 4.8
const AIR_FRICTION = 0.4

#JUMP
const JUMP_VELOCITY = 0.76
const JUMP_GRACE_TIME = 0.07
const JUMP_BUFFER_TIME = 0.12
var jump_grace_timer: float = 0.0
var jump_buffer_timer: float = 0.0
const JUMP_MOMENTUM_BOOST = 1.16
const JUMP_MOMENTUM_BOOST_SPRINT = 1.48
var momentum_boost: float = 1.0

# LANDING DIP
var landing_dip_rotation: float = 0.0
const LANDING_DIP_ROT_STRENGTH = 0.3
const LANDING_DIP_ROT_SPEED = 5.2
var landing_fov_dip: float = 0.0
const LANDING_FOV_DIP_STRENGTH = 4.5  
const LANDING_FOV_DIP_SPEED = 7.0

# THROWING
var held_player: CharacterBody3D = null
var is_held: bool = false
var holder_authority: int = -1
@export var grab_range: float = 0.2
var throw_charge: float = 0.0
var hold_target_position: Vector3 = Vector3.ZERO
var max_throw_force: float = 100.00
var charge_speed: float = 5.0
var held_player_original_authority: int = -1

# LOOK TARGETS
var target_rotation_y: float = 0.0
var target_rotation_x: float = 0.0

# RAGDOLL
const RAGDOLL_FALL_THRESHOLD = 1.8
const RAGDOLL_MIN_DURATION = 1.8
const RAGDOLL_SETTLE_SPEED = 0.08
const RAGDOLL_RECOVERY_TIME = 0.68
const RAGDOLL_SMOOTHING_TIMER = 0.58

var ragdoll_smoothing_timer: float = -1.0
var is_ragdoll: bool = false
var ragdoll_timer: float = 0.0
var ragdoll_recovery_timer: float = 0.0
var pre_impact_velocity: Vector3 = Vector3.ZERO

# RAGDOLL DIP ANIMATION
var ragdoll_landing_dip_rotation: float = 0.0
var ragdoll_landing_fov_dip: float = 0.0
var ragdoll_eye_dip: float = 0.0

# RAGDOLL ANIMATION RECOVERY  
const RECOVERY_FOV_DIP = 20           
const RECOVERY_EYE_HEIGHT_SPEED = 0.8
const RECOVERY_FOV_SPEED = 1.4          # max speed at end of ease
const RECOVERY_DURATION = 0.58           # input-blocked phase
const RECOVERY_LINGER_DURATION = 2.4     # free phase, animation tail
const RECOVERY_LOOK_DIP_TIMING = 0.12

var recovery_fov_dip: float = 0.0
var recovery_look_dip_timer: float = -1.0
var is_recovering: bool = false
var recovery_timer: float = 0.0
var recovery_tilt_x: float = 0.0
var recovery_tilt_z: float = 0.0
var recovery_linger: bool = false
var recovery_linger_timer: float = 0.0

#MOVING OBJECTS
var held_object: InteractableObject = null

@onready var collision_normal: CollisionShape3D = $CollisionShape3D
@onready var collision_crouch: CollisionShape3D = $CollisionShapeCrouch

@onready var collision_ragdoll: RigidBody3D = $Ragdoll

# ANIMATIONS
@onready var anim_tree: AnimationTree = $duck/AnimationTree

#DEBUG
var prev_pos: Vector3

# HANDBONES
@onready var hand_r: Node3D = $duck/Hand_r
@onready var hand_l: Node3D = $duck/Hand_l

#BONES MODIFIERS
@onready var modifier_rotation: DMWBWiggleRotationModifier3D = $duck/Armature/Skeleton3D/modifier_base_head_rotation
@onready var modifier_eyes_y: BoneRotationModifier3D = $duck/Armature/Skeleton3D/modifier_eyes_y


# IDLE TURN & EYE LOOK
const IDLE_TURN_THRESHOLD = deg_to_rad(80.0) # radians — body turns beyond this, eyes track within it
const IDLE_TURN_SPEED = 2.4 
var body_target_rotation_y: float = 0.0
var look_lerp_speed: float = 7.2
var current_eye_y: float = 0.0
var idle_is_turning:bool = false
var current_head_tilt: float = 0.0

func _update_head_tilt(delta: float) -> void:
	var dead_zone = deg_to_rad(45.0)
	var abs_raw = absf(target_rotation_x)
	var target_tilt = 0.0
	if abs_raw > dead_zone:
		target_tilt = clampf((abs_raw - dead_zone) * sign(target_rotation_x), -deg_to_rad(25.0), deg_to_rad(25.0))
	current_head_tilt = lerp(current_head_tilt, target_tilt, 18.0 * delta)
	modifier_rotation.force_local.z = rad_to_deg(current_head_tilt)

func _update_body_rotation(delta: float) -> void:
	var is_idle = horizontal_speed < 0.1
	if is_idle:
		var relative = angle_difference(body_target_rotation_y, target_rotation_y)
		if absf(relative) > IDLE_TURN_THRESHOLD:
			idle_is_turning = true
		if idle_is_turning:
			body_target_rotation_y = lerp_angle(body_target_rotation_y, target_rotation_y, IDLE_TURN_SPEED * delta)
			if absf(angle_difference(body_target_rotation_y, target_rotation_y)) < 0.01:
				idle_is_turning = false
	else:
		idle_is_turning = false
		body_target_rotation_y = target_rotation_y

func _update_eye_look(delta: float) -> void:
	var relative = angle_difference(body_target_rotation_y, target_rotation_y)
	var target_y = clampf(relative, -IDLE_TURN_THRESHOLD, IDLE_TURN_THRESHOLD)
	target_y = clampf(target_y, -deg_to_rad(38.0), deg_to_rad(38.0))
	current_eye_y = lerp(current_eye_y, target_y, look_lerp_speed * delta)
	modifier_eyes_y.bone_rotation_degrees = Vector3(0.0, rad_to_deg(current_eye_y), 0.0)

func _anim_to_idle():
	anim_tree.set("parameters/conditions/run",false)
	anim_tree.set("parameters/conditions/idle",true)

func _anim_to_run():
	anim_tree.set("parameters/conditions/idle",false)
	anim_tree.set("parameters/conditions/run",true)

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

func _enable_crouch_col():
	collision_crouch.set_deferred("disabled",false)
	collision_normal.set_deferred("disabled",true)

func _enable_normal_col():
	collision_crouch.set_deferred("disabled",true)
	collision_normal.set_deferred("disabled",false)

func _can_uncrouch() -> bool:
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + Vector3.UP * (EYE_HEIGHT - CROUCH_EYE_HEIGHT + 0.05)
	)
	params.exclude = [self]
	return space.intersect_ray(params).is_empty()

func _ready() -> void:
	camera_smooth_pos = global_position
	velocity = Vector3.ZERO
	if is_multiplayer_authority():
		#animation_player.play("run")
		hit_detector.body_entered.connect(_on_hit)
		global_position = initial_transform
		camera_main.current = true
		camera_main.set_cull_mask_value(2, false)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		for any in meshes.get_children():
			if any is not MeshInstance3D:
				continue
			#if any.name == "Legs" or any.name == "Legs_001":
				#continue
			any.set_layer_mask_value(1, false)
			any.set_layer_mask_value(2, true)
		
		hand_r.position = Vector3(0.02,0.0,0)
		hand_l.position = Vector3(-0.02,0.0,0)
		
		target_rotation_y = rotation.y
		body_target_rotation_y = rotation.y
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
			if not is_ragdoll and ragdoll_recovery_timer <= 0 and not is_recovering:
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
		if event.keycode == KEY_R:
			global_position = Vector3(2,5,2)
		if event.keycode == KEY_T:
			_launch_test_projectile()
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

func _launch_test_projectile():
	if test_projectile == null:
		test_projectile = get_tree().get_first_node_in_group("test_projectile")
	if test_projectile == null:
		return
	var spawn = global_position + Vector3(5.0, 0.15, 0.0)
	var target = global_position
	target.y = spawn.y
	var direction = (target - spawn).normalized()
	test_projectile.global_position = spawn
	test_projectile.linear_velocity = direction * 8.0

func _start_ragdoll(impulse: Vector3 = Vector3.ZERO) -> void:
	landing_dip_rotation = 0
	
	var impact_speed = abs(pre_impact_velocity.y)
	var dip_strength = 1.6
	ragdoll_landing_dip_rotation = LANDING_DIP_ROT_STRENGTH * dip_strength
	ragdoll_landing_fov_dip = LANDING_FOV_DIP_STRENGTH * dip_strength
	ragdoll_eye_dip = 0.7
	
	is_ragdoll = true
	ragdoll_timer = 0.0
	ragdoll_recovery_timer = -1.0
	collision_normal.set_deferred("disabled",true)
	collision_ragdoll.top_level = true
	collision_ragdoll.global_position = global_position
	collision_ragdoll.freeze = false
	
	if impulse != Vector3.ZERO:
		collision_ragdoll.linear_velocity = impulse.limit_length(6.0)
	else:
		collision_ragdoll.linear_velocity = pre_impact_velocity.limit_length(6.0)
	just_jumped = false
	jumped_while_sprinting = false
	is_falling = false
	is_climbing = false
	is_mantling = false
	is_climb_attaching = false
	climb_reacquire_timer = RAGDOLL_MIN_DURATION + RAGDOLL_RECOVERY_TIME + 0.2

func _stop_ragdoll() -> void:
	is_falling = false
	fall_distance = 0.0
	climb_tilt = 0.0
	climb_camera_tilt = 0.0
	climb_camera_tilt_target = 0.0
	mantle_camera_tilt = 0.0
	mantle_camera_tilt_target = -0.05
	
	recovery_look_dip_timer = RECOVERY_LOOK_DIP_TIMING
	
	
	var recovery_pos = collision_ragdoll.global_position 
	
	is_ragdoll = false
	collision_ragdoll.linear_velocity = Vector3.ZERO
	collision_ragdoll.angular_velocity = Vector3.ZERO
	collision_ragdoll.freeze = true
	collision_ragdoll.top_level = false
	collision_normal.set_deferred("disabled",false)
	velocity = Vector3.ZERO
	global_position = recovery_pos
	eye_height_current = 0.02
	prev_pos = recovery_pos
	
	target_rotation_x = camera_mount.rotation.x
	landing_dip_rotation = 0.0
	landing_fov_dip = 0.0
	recovery_fov_dip = RECOVERY_FOV_DIP
	recovery_timer = RECOVERY_DURATION
	ragdoll_timer = 0.0
	ragdoll_recovery_timer = -1.0
	ragdoll_smoothing_timer = RAGDOLL_SMOOTHING_TIMER 
	
	recovery_tilt_x = camera_mount.rotation.x
	recovery_tilt_z = camera_mount.rotation.z
	
	var ragdoll_yaw = collision_ragdoll.global_transform.basis.get_euler().y
	target_rotation_y = ragdoll_yaw
	rotation = Vector3(0.0, ragdoll_yaw, 0.0)
	
	is_recovering = true

func _on_hit(body: Node3D):
	if not is_multiplayer_authority():
		return
	if is_ragdoll or body==self or is_falling:
		return
	var hit_velocity := Vector3.ZERO
	if body is RigidBody3D:
		hit_velocity = body.linear_velocity
	elif body is CharacterBody3D:
		hit_velocity = body.velocity
	elif body.get_parent() is RigidBody3D:
		hit_velocity = body.get_parent().linear_velocity
	if hit_velocity.length() < 2.0:
		return
	_start_ragdoll(hit_velocity)


func _start_climb() -> void:
	camera_smooth_pos = global_position  # NEEDED FOR A SNAP TO BE MORE SNAPPY 
	is_falling = false
	fall_distance = 0.0
	climb_camera_tilt = 0.16   # push down first
	climb_camera_tilt_target = CLIMB_CAMERA_TILT_OVERSHOOT  # target is up
	camera_attach_smooth_timer = CAMERA_ATTACH_SMOOTH_DURATION
	climb_attach_boost = CLIMB_ATTACH_BOOST_STRENGTH
	climb_detach_timer = 0.0
	current_wall_normal = climb_wall_normal
	_set_cursor_climb()
	is_climbing = true
	is_climb_attaching = true
	climb_attach_timer = CLIMB_ATTACH_DURATION
	var hit = _maintain_climb()
	if hit:
		climb_attach_target = hit.position + climb_wall_normal * CLIMB_WALL_OFFSET
		climb_attach_target.y = global_position.y + 0.16  # preserve vertical position + slight nudge upwards
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

@rpc("any_peer", "reliable")
func force_release_held() -> void:
	held_player = null
	throw_charge = 0.0

func _try_grab() -> void:
	grab_cast.force_raycast_update()

	if grab_cast.is_colliding():
		var hold_target = grab_cast.get_collider()
		if hold_target is CharacterBody3D and hold_target != self:
			if hold_target.is_held:
				rpc_id(hold_target.holder_authority, "force_release_held")
			held_player = hold_target
			held_player_original_authority = hold_target.name.to_int()
			held_player.rpc("set_held", true, get_multiplayer_authority())

@rpc("any_peer", "reliable")
func set_held(held: bool, holder_id: int) -> void:
	is_held = held
	holder_authority = holder_id
	if not held:
		holder_authority = -1

func _update_held_player() -> void:
	if held_player == null:
		return
	if not is_multiplayer_authority():
		return
	var hold_position = global_position + (global_basis.z * 0.1)
	hold_position.y = global_position.y + 0.2
	held_player.rpc_id(held_player.name.to_int(), "receive_hold_position", hold_position)
	#held_player.rpc("_move_camera_on_held",held_player_original_authority)

@rpc("any_peer", "unreliable")
func receive_hold_position(pos: Vector3):
	if is_held and is_multiplayer_authority():
		hold_target_position = pos
		velocity = Vector3.ZERO

func _throw_player() -> void:
	if held_player == null:
		return
	var throw_direction = -camera_main.global_transform.basis.z.normalized()
	var throw_velocity = throw_direction * throw_charge
	throw_velocity.y = throw_charge * 0.5
	held_player.rpc("set_held", false, -1)
	held_player.rpc_id(held_player.name.to_int(), "receive_throw", throw_velocity)
	throw_charge = 0.0
	held_player = null

@rpc("any_peer", "reliable")
func receive_throw(throw_velocity: Vector3) -> void:
	if is_multiplayer_authority():
		velocity = throw_velocity

func _update_throw(delta):
		
	if Input.is_action_just_pressed("grab") and held_player == null:
		_try_grab()

	if Input.is_action_pressed("climb") and held_player != null:
		throw_charge = min(throw_charge + charge_speed * delta, max_throw_force)

	if Input.is_action_just_released("climb") and held_player != null:
		_throw_player()

	if held_player != null:
		_update_held_player()

func _try_pickup_object():
	grab_cast.force_raycast_update()
	if grab_cast.is_colliding():
		var target = grab_cast.get_collider()
		if target is InteractableObject and not target.is_held:
			held_object = target
			held_object._do_grab(get_multiplayer_authority(), get_path())
			held_object.rpc("request_grab", get_multiplayer_authority(), get_path())

func _update_object_pickup(delta: float):
	if Input.is_action_just_pressed("grab") and held_object == null:
		_try_pickup_object()
	if Input.is_action_just_released("grab") and held_object != null:
		held_object._do_release()
		held_object.rpc("request_release")
		held_object = null

	
func _handle_falling(delta: float):
	if not is_on_floor() and not is_climbing and not is_mantling:
		if not is_falling:
			is_falling = true
			fall_start_y = global_position.y
	else:
		if is_falling:
			pre_impact_velocity = velocity
			fall_distance = fall_start_y - global_position.y
			if fall_distance > RAGDOLL_FALL_THRESHOLD:
				_start_ragdoll()
				return
		
			var dip_strength = clamp(fall_distance / 1.5, 0.1, 4.8) #from 30% to 180% roughly
			landing_dip_rotation = LANDING_DIP_ROT_STRENGTH * dip_strength
			landing_fov_dip = LANDING_FOV_DIP_STRENGTH * dip_strength
			eye_height_current -= EYE_HEIGHT_LANDING_DIP * dip_strength
			is_falling = false
			fall_distance = 0.0
			just_jumped = false
			jumped_while_sprinting = false
	
	if climb_reacquire_timer > 0.0:
		climb_reacquire_timer -= delta
	
	if mantle_reacquire_timer > 0.0:
		mantle_reacquire_timer -= delta


func _count_idle_time(delta:float):
	horizontal_speed = Vector2(velocity.x, velocity.z).length()
	if horizontal_speed < 0.1:
		if !idle_check:
			idle_check = true
		idle_timer += delta
	else:
		if idle_check:
			idle_check = false
		idle_timer = 0

func _update_anim_properties():
	var local_velocity = global_transform.basis.inverse() * velocity
	var flat_velocity = Vector2(local_velocity.x, local_velocity.z)
	var speed = flat_velocity.length()
	
	anim_tree.set("parameters/conditions/run", speed > 0.1 and !is_sprinting)
	anim_tree.set("parameters/conditions/idle", speed <= 0.1)
	anim_tree.set("parameters/conditions/sprint", is_sprinting)
	
	anim_tree.set("parameters/conditions/sprintjump", jumped_while_sprinting)
	
	anim_tree.set("parameters/conditions/ragdoll",is_ragdoll)
	anim_tree.set("parameters/conditions/recovery",!is_ragdoll)
	
	var state = _get_direction_state()
	var all_states = ["runforward", "runback", "runleft", "runright"]
	for s in all_states:
		anim_tree.set("parameters/run/conditions/" + s, s == str(state))
	
	anim_tree.set("parameters/conditions/jump_run", just_jumped and !jumped_while_sprinting)
	anim_tree.set("parameters/run/conditions/jumped", just_jumped)
	
	anim_tree.set("parameters/conditions/crouch", is_crouching)
	anim_tree.set("parameters/conditions/uncrouch", !is_crouching)
	
	var state_crouch = _get_direction_state()
	var all_states_crouch = ["crouchforward", "crouchback", "crouchleft", "crouchright"]
	for c in all_states_crouch:
		anim_tree.set("parameters/crouch/conditions/" + c, c == str(state_crouch))
	
	anim_tree.set("parameters/conditions/fell",!is_falling)
	
	
func _get_direction_state() -> String:
	var local_velocity = global_transform.basis.inverse() * velocity
	var flat = Vector2(local_velocity.x, local_velocity.z)
	if abs(flat.y) > abs(flat.x):
		return "runforward" if flat.y > 0 else "runback"
	else:
		return "runright" if flat.x > 0 else "runleft"
	
func _get_direction_state_crouch() -> String:
	var local_velocity = global_transform.basis.inverse() * velocity
	var flat = Vector2(local_velocity.x, local_velocity.z)
	if abs(flat.y) > abs(flat.x):
		return "crouchforward" if flat.y > 0 else "crouchback"
	else:
		return "crouchright" if flat.x > 0 else "crouchleft"

func _physics_process(delta: float) -> void:
	_update_head_tilt(delta)
	_update_eye_look(delta)
	_update_anim_properties()
	
	if !is_multiplayer_authority():
		return
	
	_update_body_rotation(delta)
	_update_object_pickup(delta)
	
	debug_velocity.text = (str(velocity.length()))
	
	if is_held:
		velocity = Vector3.ZERO
		rotation.y = lerp_angle(rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
		global_position = global_position.lerp(hold_target_position, 8.0 * delta)
		_handle_camera_mount_rotation(delta)
		_update_bob(delta)
		if held_player != null:
			_update_held_player()
			_update_throw(delta)
		return
	
	
	
	#RAGDOLL
	if is_ragdoll:
		ragdoll_timer += delta
		var spd = collision_ragdoll.linear_velocity
		global_position = collision_ragdoll.global_position
		rotation = collision_ragdoll.rotation
		_update_camera_ragdoll(delta)
		if is_ragdoll:
			print("RAGDOLL | eye_dip: ", snappedf(ragdoll_eye_dip, 0.001),
				  " | cam_y: ", snappedf(camera_mount.global_position.y, 0.001),
				  " | smooth_y: ", snappedf(camera_smooth_pos.y, 0.001),
				  " | rag_pos_y: ", snappedf(collision_ragdoll.global_position.y, 0.001))


		if ragdoll_timer >= RAGDOLL_MIN_DURATION:
			if Vector2(spd.x, spd.z).length() < RAGDOLL_SETTLE_SPEED and abs(spd.y) < RAGDOLL_SETTLE_SPEED:
				if ragdoll_recovery_timer < 0.0:
					ragdoll_recovery_timer = RAGDOLL_RECOVERY_TIME
			if ragdoll_recovery_timer > 0.0:
				ragdoll_recovery_timer -= delta
				if ragdoll_recovery_timer <= 0.0:
					_stop_ragdoll()
		return
	
	_count_idle_time(delta)
	
	#FALLING
	_handle_falling(delta)
	

	if ragdoll_smoothing_timer > 0.0:
		ragdoll_smoothing_timer -= delta
	
	
	var target_fov = (FOV_SPRINT if is_sprinting else (FOV_CLIMB if is_climbing else FOV_DEFAULT)) - landing_fov_dip - recovery_fov_dip
	landing_fov_dip = lerp(landing_fov_dip, 0.0, LANDING_FOV_DIP_SPEED * delta)
	camera_main.fov = lerp(camera_main.fov, target_fov, FOV_LERP_SPEED * delta)

	
	var ease_t = _get_recovery_ease_t()

	if recovery_look_dip_timer > 0.0:
		recovery_look_dip_timer -= delta
		if recovery_look_dip_timer <= 0.0:
			recovery_tilt_x += 0.6

	if is_recovering:
		
		recovery_timer -= delta
		recovery_fov_dip = lerp(recovery_fov_dip, 0.0, RECOVERY_FOV_SPEED * ease_t * delta)
		target_rotation_x = camera_mount.rotation.x - recovery_tilt_x
		#camera_mount.rotation.z = recovery_tilt_z
		#camera_mount.rotation.y = lerp_angle(camera_mount.rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
		#rotation.y = lerp_angle(rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
		#camera_mount.rotation.x = lerp_angle(camera_mount.rotation.x, recovery_tilt_x, LOOK_SMOOTHING * delta)
		
		if recovery_timer <= 0.0:
			is_recovering = false
			recovery_linger = true
			recovery_linger_timer = RECOVERY_LINGER_DURATION
			target_rotation_x = camera_mount.rotation.x - recovery_tilt_x

	if recovery_linger:
		
		recovery_linger_timer -= delta
		recovery_fov_dip = lerp(recovery_fov_dip, 0.0, RECOVERY_FOV_SPEED * ease_t * delta)
		if recovery_linger_timer <= 0.0:
			recovery_linger = false
	
	
	_handle_camera_mount_rotation(delta)

	if is_recovering or recovery_linger:
		print("RECOVERY | eye_h: ", snappedf(eye_height_current, 0.001),
			  " | cam_y: ", snappedf(camera_mount.global_position.y, 0.001),
			  " | target_y: ", snappedf(global_position.y + eye_height_current, 0.001),
			  " | smooth_y: ", snappedf(camera_smooth_pos.y, 0.001),
			  " | recovering: ", is_recovering,
			  " | linger: ", recovery_linger,
			  " | linger_t: ", snappedf(recovery_linger_timer, 0.01))

	# Gravity
	if not is_on_floor() and not is_climbing:
		jump_grace_timer -= delta
		
		var fall_t = clamp(inverse_lerp(1.0, -2.6, velocity.y), 0.0, 1.0)
		fall_t = fall_t * fall_t  # ease-in for hang time at apex
		var grav = lerp(GRAVITY_UP, GRAVITY_DOWN, fall_t)
		velocity.y += grav * delta
		velocity.y = max(velocity.y, TERMINAL_VELOCITY)
	else:
		jump_grace_timer = JUMP_GRACE_TIME


	## Landing
	#var on_floor_now = is_on_floor()
	#if on_floor_now and not was_on_floor:
		#landing_dip = -LANDING_DIP_STRENGTH
		#landing_dip_rotation = LANDING_DIP_ROT_STRENGTH
		#jumped_while_sprinting = false
	#was_on_floor = on_floor_now

	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	# Jump
	if jump_buffer_timer > 0.0 and jump_grace_timer > 0.0:
		just_jumped = true
		jumped_while_sprinting = is_sprinting
		velocity.y = JUMP_VELOCITY
		if stamina >= JUMP_MOMENTUM_BOOST * 0.5:
			if jumped_while_sprinting:
				momentum_boost = JUMP_MOMENTUM_BOOST_SPRINT
			else:
				momentum_boost = JUMP_MOMENTUM_BOOST
		else:
			momentum_boost = STAMINA_MOMENTUM_BOOST_EMPTY
		stamina = max(stamina - STAMINA_JUMP_COST, 0.0)
		stamina_regen_timer = STAMINA_REGEN_DELAY
		jump_grace_timer = 0.0
		jump_buffer_timer = 0.0

	# Movement
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var input_lerp_speed = lerp(18.0, 12.0, input.length())
	move_input_smooth = move_input_smooth.lerp(input, input_lerp_speed * delta)
	var direction = (transform.basis * Vector3(-move_input_smooth.x, 0, -move_input_smooth.y))
	var forward = global_basis.z
	var dot = direction.dot(forward)
	is_sprinting = Input.is_action_pressed("sprint") and stamina > 0.0 and is_on_floor() and dot > 0.5
	var target_speed = SPRINT_SPEED if (is_sprinting or jumped_while_sprinting) else SPEED
	speed_target = lerp(speed_target, target_speed, 14.0 * delta)

	if is_sprinting:
		stamina = max(stamina - STAMINA_SPRINT_COST * delta, 0.0)
		stamina_regen_timer = STAMINA_REGEN_DELAY
	
	# CROUCH
	var was_crouching = is_crouching
	
	var wants_to_uncrouch = not Input.is_action_pressed("crouch")
	if is_crouching and wants_to_uncrouch:
		if _can_uncrouch():
			is_crouching = false
	elif not is_crouching and Input.is_action_pressed("crouch") and not is_climbing:
		is_crouching = true
		if not was_crouching:
			crouch_tilt_velocity -= 0.8
	
	if !is_crouching and collision_normal.disabled == true:
		_enable_normal_col()

	# trigger the camera flick on crouch start
	if is_crouching and not was_crouching:
		_enable_crouch_col()
		crouch_tilt_velocity -= 0.8
	

	if is_climbing:
		
		
		#CLIMB ATTACH
		if is_climb_attaching:
			climb_attach_timer -= delta
			var t_raw = 1.0 - clamp(climb_attach_timer / CLIMB_ATTACH_DURATION, 0.0, 1.0)
			var t = 1.0 - pow(1.0 - t_raw, 3.0) #HARD EASE OUT
			global_position = global_position.lerp(climb_attach_target, t * 0.5)
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
					mantle_camera_tilt_target = -0.12
					mantle_camera_tilt = MANTLE_CAMERA_TILT
					is_mantling = true
					mantle_timer = MANTLE_DURATION
					is_climbing = false
					is_climb_attaching = false
					climb_reacquire_timer = MANTLE_DURATION + 0.4  # outlast the mantle
					_stop_climb()

	var current_air_accel = SPRINT_AIR_ACCELERATION if jumped_while_sprinting else AIR_ACCELERATION
	var target_accel = ACCELERATION if is_on_floor() else current_air_accel
	var target_decel = DECELERATION if is_on_floor() else AIR_FRICTION
	accel = lerp(accel, target_accel, 12.0 * delta)
	decel = lerp(decel, target_decel, 12.0 * delta)
	momentum_boost = lerp(momentum_boost, 1.0, 2.6 * delta)
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * speed_target * momentum_boost, accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed_target * momentum_boost, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, decel * delta)
		velocity.z = move_toward(velocity.z, 0, decel * delta)
	
	if is_mantling:
		mantle_timer -= delta
		var t_raw = 1.0 - clamp(mantle_timer / MANTLE_DURATION, 0.0, 1.0)
		var t = t_raw * t_raw * t_raw
		global_position = global_position.lerp(mantle_target, t * MANTLE_LERP_SPEED)
		velocity = Vector3.ZERO
		if mantle_timer <= 0.0:
			is_mantling = false
			mantle_reacquire_timer = MANTLE_REACQUIRE_COOLDOWN


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

	# THROW
	_update_throw(delta)

func _update_camera_clip() -> void:
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(
		camera_mount.global_position,
		camera_main.global_position
	)
	params.exclude = [self]
	var hit = space.intersect_ray(params)
	if hit:  # ignore floors
		camera_main.global_position = hit.position + hit.normal * 0.05

func _update_camera_ragdoll(delta: float) -> void:
	_partial_bob_update(delta)
	
	var eye_with_dip = EYE_HEIGHT - ragdoll_eye_dip
	var target_pos = collision_ragdoll.global_position + Vector3(0.0, eye_with_dip, 0.0)
	camera_smooth_pos = camera_smooth_pos.lerp(target_pos, CAMERA_DEFAULT_SMOOTH_SPEED * delta)
	camera_smooth_pos.y = max(camera_smooth_pos.y, collision_ragdoll.global_position.y + 0.012)
	camera_mount.global_position = camera_smooth_pos

	
	# apply dip rotation on top of ragdoll body rotation
	var from_q = Quaternion(camera_mount.basis.orthonormalized())
	var to_q = Quaternion(collision_ragdoll.global_transform.basis.orthonormalized())
	camera_mount.basis = Basis(from_q.slerp(to_q, LOOK_SMOOTHING * delta)).orthonormalized()
	camera_mount.rotation.x += ragdoll_landing_dip_rotation
	
	_update_camera_clip()

func _get_recovery_ease_t() -> float:
	var total_duration = RECOVERY_DURATION + RECOVERY_LINGER_DURATION
	var total_time
	if is_recovering:
		total_time = RECOVERY_DURATION - recovery_timer
	else:
		total_time = RECOVERY_LINGER_DURATION - recovery_linger_timer
	var t = 1.0 - clamp(total_time / total_duration, 0.0, 1.0)
	return t  # just linear 1→0, the pow() in the caller shapes it

func _handle_camera_mount_rotation(delta: float):
	
	var t = 1.0 - _get_recovery_ease_t() 
	var struggle = sin(t * PI * 3.0) * 0.3
	var eased = lerp(1.0, 3.0, pow(1.0 - t, 8.0)) + struggle
	recovery_tilt_x = lerp(recovery_tilt_x, 0.0, eased * delta)
	recovery_tilt_z = lerp(recovery_tilt_z, 0.0, eased * delta)

	if is_climbing:
		var target_wall_facing = atan2(climb_wall_normal.x, climb_wall_normal.z) + PI
		rotation.y = lerp_angle(rotation.y, target_wall_facing, 8.0 * delta)
		camera_mount.rotation.y = lerp_angle(camera_mount.rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
		camera_mount.rotation.x = lerp_angle(camera_mount.rotation.x, target_rotation_x, LOOK_SMOOTHING * delta)
	else:
		rotation.y = lerp_angle(rotation.y, body_target_rotation_y, LOOK_SMOOTHING * delta)  # changed
		camera_mount.rotation.y = lerp_angle(camera_mount.rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)

	var horizontal_input = Input.get_axis("move_right", "move_left")
	climb_tilt = lerp(climb_tilt, horizontal_input * CLIMB_TILT_STRENGTH if is_climbing else 0.0, CLIMB_TILT_SPEED * delta)
	camera_mount.rotation.z = climb_tilt + recovery_tilt_z

	var crouch_tilt_target = -CROUCH_CAMERA_TILT if is_crouching else 0.0
	var crouch_tilt_force = (crouch_tilt_target - crouch_tilt) * 180.0 - crouch_tilt_velocity * 12.0
	crouch_tilt_velocity += crouch_tilt_force * delta
	crouch_tilt += crouch_tilt_velocity * delta

	landing_dip_rotation = lerp(landing_dip_rotation, 0.0, LANDING_DIP_ROT_SPEED * delta)
	var tilt_target: float = CLIMB_CAMERA_TILT_TARGET if is_climbing else 0.0
	if camera_attach_smooth_timer > 0.0:
		climb_camera_tilt_target = lerp(climb_camera_tilt_target, tilt_target, CLIMB_CAMERA_TILT_ROT * delta)
	else:
		climb_camera_tilt_target = lerp(climb_camera_tilt_target, tilt_target, CLIMB_CAMERA_TILT_SPEED * delta)
	climb_camera_tilt = lerp(climb_camera_tilt, climb_camera_tilt_target, 12.0 * delta)
	mantle_camera_tilt_target = lerp(mantle_camera_tilt_target, 0.0 if not is_mantling else -0.05, 3.0 * delta)
	mantle_camera_tilt = lerp(mantle_camera_tilt, mantle_camera_tilt_target, 6.0 * delta)
	var attach_t = 1.0 - clamp(camera_attach_smooth_timer / CAMERA_ATTACH_SMOOTH_DURATION, 0.0, 1.0)
	var tilt_speed = lerp(8.0, LOOK_SMOOTHING, attach_t)
	camera_mount.rotation.x = lerp_angle(camera_mount.rotation.x, target_rotation_x + climb_camera_tilt + landing_dip_rotation + mantle_camera_tilt + recovery_tilt_x + crouch_tilt, tilt_speed * delta)

func _partial_bob_update(delta: float) -> void:
	ragdoll_landing_dip_rotation = lerp(ragdoll_landing_dip_rotation, 0.0, LANDING_DIP_ROT_SPEED * delta)
	ragdoll_landing_fov_dip = lerp(ragdoll_landing_fov_dip, 0.0, LANDING_FOV_DIP_SPEED * delta)

	var target_fov = FOV_DEFAULT - ragdoll_landing_fov_dip
	camera_main.fov = lerp(camera_main.fov, target_fov, FOV_LERP_SPEED * delta)

func _update_bob(delta: float) -> void:
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	var speed_ratio = clamp(horizontal_speed / SPEED, 0.0, 1.0)
	var bob_offset_y = 0.0
	var bob_offset_x = 0.0
	var bob_offset_z = 0.0
	if horizontal_speed > 0.4 and is_on_floor():
		bob_time += delta * BOB_FREQUENCY
		bob_offset_y = sin(bob_time) * BOB_AMPLITUDE_Y * speed_ratio
		bob_offset_x = cos(bob_time * 0.5) * BOB_AMPLITUDE_X * speed_ratio
	
	var is_idle = idle_check and idle_timer > 1.8 and is_on_floor()
	idle_bob_blend = lerp(idle_bob_blend, 1.0 if is_idle else 0.0, delta)
	
	if idle_bob_blend > 0.001:
		idle_bob_time += delta * IDLE_BOB_FREQUENCY * idle_bob_blend
		bob_offset_x += sin(idle_bob_time) * IDLE_BOB_RADIUS * idle_bob_blend
		bob_offset_z = cos(idle_bob_time) * IDLE_BOB_RADIUS * idle_bob_blend

	if camera_attach_smooth_timer > 0.0:
		camera_attach_smooth_timer -= delta

	var eye_lerp_speed: float
	var smooth_speed: float
	
	
	if is_recovering or recovery_linger:
		eye_lerp_speed = RECOVERY_EYE_HEIGHT_SPEED
	else:
		eye_lerp_speed = LANDING_DIP_ROT_SPEED
	
	var raw_t = 1.0 - clamp(camera_attach_smooth_timer / CAMERA_ATTACH_SMOOTH_DURATION, 0.0, 1.0)
	var smooth_t = raw_t * raw_t * raw_t
	smooth_speed = lerp(CAMERA_ATTACH_SMOOTH_SPEED, CAMERA_DEFAULT_SMOOTH_SPEED, smooth_t)
	
	var eye_target = CROUCH_EYE_HEIGHT if is_crouching else EYE_HEIGHT
	eye_height_current = lerp(eye_height_current, eye_target, eye_lerp_speed * delta)
	
	var target_pos = global_position + Vector3(bob_offset_x, bob_offset_y + eye_height_current, bob_offset_z)

	var xz_speed = smooth_speed
	var y_speed = smooth_speed
	
	
	var total = RECOVERY_DURATION + RECOVERY_LINGER_DURATION

	var elapsed = RECOVERY_DURATION - recovery_timer  # counts up during recovery
	
	if not is_recovering:
		elapsed = RECOVERY_DURATION + (RECOVERY_LINGER_DURATION - recovery_linger_timer)
	
	if is_recovering or recovery_linger:
		var raw = elapsed / total
		var t = clamp((raw - 0.36) / 0.64, 0.0, 1.0)
		var ease = (1.0 - pow(1.0 - t, 18)) * 6.2
		# crazy dip
		var dip_t = clamp((raw - 0.18) / 0.16, 0.0, 1.0)
		var dip = -pow(sin(dip_t * PI), 0.4) * 18.0
		y_speed = ease + dip

	camera_smooth_pos.x = lerp(camera_smooth_pos.x, target_pos.x, xz_speed * delta)
	camera_smooth_pos.z = lerp(camera_smooth_pos.z, target_pos.z, xz_speed * delta)
	camera_smooth_pos.y = lerp(camera_smooth_pos.y, target_pos.y, y_speed * delta)
	
	var floor_safe_y = global_position.y + 0.012  # tiny epsilon above floor
	camera_smooth_pos.y = max(camera_smooth_pos.y, floor_safe_y)
	camera_mount.global_position = camera_smooth_pos

func _spring(current: float, target: float, velocity: float, stiffness: float, damping: float, delta: float) -> Array:
	var force = (target - current) * stiffness - velocity * damping
	velocity += force * delta
	current += velocity * delta
	return [current, velocity]
