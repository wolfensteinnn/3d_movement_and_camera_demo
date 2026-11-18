extends CharacterBody3D
class_name Player
@onready var camera_mount: Node3D = $CameraMount
@onready var camera_main: Camera3D = $CameraMount/Camera3D
@onready var meshes: Skeleton3D = $duck_wholebody_transform/duck/Armature/Skeleton3D
@onready var grab_cast: RayCast3D = $CameraMount/GrabCast
@onready var hit_detector: Area3D = $HitDetector
@onready var hold_point: Node3D = $CameraMount/HoldPoint


@onready var duck_mesh: Node3D = $duck_wholebody_transform

# SHIP RELATED
var current_platform: Node3D = null              # the AnimatableBody3D we're currently standing on, or null
var was_on_platform: bool = false                 # last frame's state, so we can detect the leave-frame

var platform_velocity: Vector3 = Vector3.ZERO     # linear velocity the platform is contributing to us right now
var platform_angular_velocity: Vector3 = Vector3.ZERO  # copy of the platform's angular_velocity var

var platform_local_offset: Vector3 = Vector3.ZERO # our position relative to the platform's origin (needed for angular contribution)

var local_velocity: Vector3 = Vector3.ZERO        # velocity - platform_velocity — "how fast are we actually walking on deck"

var platform_debug_enabled: bool = true
var platform_debug_timer: float = 0.0
const PLATFORM_DEBUG_INTERVAL = 0.5  # seconds between prints, so it doesn't flood the console

# WATER RELATED
var clipmap_tile_size := 1.0 
var previous_tile := Vector3i.MAX
var water

# MESH ROTATION (CLIMB/HANG)
const MESH_ROTATION_LERP_SPEED = 6.0
var mesh_target_basis: Basis = Basis.IDENTITY

var debug_velocity
var test_projectile: RigidBody3D = null

#UI
var stamina_bar
var cursor
var emote_wheel
var inputs_blocked:bool = false

# CAMERA GENERAL
const CAMERA_ATTACH_SMOOTH_SPEED = 10.6
const CAMERA_DEFAULT_SMOOTH_SPEED = 16.0
var camera_smooth_pos: Vector3 = Vector3.ZERO
const LOOK_SMOOTHING = 17.0
const MOUSE_SENSITIVITY = 0.002
const EYE_HEIGHT = 0.111
const EYE_HEIGHT_LANDING_DIP = 0.009
var eye_height_current: float = 0.111
var cam_clip_target: Vector3 = Vector3.ZERO  # add with other vars
var cam_clip_active: bool = false

# CAMERA BOB
const BOB_FREQUENCY = 20.6
const BOB_AMPLITUDE_Y = 0.018
const BOB_AMPLITUDE_X = 0.01
var bob_time: float = 0.0
var idle_bob_time: float = 0.0
const IDLE_BREATHE_FREQUENCY = 0.28      # full breath cycle per second
const IDLE_BREATHE_AMPLITUDE_Y = 0.0038  # very subtle vertical
const IDLE_BREATHE_AMPLITUDE_X = 0.0016  # tiny forward lean on inhale
const IDLE_BREATHE_AMPLITUDE_Z = 0.0014  # barely perceptible side
var idle_bob_blend: float = 0.0
var idle_check:bool = false
var idle_timer = 0.0

# WALK BOB
const WALK_BOB_FREQUENCY = 17.0
const WALK_BOB_AMPLITUDE_Y = 0.006
const WALK_BOB_AMPLITUDE_X = 0.0095

# SPRINT BOB
const SPRINT_BOB_FREQUENCY = 21.0
const SPRINT_BOB_AMPLITUDE_Y = 0.011
const SPRINT_BOB_AMPLITUDE_X = 0.0156

# CLIMB BOB
const CLIMB_BOB_FREQUENCY = 5.1
const CLIMB_BOB_AMPLITUDE_Y = 0.011
const CLIMB_BOB_AMPLITUDE_X = 0.026
var climb_bob_time: float = 0.0
var climb_bob_blend: float = 0.0

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
var move_tilt: float = 0.0

# CROUCH
const CROUCH_EYE_HEIGHT = 0.04
const CROUCH_CAMERA_TILT = 0.06
const CROUCH_CAMERA_TILT_SPEED = 8.0
const CROUCH_SPEED = 0.3
var is_crouching: bool = false
var crouch_tilt: float = 0.0
var crouch_tilt_velocity: float = 0.0

#SPRINT
const SPRINT_SPEED = 0.48
const STAMINA_SPRINT_COST = 18.0
var is_sprinting: bool = false
var jumped_while_sprinting: bool = false
var just_jumped: bool = false
var sprint_lean: float = 0.0

# SLOPE MOVEMENT
var slope_speed_modifier: float = 1.0        # read this in animation system
var slope_steepness: float = 0.0             # 0 = flat, 1 = max uphill (read for anims)
const SLOPE_SPEED_MIN = 0.32                 # how slow at max uphill angle
const SLOPE_UPHILL_THRESHOLD = 0.08          # dot product before slowdown kicks in
const SLOPE_MODIFIER_LERP = 8.0              # smoothing speed
const SLOPE_SPRINT_BLOCK = 0.3               # steepness above which sprint is cut

# SLOPE BOB
const UPHILL_BOB_FREQUENCY = 7.0 
const UPHILL_BOB_AMPLITUDE_Y = 0.013    
const UPHILL_BOB_AMPLITUDE_X = 0.008 
const UPHILL_BOB_THRESHOLD = 0.35       # slope_steepness above this triggers it
const UPHILL_BOB_BLEND_SPEED = 9.0      # fast snap in/out
var uphill_bob_blend: float = 0.0
var uphill_bob_time: float = 0.0

# MANTLING
var is_mantling: bool = false
var pending_jump_mantle: Vector3 = Vector3.ZERO #for jumping mantles
var pending_jump_mantle_timer: float = 0.0
var mantle_timer: float = 0.0
const MANTLE_DURATION = 0.64        # total time of the mantle
const MANTLE_LERP_SPEED = 0.16      # lower = floatier, higher = snappier
var mantle_target: Vector3 = Vector3.ZERO
const MANTLE_DISTANCE = 0.075 #around 45% of the duck
var mantle_reacquire_timer: float = 0.0
const MANTLE_REACQUIRE_COOLDOWN = 0.48

# SURFACE-RELATIVE CLIMBING
var climb_surface: Node3D = null
var climb_local_offset: Vector3 = Vector3.ZERO
var climb_local_normal: Vector3 = Vector3.ZERO
var climb_surface_prev_transform: Transform3D = Transform3D.IDENTITY

# CLIMB INIT
const CLIMB_MIN_STAMINA_TO_ATTACH = 10.0
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
const WALL_ACQUISITION_LENGTH = 0.208
const WALL_ACQUISITION_VERTICAL_SPREAD = 0.08
const CLIMB_DETACH_GRACE = 0.4
const CLIMB_ATTACH_GRACE = 0.38   # tweak alongside CLIMB_ATTACH_DURATION
var climb_attach_grace_timer: float = 0.0
const CLIMB_REACQUIRE_COOLDOWN = 0.12
var climb_detach_timer: float = 0.0
var climb_reacquire_timer: float = 0.0
var wall_nudge_timer: float = 0.0
var wall_nudge_dir: Vector3 = Vector3.ZERO
const WALL_NUDGE_DURATION = 0.14
const WALL_NUDGE_STRENGTH = 0.55
var prev_wall_normal: Vector3 = Vector3.ZERO

# CLIMBABLE SURFACE ANGLE THRESHOLDS
const CLIMB_FLOOR_THRESHOLD = 0.629   #  DEGREES
const CLIMB_CEIL_THRESHOLD  = -0.99   # BASSICALLY ANYTHING

# HANGING SYSTEM
var hanging_bar
const HANGING_MAX = 100.0
var hanging: float = 100.0
const HANGING_REGEN_RATE = 18.0
const HANGING_REGEN_DELAY = 0.6
var hanging_regen_timer: float = 0.0

const HANGING_DRAIN_MIN = 2.0    # leaning/shallow surface
const HANGING_DRAIN_MAX = 28.0   # sheer vertical wall

var hang_pitch_velocity: float = 0.0
var hang_pitch: float = 0.0

var is_hanging: bool = false

# WALL LUNGE CAMERA EFFECTS
var wall_lunge_fov_punch: float = 0.0
const WALL_LUNGE_FOV_PUNCH = 8.0
const WALL_LUNGE_FOV_DECAY = 1.2

var wall_lunge_cam_tilt: float = 0.0
const WALL_LUNGE_CAM_TILT = 0.09

var wall_lunge_cam_nudge: float = 0.0
const WALL_LUNGE_NUDGE = 0.04
var wall_lunge_nudge_dir: float = 0.0  # +1 right, -1 left

var wall_lunge_cam_pitch: float = 0.0
const WALL_LUNGE_PITCH_DECAY = 1.2

var wall_lunge_tilt_velocity: float = 0.0
var wall_lunge_pitch_velocity: float = 0.0

# WALL JUMPS
 
const WALL_JUMP_VELOCITY_UP      = 0.45   # upward pop (tune vs JUMP_VELOCITY = 0.76)
const WALL_JUMP_VELOCITY_OUT     = 0.55   # push away from wall
const WALL_JUMP_CAMERA_BLEND     = 0.48   # how much camera fwd direction steers the jump (0 = pure normal, 1 = pure cam)
const WALL_JUMP_LATERAL_BOOST    = 0.38   # extra lateral momentum from move input
const WALL_JUMP_CAM_FACING_THRESHOLD = -0.7  # dot(cam_fwd, wall_normal) > this = "looking away"
const WALL_JUMP_STAMINA_COST     = 8.0   # same as lunge so it feels consistent
const WALL_JUMP_COOLDOWN         = 0.3
const WALL_JUMP_FOV_PUNCH        = 11.0
const WALL_JUMP_REACQUIRE_DELAY  = 0.55   # keeps you from immediately re-grabbing the same wall
 
var wall_jump_cooldown_timer: float = 0.0  # separate from wall_lunge_cooldown so they don't interfere

# WALL DISTANCE
# how far the player sits from the wall surface on attach and maintain
const CLIMB_WALL_OFFSET = 0.006       # offset on _start_climb snap
const CLIMB_MAINTAIN_DEPTH = 0.5     # how deep _maintain_climb casts into wall

# NEW CLIMBING
var climb_wall_normal: Vector3 = Vector3.ZERO
var current_wall_normal: Vector3 = Vector3.ZERO

# CLIMBING
var climb_input_anim_cache: Vector2 = Vector2.ZERO
var is_climbing = false
var climb_speed: float = 0.22
var climb_tilt: float = 0.0

# CLIMB STAMINA SHAKE
var climb_shake_blend: float = 0.0
var climb_shake_time: float = 0.0
const CLIMB_SHAKE_FREQUENCY = 32.0
const CLIMB_SHAKE_AMPLITUDE_Y = 0.0015
const CLIMB_SHAKE_AMPLITUDE_X = 0.0024
const CLIMB_SHAKE_AMPLITUDE_Z = 0.0008

var climb_shake_fov: float = 0.0
const CLIMB_SHAKE_FOV_AMPLITUDE = 0.5  # subtle — tweak between 0.3 and 0.8

# WALL LUNGES
var wall_lunge_cooldown_timer: float = 0.0
const WALL_LUNGE_COOLDOWN = 0.35
const WALL_LUNGE_STAMINA_COST = 17.0
const WALL_LUNGE_IMPULSE = 1.1
var wall_lunge_boost: Vector3 = Vector3.ZERO
const WALL_LUNGE_DECAY = 18.0
var wall_lunge_triggered: bool = false

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
const GRAVITY_UP = -2.0
const GRAVITY_DOWN = -3.2
const GRAVITY_PEAK_THRESHOLD = 1.2
const TERMINAL_VELOCITY = -8.5

#Falling
var fall_start_y: float = 0.0
var is_falling: bool = false
var fall_distance: float = 0.0

#AIR
const AIR_ACCELERATION = 3.5
const SPRINT_AIR_ACCELERATION = 5.2
const AIR_FRICTION = 0.36

#JUMP
const JUMP_VELOCITY = 0.76
const JUMP_GRACE_TIME = 0.07
const JUMP_BUFFER_TIME = 0.12
var jump_grace_timer: float = 0.0
var jump_buffer_timer: float = 0.0
const JUMP_MOMENTUM_BOOST = 1.16
const JUMP_MOMENTUM_BOOST_SPRINT = 1.48
var momentum_boost: float = 1.0

# FREEFALL CAMERA
var fall_lean: float = 0.0
var fall_fov_bonus: float = 0.0
var fall_drift_time: float = 0.0
const FALL_FOV_MAX = 5.0
const FALL_LEAN_MAX = 0.08
const FALL_DRIFT_AMPLITUDE = 0.028
const FALL_DRIFT_FREQUENCY = 1.5
const FALL_ONSET_DISTANCE = 0.5  # meters before effect kicks in
const FALL_FULL_DISTANCE = 1.2   # meters where effect is at full strength

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
const RAGDOLL_RECOVERY_TIME = 1.28
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
var emote_anim: String = "null"
var emote_anim_grace = 0.0
const EMOTE_ANIM_GRACE = 0.35
@onready var anim_tree: AnimationTree = $duck_wholebody_transform/duck/AnimationTree

#DEBUG
var prev_pos: Vector3

# HANDBONES
@onready var hand_r: Node3D = $duck_wholebody_transform/duck/Hand_r
@onready var hand_l: Node3D = $duck_wholebody_transform/duck/Hand_l

#BONES MODIFIERS
@onready var modifier_rotation: DMWBWiggleRotationModifier3D = $duck_wholebody_transform/duck/Armature/Skeleton3D/modifier_base_head_rotation
@onready var modifier_eyes_y: BoneRotationModifier3D = $duck_wholebody_transform/duck/Armature/Skeleton3D/modifier_eyes_y


# IDLE TURN & EYE LOOK
const IDLE_TURN_THRESHOLD = deg_to_rad(80.0) # radians — body turns beyond this, eyes track within it
const IDLE_TURN_SPEED = 2.4 
var body_target_rotation_y: float = 0.0
var look_lerp_speed: float = 7.2
var current_eye_y: float = 0.0
var idle_is_turning:bool = false
var current_head_tilt: float = 0.0

# BLINKING
@onready var eyes: MeshInstance3D = $duck_wholebody_transform/duck/Armature/Skeleton3D/eyes
var blink_timer: float = 0.0
var blink_interval: float = 0.0
var blink_value: float = 0.0
var is_blinking: bool = false
const BLINK_SPEED_CLOSE = 18.0
const BLINK_SPEED_OPEN = 10.0

# SCREEN FX
var screen_fx_material: ShaderMaterial
var ragdoll_vignette:float = 0.0

var small_error_shake_value:float = 0.4
var small_error_shake_cooldown:float = 0.0
const SMALL_ERROR_SHAKE_COOLDOWN:float = 0.8

# NETCODE
@onready var tick_interpolator: TickInterpolator = $TickInterpolator

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

func _ui_setup(an_emote_wheel):
	emote_wheel = an_emote_wheel

func _set_water(a_water):
	water = a_water

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

func _hide_cursor():
	if cursor.visible:
		cursor.visible = false

func _show_cursor():
	if !cursor.visible:
		cursor.visible = true

func _set_stamina_bar(a_bar):
	stamina_bar = a_bar

func _set_hanging_bar(a_bar):
	hanging_bar = a_bar

func _set_debug_velocityLabel(a_label):
	debug_velocity = a_label

func _set_screen_fx(a_shader):
	screen_fx_material = a_shader.material

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

func _reset_blink_timer() -> void:
	blink_interval = randf_range(2.5, 4.8)
	blink_timer = blink_interval

func _update_blink(delta: float) -> void:
	if is_ragdoll:
		return
	blink_timer -= delta
	if blink_timer <= 0.0:
		is_blinking = true

	if is_blinking:
		blink_value = lerp(blink_value, 1.0, BLINK_SPEED_CLOSE * delta)
		if blink_value >= 0.98:
			is_blinking = false
			_reset_blink_timer()
	else:
		blink_value = lerp(blink_value, 0.0, BLINK_SPEED_OPEN * delta)

	eyes.set_blend_shape_value(
		eyes.find_blend_shape_by_name("EyesClose"),
		blink_value
	)

func _ready() -> void:
	camera_smooth_pos = global_position
	velocity = Vector3.ZERO
	if is_multiplayer_authority():
		_reset_blink_timer()
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
			any.cast_shadow = 3 #SETS THE SHADOW CAST ONLY MODE (SO THAT YOU CAN SEE YOUR OWN SHADOW
		
		hand_r.position = Vector3(0.0,0.0,0)
		hand_l.position = Vector3(-0.0,0.0,0)
		
		target_rotation_y = rotation.y
		body_target_rotation_y = rotation.y
		target_rotation_x = camera_mount.rotation.x
	else:
		tick_interpolator.enabled = true
		tick_interpolator.enable_recording = true

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
	
	if is_multiplayer_authority():
		if event.is_action_pressed("emotes") and !is_climbing and !is_falling and !is_ragdoll and !is_hanging and held_player == null:
			_hide_cursor()
			if !inputs_blocked:
				inputs_blocked = true
			emote_wheel._activate()
		if event.is_action_released("emotes"):
			_show_cursor()
			if inputs_blocked:
				inputs_blocked = false
			emote_anim = emote_wheel._choose_and_close()
			emote_anim_grace = 0.0
		
		if event.is_action_pressed("climb") and inputs_blocked:
			_show_cursor()
			if inputs_blocked:
				inputs_blocked = false
			emote_anim = emote_wheel._choose_and_close()
			emote_anim_grace = 0.0
	
	
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
	
	if inputs_blocked:
		return
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
		if event.keycode == KEY_R:
			global_position = Vector3(2.7,9,3)
		if event.keycode == KEY_T:
			_launch_test_projectile()
	
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_O:
		Engine.time_scale = 3.0
	else:
		Engine.time_scale = 1.0
	
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
		
	#if event is InputEventMouseMotion:
		#target_rotation_y -= event.relative.x * MOUSE_SENSITIVITY
		#target_rotation_x += event.relative.y * MOUSE_SENSITIVITY
		#target_rotation_x = clamp(target_rotation_x, deg_to_rad(-75), deg_to_rad(75))

	if event.is_action_pressed("jump"):
		if emote_anim != "null" and emote_anim_grace > EMOTE_ANIM_GRACE:
			emote_anim = "null"
		jump_buffer_timer = JUMP_BUFFER_TIME

func _update_stamina(delta: float) -> void:
	if is_climbing:
		if is_instance_valid(stamina_bar):
			stamina_bar.value = max(stamina, 0)
		return
	if stamina_regen_timer > 0.0:
		stamina_regen_timer -= delta
	else:
		stamina = min(stamina + STAMINA_REGEN_RATE * delta, STAMINA_MAX)
	if is_instance_valid(stamina_bar):
		stamina_bar.value = max(stamina, 0)

func _update_hanging(delta: float) -> void:
	if is_hanging:
		var drain_rate = _get_hanging_drain_rate(current_wall_normal)
		hanging = max(hanging - drain_rate * delta, 0.0)
		if hanging <= 0.0:
			is_hanging = false
			if not is_falling:
				is_falling = true
				fall_start_y = global_position.y
			_stop_climb()
	else:
		if hanging_regen_timer > 0.0:
			hanging_regen_timer -= delta
		else:
			hanging = min(hanging + HANGING_REGEN_RATE * delta, HANGING_MAX)

	if is_instance_valid(hanging_bar):
		hanging_bar.value = max(hanging, 0)

func _update_mesh_rotation(delta: float) -> void:
	var target_pitch: float = 0.0
	if is_climbing and not is_hanging:
		# Snap to surface like Spiderman
		target_pitch = climb_wall_normal.y * deg_to_rad(90.0)
		hang_pitch = duck_mesh.rotation.x  # keep spring in sync so no pop when transitioning
		hang_pitch_velocity = 0.0
		duck_mesh.rotation.x = lerp_angle(duck_mesh.rotation.x, target_pitch, MESH_ROTATION_LERP_SPEED * delta)
	elif is_hanging:
		var wall_up = climb_wall_normal.cross(Vector3.UP).normalized()
		var gravity_dot = Vector3.DOWN.dot(wall_up)
		var gravity_target = gravity_dot * deg_to_rad(90.0)

		var up_dot = climb_wall_normal.dot(Vector3.UP)

		if up_dot > 0.3:
			var surface_target = climb_wall_normal.y * deg_to_rad(90.0)
			duck_mesh.rotation.x = lerp_angle(duck_mesh.rotation.x, surface_target, MESH_ROTATION_LERP_SPEED * delta)
			hang_pitch = duck_mesh.rotation.x
			hang_pitch_velocity = 0.0
			return

		var result = _spring(hang_pitch, gravity_target, hang_pitch_velocity, 18.0, 4.2, delta)
		hang_pitch = result[0]
		hang_pitch_velocity = result[1]
		duck_mesh.rotation.x = hang_pitch
	else:
		hang_pitch_velocity = 0.0
		hang_pitch = duck_mesh.rotation.x
		duck_mesh.rotation.x = lerp_angle(duck_mesh.rotation.x, 0.0, MESH_ROTATION_LERP_SPEED * delta)

func _maintain_climb() -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + (-climb_wall_normal * CLIMB_MAINTAIN_DEPTH)
	)
	query.exclude = [self]
	return space_state.intersect_ray(query)

func _maintain_climb_depth() -> void:
	if climb_surface == null or not is_instance_valid(climb_surface):
		return
	var hit = _maintain_climb()
	if hit.is_empty():
		return
	var desired_pos = hit.position + climb_wall_normal * CLIMB_WALL_OFFSET
	var diff = desired_pos - global_position
	var correction = diff.dot(-climb_wall_normal)
	if abs(correction) < 0.012:
		return
	var target_offset = -climb_wall_normal * correction
	var nudge = global_position.lerp(global_position + target_offset, 0.1)  - global_position
	global_position += nudge
	camera_smooth_pos += nudge

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

func _close_eyes():
	eyes.set_blend_shape_value(
		eyes.find_blend_shape_by_name("EyesClose"),
		1.0
	)

@rpc("any_peer", "reliable","call_local")
func _sync_start_ragdoll(impulse: Vector3 = Vector3.ZERO) -> void:
	_start_ragdoll(impulse)

@rpc("any_peer", "reliable", "call_local")
func _sync_stop_ragdoll() -> void:
	_stop_ragdoll()

func _start_ragdoll(impulse: Vector3 = Vector3.ZERO) -> void:
	landing_dip_rotation = 0
	ragdoll_vignette = 1.12
	
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
	
	var launch = impulse if impulse != Vector3.ZERO else pre_impact_velocity
	launch = launch.limit_length(6.0)
	collision_ragdoll.linear_velocity = launch
	
	var tumble_axis = launch.normalized().cross(Vector3.UP)
	# tiny random bias so repeated ragdolls don't look identical
	tumble_axis = (tumble_axis + Vector3(randf_range(-0.3, 0.3), randf_range(-0.1, 0.1), randf_range(-0.3, 0.3))).normalized()
	var spin_strength = clamp(launch.length() * 2.5, 1.5, 9.0)
	collision_ragdoll.angular_velocity = tumble_axis * spin_strength
	
	just_jumped = false
	jumped_while_sprinting = false
	is_falling = false
	is_climbing = false
	is_mantling = false
	is_climb_attaching = false
	climb_reacquire_timer = RAGDOLL_MIN_DURATION + RAGDOLL_RECOVERY_TIME + 0.2
	
	_notify_teleport_if_remote()

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
	
	_notify_teleport_if_remote()

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
	rpc("_sync_start_ragdoll", hit_velocity)

func _get_climb_speed_modifier() -> float:
	var t = clamp(stamina / STAMINA_MAX, 0.0, 1.0)
	var remapped = clamp(t / 0.16, 0.0, 1.0)  # 0→0.16 stamina maps to 0→1
	return lerp(0.18, 0.8, remapped)

func _get_climb_stamina_drain_modifier() -> float:
	var t = clamp(stamina / STAMINA_MAX, 0.0, 1.0)
	var remapped = clamp(t / 0.16, 0.0, 1.0)
	return lerp(0.04, 1.0, remapped)

func _get_climb_shake_strength() -> float:
	if is_hanging:
		return 1.0
	var t = clamp(stamina / STAMINA_MAX, 0.0, 1.0)
	var remapped = clamp(t / 0.16, 0.0, 1.0)
	return 1.0 - lerp(0.0, 1.0, remapped)

func _get_hanging_drain_rate(normal: Vector3) -> float:
	return 5.8
	#var steepness = 1.0 - clamp(absf(normal.y) / CLIMB_FLOOR_THRESHOLD, 0.0, 1.0)
	#return lerp(HANGING_DRAIN_MIN, HANGING_DRAIN_MAX, steepness)

func _update_climb_surface_transform(delta) -> void:
	if climb_surface == null or not is_instance_valid(climb_surface):
		climb_surface = null
		return
	
	var current_transform = climb_surface.global_transform
	
	# if the surface didn't move this frame, nothing to do
	if current_transform.is_equal_approx(climb_surface_prev_transform):
		climb_surface_prev_transform = current_transform
		return
	
	# reproject our local offset into the new world position
	var new_world_pos = climb_surface.to_global(climb_local_offset)
	var delta_pos = new_world_pos - global_position

	global_position = new_world_pos
	camera_smooth_pos += delta_pos
	
	# rotate the wall normal with the surface
	climb_wall_normal = (current_transform.basis * climb_local_normal).normalized()
	if current_wall_normal.distance_to(climb_wall_normal) < 0.001:
		current_wall_normal = climb_wall_normal
	else:
		current_wall_normal = current_wall_normal.lerp(climb_wall_normal, 16.0 * delta)
	
	climb_surface_prev_transform = current_transform

func wall_normal_flat() -> Vector3:
	var n = climb_wall_normal
	n.y = 0.0
	return n.normalized() if n.length_squared() > 0.001 else -global_transform.basis.z

func _wall_jump() -> void:
	# Direction: blend between pure wall normal and camera forward
	var cam_fwd   = -camera_mount.global_transform.basis.z
	cam_fwd.y     = 0.0
	cam_fwd       = cam_fwd.normalized()
 
	# Jump direction = lerp between wall_normal and camera forward, then add upward
	var jump_dir  = wall_normal_flat().lerp(cam_fwd, WALL_JUMP_CAMERA_BLEND).normalized()
 
	# Lateral boost from move input (lets you arc left/right off the wall)
	var right_dir = climb_wall_normal.cross(Vector3.UP).normalized()
	var lat_input = Input.get_axis("move_right", "move_left")
	var lateral   = right_dir * lat_input * WALL_JUMP_LATERAL_BOOST
 
	velocity.x = (jump_dir.x + lateral.x) * WALL_JUMP_VELOCITY_OUT
	velocity.z = (jump_dir.z + lateral.z) * WALL_JUMP_VELOCITY_OUT
	velocity.y = WALL_JUMP_VELOCITY_UP
 
	stamina = max(stamina - WALL_JUMP_STAMINA_COST, 0.0)
	stamina_regen_timer = STAMINA_REGEN_DELAY
 
	# Camera feel
	wall_lunge_fov_punch  = WALL_JUMP_FOV_PUNCH
	wall_lunge_cam_pitch  = -0.10   # slight look-up kick
	wall_lunge_cam_tilt   = lat_input * 0.14
 
	# State cleanup
	wall_jump_cooldown_timer = WALL_JUMP_COOLDOWN
	climb_reacquire_timer    = max(climb_reacquire_timer, WALL_JUMP_REACQUIRE_DELAY)
	just_jumped              = true
	jumped_while_sprinting   = false   # wall jump has its own feel, don't inherit sprint state
	jump_buffer_timer        = 0.0
	jump_grace_timer         = 0.0
 
	_stop_climb()

func _start_climb(acquisition: Dictionary = {}) -> void:
	if not acquisition.is_empty() and acquisition.has("collider"):
		climb_surface = acquisition.collider
		climb_local_offset = climb_surface.to_local(global_position)
		climb_local_normal = climb_surface.global_transform.basis.inverse() * climb_wall_normal
		climb_surface_prev_transform = climb_surface.global_transform
	else:
		climb_surface = null
		climb_local_offset = Vector3.ZERO
		climb_local_normal = Vector3.ZERO
	
	climb_bob_time = 0.0
	climb_bob_blend = 0.0
	
	is_hanging = false
	hanging = HANGING_MAX
	camera_smooth_pos = global_position  # NEEDED FOR A SNAP TO BE MORE SNAPPY 
	is_falling = false
	just_jumped = false
	jumped_while_sprinting = false
	fall_distance = 0.0
	climb_camera_tilt = 0.16   # push down first
	climb_camera_tilt_target = CLIMB_CAMERA_TILT_OVERSHOOT  # target is up
	camera_attach_smooth_timer = CAMERA_ATTACH_SMOOTH_DURATION
	climb_detach_timer = 0.0
	current_wall_normal = climb_wall_normal
	_set_cursor_climb()
	is_climbing = true
	is_climb_attaching = true
	climb_attach_timer = CLIMB_ATTACH_DURATION
	climb_attach_grace_timer = CLIMB_ATTACH_GRACE
	var hit = _maintain_climb()
	if hit:
		climb_attach_target = hit.position + climb_wall_normal * CLIMB_WALL_OFFSET
		climb_attach_target.y = global_position.y + 0.14  # preserve vertical position + slight nudge upwards
	else:
		climb_attach_target = global_position

func _stop_climb() -> void:
	climb_surface = null
	climb_local_offset = Vector3.ZERO
	climb_local_normal = Vector3.ZERO
	is_climbing = false
	is_hanging = false
	climb_detach_timer = 0.0
	climb_reacquire_timer = CLIMB_REACQUIRE_COOLDOWN
	pending_jump_mantle = Vector3.ZERO  # cancel any pending mantle
	pending_jump_mantle_timer = 0.0

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
		params.to = global_position + rotated_dir * WALL_PROBE_LENGTH * 0.8
		var hit = space.intersect_ray(params)
		if not hit.is_empty() and _is_climbable_normal(hit.normal):
			if hit.position.y < global_position.y - 0.05:
				continue
			var diff = 1.0 - prev_wall_normal.dot(hit.normal)
			if diff > best_score:
				best_score = diff
				best_hit = hit

	return best_hit

func _try_acquire_wall() -> Dictionary:
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.exclude = [self]
	params.collision_mask = 1
	
	# cast from camera in the direction the player is looking
	var cam_origin = camera_mount.global_position
	var cam_forward = camera_mount.global_transform.basis.z
	
	params.from = cam_origin
	params.to = cam_origin + cam_forward * WALL_ACQUISITION_LENGTH
	var hit = space.intersect_ray(params)
	
	
	if hit.is_empty():
		return {}
	if hit.collider is Player:
		return {}
	if not _is_climbable_normal(hit.normal):
		return {}
	if hit.position.y < global_position.y + 0.05:
		return {}
	
	return hit

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
			
			# re-anchor to the new surface
			var new_surface = col.get_collider()
			if new_surface != null and is_instance_valid(new_surface):
				climb_surface = new_surface
				climb_local_offset = climb_surface.to_local(global_position)
				climb_local_normal = (climb_surface.global_transform.basis.inverse() * n).normalized()
				climb_surface_prev_transform = climb_surface.global_transform
			
			break

func _is_at_bottom_edge() -> bool:
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.exclude = [self]
	params.collision_mask = 1
	
	var forward = -climb_wall_normal
	
	var high_origin = global_position + Vector3.UP * 0.15
	params.from = high_origin
	params.to = high_origin + forward * 0.35
	var high_hit = space.intersect_ray(params)
	
	var low_origin = global_position + Vector3.DOWN * 0.05
	params.from = low_origin
	params.to = low_origin + forward * 0.35
	var low_hit = space.intersect_ray(params)
	
	if high_hit.is_empty(): return false
	if not _is_climbable_normal(high_hit.normal): return false
	if low_hit.is_empty(): return true
	if not _is_climbable_normal(low_hit.normal): return true
	return false

func _try_mantle(height_tolerance: float = 0.12) -> Dictionary:
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
	if ledge_height_diff > height_tolerance or ledge_height_diff < -0.05:
		return {}
	
	# confirm the landing spot is walkable
	if ledge_hit.normal.y < 0.629:
		return {}
	
	return { "position": ledge_hit.position }

func _try_mantle_jump() -> Dictionary:
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.exclude = [self]
	params.collision_mask = 1
	
	var forward = camera_mount.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	
	params.from = global_position
	params.to = global_position + forward * (CLIMB_WALL_OFFSET + 0.1)
	var wall_hit = space.intersect_ray(params)
	
	
	if wall_hit.is_empty():
		return {}
	
	
	var ledge_top_origin = wall_hit.position + Vector3.UP * 0.25 + forward * 0.05
	params.from = ledge_top_origin
	params.to = ledge_top_origin + Vector3.DOWN * 0.25
	var ledge_hit = space.intersect_ray(params)
	
	
	if ledge_hit.is_empty():
		return {}
	

	
	var ledge_height_diff = ledge_hit.position.y - global_position.y
	
	if ledge_height_diff > 0.35 or ledge_height_diff < -0.05:
		return {}
	
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

@rpc("any_peer", "unreliable_ordered")
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
		rpc("_sync_start_ragdoll", throw_velocity)

func _update_throw(delta):
	
	if Input.is_action_just_pressed("grab") and held_player == null:
		_try_grab()

	if Input.is_action_pressed("climb") and held_player != null:
		throw_charge = min(throw_charge + charge_speed * delta, max_throw_force)

	if Input.is_action_just_released("climb") and held_player != null:
		_throw_player()

	if held_player != null:
		_update_held_player()

func _update_freefall_camera(delta: float) -> void:
	if not is_falling or is_ragdoll or is_climbing or is_mantling:
		# bleed everything back out
		fall_lean = lerp(fall_lean, 0.0, 8.0 * delta)
		fall_fov_bonus = lerp(fall_fov_bonus, 0.0, 8.0 * delta)
		fall_drift_time = 0.0
		return

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

	
	var fallen = fall_start_y - global_position.y
	var t = clamp((fallen - FALL_ONSET_DISTANCE) / (FALL_FULL_DISTANCE - FALL_ONSET_DISTANCE), 0.0, 1.0)
	t = t * t  # ease in so early fall still feels clean
	
	fall_lean = lerp(fall_lean, FALL_LEAN_MAX * t, 5.0 * delta)
	fall_fov_bonus = lerp(fall_fov_bonus, FALL_FOV_MAX * t, 3.0 * delta)
	
	fall_drift_time += delta * FALL_DRIFT_FREQUENCY

func _handle_falling(delta: float):
	if not is_on_floor() and not is_climbing and not is_mantling:
		if not is_falling:
			is_falling = true
			fall_start_y = global_position.y
		else:
			if just_jumped and pending_jump_mantle_timer <= 0.0:
				var mantle = _try_mantle_jump()
				if not mantle.is_empty():
					pending_jump_mantle = mantle.position + Vector3.UP * MANTLE_DISTANCE
					pending_jump_mantle_timer = 0.2
	else:
		if is_falling:
			pre_impact_velocity = velocity
			fall_distance = fall_start_y - global_position.y
			if fall_distance > RAGDOLL_FALL_THRESHOLD:
				rpc("_sync_start_ragdoll")
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
	
	anim_tree.set("parameters/conditions/freefall", is_falling and !jumped_while_sprinting and !just_jumped)
	
	anim_tree.set("parameters/conditions/crouch", is_crouching)
	anim_tree.set("parameters/conditions/uncrouch", !is_crouching)
	
	var state_crouch = _get_direction_state_crouch()
	var all_states_crouch = ["crouchidle","crouchforward", "crouchback", "crouchleft", "crouchright"]
	for c in all_states_crouch:
		anim_tree.set("parameters/crouch/conditions/" + c, c == str(state_crouch))
	
	anim_tree.set("parameters/climb/conditions/hang",is_hanging)
	anim_tree.set("parameters/climb/conditions/not_hang",!is_hanging)
	
	anim_tree.set("parameters/conditions/fell",!is_falling)
	
	anim_tree.set("parameters/conditions/mantle",is_mantling)
	
	anim_tree.set("parameters/conditions/climbing",is_climbing)
	anim_tree.set("parameters/conditions/not_climbing",!is_climbing)
	
	
	if wall_lunge_triggered:
		anim_tree.set("parameters/climb/conditions/lounge",true)
		wall_lunge_triggered = false
	else:
		anim_tree.set("parameters/climb/conditions/lounge",false)
	
	var climbing_state = _get_direction_climb()
	var all_climb_crouch = ["vel_climb","novel_climb"]
	for c in all_climb_crouch:
		anim_tree.set("parameters/climb/conditions/" + c, c == str(climbing_state))
	
	anim_tree.set("parameters/climb/climb/TimeScale/scale",_get_climb_speed_modifier())
	
	anim_tree.set("parameters/conditions/hardwalk", uphill_bob_blend > 0.5)
	anim_tree.set("parameters/conditions/nohardwalk", uphill_bob_blend < 0.5)
	
	if emote_anim != "null":
		_disable_all_emotes()
		anim_tree.set("parameters/conditions/emote_end",false)
		anim_tree.set("parameters/conditions/"+str(emote_anim),true)
	else:
		_disable_all_emotes()
		anim_tree.set("parameters/conditions/emote_end",true)
		

func _disable_all_emotes():
	var emote_anims = ["no_anim", "point_anim", "facepalm", "sixseven", "like_anim"]
	for i in emote_anims:
		anim_tree.set("parameters/conditions/"+str(i), false)
	
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
	if flat.length() < 0.1:
		return "crouchidle"
	if abs(flat.y) > abs(flat.x):
		return "crouchforward" if flat.y > 0 else "crouchback"
	else:
		return "crouchright" if flat.x > 0 else "crouchleft"

func _get_direction_climb() -> String:
	if climb_input_anim_cache.length() < 0.1:
		return "novel_climb"
	return "vel_climb"

func _handle_screen_fx(delta):
	if is_ragdoll:
		pass
	elif is_recovering or recovery_linger:
		ragdoll_vignette = lerp(ragdoll_vignette, 0.0, 1.0 * delta)
	else:
		ragdoll_vignette = lerp(ragdoll_vignette, 0.0, 2.8 * delta)
	
	small_error_shake_value = lerp(small_error_shake_value, 0.0, 18.0 * delta)
	
	if is_instance_valid(screen_fx_material):
		screen_fx_material.set_shader_parameter("aberration", climb_shake_blend * 0.18)
		screen_fx_material.set_shader_parameter("vignette_intensity", climb_shake_blend * 0.54 + ragdoll_vignette)
		screen_fx_material.set_shader_parameter("shake_strength", climb_shake_blend * 0.06)
		screen_fx_material.set_shader_parameter("fast_shake_intensity",small_error_shake_value)

func _update_slope_modifier(delta: float) -> void:
	if not is_on_floor():
		slope_speed_modifier = lerp(slope_speed_modifier, 1.0, SLOPE_MODIFIER_LERP * delta)
		slope_steepness = lerp(slope_steepness, 0.0, SLOPE_MODIFIER_LERP * delta)
		return

	var floor_n = get_floor_normal()
	var move_dir = Vector2(velocity.x, velocity.z)

	if move_dir.length() < 0.01:
		slope_speed_modifier = lerp(slope_speed_modifier, 1.0, SLOPE_MODIFIER_LERP * delta)
		slope_steepness = lerp(slope_steepness, 0.0, SLOPE_MODIFIER_LERP * delta)
		return

	# Project floor normal onto horizontal move direction to get uphill component
	var move_dir_3d = Vector3(move_dir.x, 0.0, move_dir.y).normalized()
	var uphill_dot = -floor_n.dot(move_dir_3d)  # negative because normal points away from slope
	# uphill_dot > 0 means moving uphill, < 0 means downhill

	var uphill_t = clamp((uphill_dot - SLOPE_UPHILL_THRESHOLD) / (1.0 - SLOPE_UPHILL_THRESHOLD), 0.0, 1.0)
	var target_modifier = lerp(1.0, SLOPE_SPEED_MIN, uphill_t)

	slope_steepness = lerp(slope_steepness, uphill_t, SLOPE_MODIFIER_LERP * delta)
	slope_speed_modifier = lerp(slope_speed_modifier, target_modifier, SLOPE_MODIFIER_LERP * delta)

func _handle_water_render(delta):
	var tile = (Vector3(global_position.x, 0.0, global_position.z) / clipmap_tile_size).ceil()
	if not tile.is_equal_approx(previous_tile):
		water.global_position = tile * clipmap_tile_size
		previous_tile = tile

func _find_platform_below() -> ShipRoot:
	if not is_on_floor():
		return null

	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.05,
		global_position + Vector3.DOWN * 0.3
	)
	params.exclude = [self]
	var hit = space.intersect_ray(params)

	if hit.is_empty():
		return null
	if hit.collider is AnimatableBody3D and hit.collider.get_parent() is ShipRoot:
		return hit.collider.get_parent()
	return null

func _update_platform_tracking(delta: float) -> void:
	var found_ship: ShipRoot = _find_platform_below()
	var found_offset: Vector3 = Vector3.ZERO
	if found_ship != null:
		found_offset = global_position - found_ship.global_position

	var is_on_platform_now = found_ship != null

	# ENTER
	if is_on_platform_now and not was_on_platform:
		current_platform = found_ship
		platform_local_offset = found_offset

	# STAYING ON IT
	elif is_on_platform_now and was_on_platform:
		platform_local_offset = found_offset

	# EXIT — carry the momentum instead of dropping it
	elif not is_on_platform_now and was_on_platform:
		velocity += platform_velocity
		current_platform = null

	# refresh platform_velocity / angular from live ship data
	if current_platform != null:
		platform_angular_velocity = current_platform.angular_velocity
		platform_velocity = current_platform.velocity + current_platform.angular_velocity.cross(platform_local_offset)
	else:
		platform_velocity = Vector3.ZERO
		platform_angular_velocity = Vector3.ZERO

	local_velocity = velocity - platform_velocity
	
	was_on_platform = is_on_platform_now


func _physics_process(delta: float) -> void:
	_update_head_tilt(delta)
	_update_eye_look(delta)
	_update_anim_properties()
	_update_blink(delta)
	if is_ragdoll:
		_close_eyes()
	
	if !is_multiplayer_authority():
		return
	
	_handle_water_render(delta)
	
	_handle_screen_fx(delta)
	_update_body_rotation(delta)
	_update_object_pickup(delta)
	
	_update_slope_modifier(delta)
	
	debug_velocity.text = (str(velocity.length()))
	
	if is_held:
		velocity = Vector3.ZERO
		rotation.y = lerp_angle(rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
		global_position = global_position.lerp(hold_target_position, 8.0 * delta)
		_handle_camera_mount_rotation(delta)
		_update_bob(delta)
		if held_player != null and !inputs_blocked:
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
		
		if ragdoll_timer >= RAGDOLL_MIN_DURATION:
			if Vector2(spd.x, spd.z).length() < RAGDOLL_SETTLE_SPEED and abs(spd.y) < RAGDOLL_SETTLE_SPEED:
				if ragdoll_recovery_timer < 0.0:
					ragdoll_recovery_timer = RAGDOLL_RECOVERY_TIME
			if ragdoll_recovery_timer > 0.0:
				ragdoll_recovery_timer -= delta
				if ragdoll_recovery_timer <= 0.0:
					rpc("_sync_stop_ragdoll")
		return
	
	_count_idle_time(delta)
	
	#FALLING
	_handle_falling(delta)
	_update_freefall_camera(delta)
	

	if ragdoll_smoothing_timer > 0.0:
		ragdoll_smoothing_timer -= delta
	
	if small_error_shake_cooldown > 0.0:
		small_error_shake_cooldown -= delta
	
	if emote_anim_grace <= EMOTE_ANIM_GRACE:
		emote_anim_grace += delta
	
	wall_lunge_fov_punch = lerp(wall_lunge_fov_punch, 0.0, WALL_LUNGE_FOV_DECAY * delta)

	var tilt_result = _spring(wall_lunge_cam_tilt, 0.0, wall_lunge_tilt_velocity, 32.0, 3.8, delta)
	wall_lunge_cam_tilt     = tilt_result[0]
	wall_lunge_tilt_velocity = tilt_result[1]

	var pitch_result = _spring(wall_lunge_cam_pitch, 0.0, wall_lunge_pitch_velocity, 32.0, 3.8, delta)
	wall_lunge_cam_pitch      = pitch_result[0]
	wall_lunge_pitch_velocity = pitch_result[1]
	
	if is_climbing or is_hanging:
		climb_shake_fov = -climb_shake_blend * 6.8
	else:
		climb_shake_fov = lerp(climb_shake_fov, 0.0, 6.0 * delta)
	
	
	var target_fov = (FOV_SPRINT if is_sprinting else (FOV_CLIMB if is_climbing else FOV_DEFAULT)) \
	+ fall_fov_bonus - landing_fov_dip - recovery_fov_dip + wall_lunge_fov_punch + climb_shake_fov
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
	_update_mesh_rotation(delta)
	
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
	
	if is_climbing and jump_buffer_timer > 0.0 and wall_jump_cooldown_timer <= 0.0:
		is_hanging = false
		_wall_jump()
	
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
		var jump_mantle = _try_mantle_jump()
		if not jump_mantle.is_empty():
			pending_jump_mantle = jump_mantle.position + Vector3.UP * MANTLE_DISTANCE
			pending_jump_mantle_timer = 0.2 # GIVING A JUMP TIME TO DEVELOP

	# Movement
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if inputs_blocked:
		input = Vector2.ZERO
	
	if emote_anim != "null" and input != Vector2.ZERO and emote_anim_grace > EMOTE_ANIM_GRACE:
		emote_anim = "null"
		
	
	var input_lerp_speed = lerp(18.0, 12.0, input.length())
	move_input_smooth = move_input_smooth.lerp(input, input_lerp_speed * delta)
	var direction = (transform.basis * Vector3(-move_input_smooth.x, 0, -move_input_smooth.y))
	var forward = global_basis.z
	var dot = direction.dot(forward)
	is_sprinting = Input.is_action_pressed("sprint") and stamina > 0.0 and is_on_floor() and dot > 0.5 and !is_crouching and slope_steepness < SLOPE_SPRINT_BLOCK
	var target_speed = SPRINT_SPEED if (is_sprinting or jumped_while_sprinting) else SPEED
	if is_sprinting or jumped_while_sprinting:
		target_speed = SPRINT_SPEED
	elif is_crouching:
		target_speed = CROUCH_SPEED
	else:
		target_speed = SPEED
	speed_target = lerp(speed_target, target_speed * slope_speed_modifier, 14.0 * delta)

	if is_sprinting:
		stamina = max(stamina - STAMINA_SPRINT_COST * delta, 0.0)
		stamina_regen_timer = STAMINA_REGEN_DELAY
	
	# CROUCH
	var was_crouching = is_crouching
	
	var wants_to_uncrouch = not Input.is_action_pressed("crouch")
	if is_crouching and wants_to_uncrouch:
		if _can_uncrouch():
			is_crouching = false
	elif not is_crouching and Input.is_action_pressed("crouch") and not is_climbing and not is_sprinting and not is_mantling and not inputs_blocked:
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
		
		_update_climb_surface_transform(delta)
		#CLIMB ATTACH
		if is_climb_attaching:
			climb_attach_timer -= delta
			var t_raw = 1.0 - clamp(climb_attach_timer / CLIMB_ATTACH_DURATION, 0.0, 1.0)
			var t = 1.0 - pow(1.0 - t_raw, 3.0)
			global_position = global_position.lerp(climb_attach_target, t * 0.5)
			
			if velocity.y < -1.0:
				velocity.y = lerp(velocity.y, 0.0, t * 0.1)
			
			if climb_attach_timer <= 0.0:
				is_climb_attaching = false
		
		#CLIMB ITSELF
		var hit = _maintain_climb()
		var climbing_input = Vector2(Input.get_axis("move_right", "move_left"), Input.get_axis("move_forward", "move_back"))
		climb_input_anim_cache = climbing_input
		current_wall_normal = current_wall_normal.lerp(climb_wall_normal, 16.0 * delta)
		var right_dir: Vector3
		var up_dir: Vector3
		var up_dot = abs(current_wall_normal.dot(Vector3.UP))
		if up_dot > 0.9:
			# normal is too close to UP, cross product degenerates — use forward as fallback
			right_dir = current_wall_normal.cross(Vector3.FORWARD).normalized()
		else:
			right_dir = current_wall_normal.cross(Vector3.UP).normalized()
		#INSTANT SNAP CORRECTION
		if up_dot > 0.5:
			current_wall_normal = climb_wall_normal
		else:
			current_wall_normal = current_wall_normal.lerp(climb_wall_normal, 8.0 * delta)
		up_dir = right_dir.cross(current_wall_normal).normalized()
		
		if wall_lunge_cooldown_timer > 0.0:
			wall_lunge_cooldown_timer -= delta
		if wall_jump_cooldown_timer > 0.0:
			wall_jump_cooldown_timer -= delta
		
		# WALL LUNGE (sprint impulse, climb continues)
		if Input.is_action_just_pressed("sprint") and climbing_input.length() > 0.1:
			# Check if camera is facing AWAY from the wall
			var cam_fwd_dot = (-camera_mount.global_transform.basis.z).dot(climb_wall_normal)
			var looking_away = cam_fwd_dot < WALL_JUMP_CAM_FACING_THRESHOLD
 
			if looking_away and wall_jump_cooldown_timer <= 0.0:
				is_hanging = false 
				_wall_jump()
 
			elif not looking_away and wall_lunge_cooldown_timer <= 0.0 and stamina >= WALL_LUNGE_STAMINA_COST:
				# === WALL LUNGE (existing behaviour, unchanged) ===
				var lunge_dir = (right_dir * climbing_input.x + up_dir * -climbing_input.y).normalized()
				wall_lunge_boost = lunge_dir * WALL_LUNGE_IMPULSE
				wall_lunge_cooldown_timer = WALL_LUNGE_COOLDOWN
				stamina = max(stamina - WALL_LUNGE_STAMINA_COST, 0.0)
				stamina_regen_timer = STAMINA_REGEN_DELAY
				wall_lunge_triggered = true
 
				wall_lunge_cam_tilt  = climbing_input.x * 0.22
				wall_lunge_cam_pitch = -climbing_input.y * 0.14
				wall_lunge_fov_punch = 14.0
				wall_lunge_nudge_dir = sign(climbing_input.x)
				wall_lunge_cam_nudge = WALL_LUNGE_NUDGE
		
		if not hit.is_empty():
			var desired_pos = hit.position + current_wall_normal * CLIMB_WALL_OFFSET
			desired_pos.y = global_position.y
		
		var effective_climb_speed = climb_speed * _get_climb_speed_modifier()

		if stamina > 0.0:
			
			var has_wall_below: bool = true
			if climbing_input.y > 0.1:
				var space = get_world_3d().direct_space_state
				var params = PhysicsRayQueryParameters3D.new()
				params.exclude = [self]
				params.collision_mask = 1
				# cast along the wall surface downward, not just horizontally
				var surface_down = -up_dir
				var probe_origin = global_position + surface_down * 0.003
				params.from = probe_origin
				params.to = probe_origin + (-climb_wall_normal) * 0.25
				var probe = space.intersect_ray(params)
				if probe.is_empty():
					has_wall_below = false

			# then when assigning velocity, mask the downward component
			var masked_input = climbing_input
			if not has_wall_below:
				masked_input.y = min(masked_input.y, 0.0)
			
			var target_vel = Vector3(
				(right_dir.x * climbing_input.x + up_dir.x * -masked_input.y) * effective_climb_speed,
				(right_dir.y * climbing_input.x + up_dir.y * -masked_input.y) * effective_climb_speed,
				(right_dir.z * climbing_input.x + up_dir.z * -masked_input.y) * effective_climb_speed
			)
			
			velocity = velocity.lerp(target_vel, 12.0 * delta)
			
			velocity += wall_lunge_boost
			velocity.y += climb_attach_boost

			if wall_nudge_timer > 0.0:
				wall_nudge_timer -= delta
				velocity += wall_nudge_dir * WALL_NUDGE_STRENGTH

			stamina = max(stamina - STAMINA_CLIMB_COST * _get_climb_stamina_drain_modifier() * delta, 0.0)
			stamina_regen_timer = STAMINA_REGEN_DELAY
		else:
			if is_climbing:
				# Out of stamina: claw at the wall, then lose grip entirely
				is_hanging = true
				is_climb_attaching = false
				
				velocity.x = 0
				velocity.y = 0
				velocity.z = 0
			
				var drain_rate = _get_hanging_drain_rate(current_wall_normal)
				hanging = max(hanging - drain_rate * delta, 0.0)

			if hanging <= 0.0:
				is_hanging = false
				if not is_falling:
					is_falling = true
					fall_start_y = global_position.y
				_stop_climb()

		wall_lunge_boost = wall_lunge_boost.lerp(Vector3.ZERO, WALL_LUNGE_DECAY * delta)
		climb_attach_boost = lerp(climb_attach_boost, 0.0, CLIMB_ATTACH_BOOST_DECAY * delta)
		
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
		
		if climb_surface != null and is_instance_valid(climb_surface):
			climb_local_offset = climb_surface.to_local(global_position)
		
		
	if is_hanging: 
		direction = Vector3.ZERO
	
	var current_air_accel = SPRINT_AIR_ACCELERATION if jumped_while_sprinting else AIR_ACCELERATION
	var target_accel = ACCELERATION if is_on_floor() else current_air_accel
	var target_decel = DECELERATION if is_on_floor() else AIR_FRICTION
	accel = lerp(accel, target_accel, 12.0 * delta)
	decel = lerp(decel, target_decel, 12.0 * delta)
	momentum_boost = lerp(momentum_boost, 1.0, 2.6 * delta)
	if direction and not is_climbing:
		velocity.x = move_toward(velocity.x, direction.x * speed_target * momentum_boost, accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed_target * momentum_boost, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, decel * delta)
		velocity.z = move_toward(velocity.z, 0, decel * delta)
	
	# JUMPING MANTLES
	if pending_jump_mantle != Vector3.ZERO and not is_mantling:
		pending_jump_mantle_timer -= delta
		if pending_jump_mantle_timer > 0.0:
			pass  # wait
		else:
			var height_diff = pending_jump_mantle.y - global_position.y
			if height_diff < 0.18:
				mantle_target = pending_jump_mantle
				mantle_camera_tilt_target = -0.12
				mantle_camera_tilt = MANTLE_CAMERA_TILT
				is_mantling = true
				mantle_timer = MANTLE_DURATION
				mantle_reacquire_timer = MANTLE_DURATION + 0.4
				pending_jump_mantle = Vector3.ZERO
			elif not is_on_floor() and velocity.y < -0.1:
				pending_jump_mantle = Vector3.ZERO
	
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
	_update_camera_clip()
	move_and_slide()
	if current_platform != null and platform_debug_enabled:
		platform_debug_timer -= delta
		if platform_debug_timer <= 0.0:
			platform_debug_timer = PLATFORM_DEBUG_INTERVAL
			print("--- PLATFORM DEBUG ---")
			print("ship.velocity: ", current_platform.velocity)
			print("player velocity (raw): ", velocity)
			print("platform_velocity (computed): ", platform_velocity)
			print("local_velocity (should be near 0 if standing still): ", local_velocity)
			print("is_on_floor: ", is_on_floor())
			print("built-in platform velocity: ", get_platform_velocity())
	_update_platform_tracking(delta)
	
	if is_climbing:
		_maintain_climb_depth()

		if climb_surface != null and is_instance_valid(climb_surface):
			climb_local_offset = climb_surface.to_local(global_position)
		_sliding_into_walls_check()
		
	_update_stamina(delta)
	_update_hanging(delta)

	# NEW CLIMBING
	var manifold = _try_acquire_wall()

	if !manifold.is_empty() and stamina >= CLIMB_MIN_STAMINA_TO_ATTACH:
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
			if stamina >= CLIMB_MIN_STAMINA_TO_ATTACH:
				climb_wall_normal = acquisition.normal
				stamina = max(stamina - CLIMB_MIN_STAMINA_TO_ATTACH, 0.0)
				_start_climb(acquisition)
			elif small_error_shake_cooldown <= 0:
				_screen_shake(small_error_shake_value)

	if is_climbing:
		if climb_attach_grace_timer > 0.0:
			climb_attach_grace_timer -= delta
		else:
			var manifold_check = _get_wall_manifold()
			if not manifold_check.hit:
				
				var search_hit = _search_for_wall()
				if not search_hit.is_empty():
					prev_wall_normal = climb_wall_normal
					climb_wall_normal = search_hit.normal
					climb_detach_timer = 0.0
					wall_nudge_timer = WALL_NUDGE_DURATION
					wall_nudge_dir = -search_hit.normal
					
					# re-anchor to whatever we found
					if search_hit.has("collider") and is_instance_valid(search_hit.collider):
						climb_surface = search_hit.collider
						climb_local_offset = climb_surface.to_local(global_position)
						climb_local_normal = (climb_surface.global_transform.basis.inverse() * search_hit.normal).normalized()
						climb_surface_prev_transform = climb_surface.global_transform
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
	var origin = global_position + Vector3(0, eye_height_current, 0)
	
	# use the SMOOTH position as the camera intent, not the clipped position
	var cam_intended = camera_smooth_pos  
	var right = camera_mount.global_transform.basis.x * 0.04
	var up = camera_mount.global_transform.basis.y * 0.04
	
	var probes = [cam_intended, cam_intended + right, cam_intended - right, cam_intended + up, cam_intended - up]
	
	var closest_dist = INF
	var closest_safe: Vector3 = cam_intended
	
	for probe in probes:
		var params = PhysicsRayQueryParameters3D.create(origin, probe)
		params.exclude = [self]
		var hit = space.intersect_ray(params)
		if hit:
			var dist = origin.distance_to(hit.position)
			if dist < closest_dist:
				closest_dist = dist
				var ray_dir = (probe - origin).normalized()
				closest_safe = hit.position - ray_dir * 0.05
	
	var delta = get_physics_process_delta_time()
	
	if closest_dist < INF:
		if not cam_clip_active:
			cam_clip_target = closest_safe
			cam_clip_active = true
		else:
			cam_clip_target = cam_clip_target.lerp(closest_safe, 18.0 * delta)
		camera_main.global_position = cam_clip_target
	else:
		cam_clip_active = false
		if not is_ragdoll:
			camera_main.position = camera_main.position.lerp(Vector3.ZERO, 6.0 * delta)

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
	camera_mount.rotation.z = climb_tilt + recovery_tilt_z + move_tilt + wall_lunge_cam_tilt
	
	# strafe tilt — based on actual velocity, not input, so it feels physical
	var local_vel = global_transform.basis.inverse() * velocity
	var strafe_amount = clamp(local_vel.x / SPEED, -1.0, 1.0)
	move_tilt = lerp(move_tilt, strafe_amount * 0.028, 6.0 * delta)
	
	var crouch_tilt_target = -CROUCH_CAMERA_TILT if is_crouching else 0.0
	var crouch_tilt_force = (crouch_tilt_target - crouch_tilt) * 180.0 - crouch_tilt_velocity * 12.0
	crouch_tilt_velocity += crouch_tilt_force * delta
	crouch_tilt += crouch_tilt_velocity * delta
	
	# SPRINT LEAN
	var sprint_lean_target: float
	if jumped_while_sprinting and not is_on_floor():
		sprint_lean_target = -0.058
	elif is_sprinting:
		sprint_lean_target = -0.04
	else:
		sprint_lean_target = 0.0
	sprint_lean = lerp(sprint_lean, sprint_lean_target, 6.0 * delta)
	
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
	camera_mount.rotation.x = lerp_angle(camera_mount.rotation.x, target_rotation_x + climb_camera_tilt + landing_dip_rotation + mantle_camera_tilt + recovery_tilt_x + crouch_tilt + sprint_lean + fall_lean + wall_lunge_cam_pitch, tilt_speed * delta)

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
	
	if current_platform != null:
		platform_angular_velocity = current_platform.angular_velocity
		platform_velocity = current_platform.velocity + current_platform.angular_velocity.cross(platform_local_offset)
		
		camera_smooth_pos += platform_velocity * delta
	else:
		platform_velocity = Vector3.ZERO
		platform_angular_velocity = Vector3.ZERO
	
	if horizontal_speed > 0.1 and is_on_floor():
		var is_sprint_bob = is_sprinting or jumped_while_sprinting
		var bob_freq = SPRINT_BOB_FREQUENCY if is_sprint_bob else WALK_BOB_FREQUENCY
		var amp_y = SPRINT_BOB_AMPLITUDE_Y if is_sprint_bob else WALK_BOB_AMPLITUDE_Y
		var amp_x = SPRINT_BOB_AMPLITUDE_X if is_sprint_bob else WALK_BOB_AMPLITUDE_X
		
		bob_time += delta * bob_freq
		
		bob_offset_y = sin(bob_time) * amp_y * speed_ratio
		bob_offset_x = sin(bob_time * 0.5) * amp_x * speed_ratio
	
	#if horizontal_speed > 0.1 and is_on_floor():
		#var is_sprint_bob = is_sprinting or jumped_while_sprinting
		#var bob_freq = SPRINT_BOB_FREQUENCY if is_sprint_bob else WALK_BOB_FREQUENCY
		#var amp_y = SPRINT_BOB_AMPLITUDE_Y if is_sprint_bob else WALK_BOB_AMPLITUDE_Y
		#var amp_x = SPRINT_BOB_AMPLITUDE_X if is_sprint_bob else WALK_BOB_AMPLITUDE_X
		#
		#bob_time += delta * bob_freq
		#
		#bob_offset_y = sin(bob_time) * amp_y * speed_ratio
		#bob_offset_x = sin(bob_time * 0.5) * amp_x * speed_ratio
	var wants_uphill_bob = is_on_floor() and horizontal_speed > 0.1 and slope_steepness >= UPHILL_BOB_THRESHOLD
	uphill_bob_blend = lerp(uphill_bob_blend, 1.0 if wants_uphill_bob else 0.0, UPHILL_BOB_BLEND_SPEED * delta)

	if uphill_bob_blend > 0.001:
		uphill_bob_time += delta * UPHILL_BOB_FREQUENCY * uphill_bob_blend
		
		var raw_y = sin(uphill_bob_time)
		
		# gentle sine, just slightly weighted low — no sharp shaping
		var shaped_y = raw_y - 0.18   # bias downward without punchy curves
		
		var forward_nod = max(0.0, -raw_y) * 0.005   # softer lean, no pow spike
		
		bob_offset_y += shaped_y * UPHILL_BOB_AMPLITUDE_Y * uphill_bob_blend
		bob_offset_x += sin(uphill_bob_time * 0.5) * UPHILL_BOB_AMPLITUDE_X * uphill_bob_blend
		bob_offset_z -= forward_nod * uphill_bob_blend
	
	
	var is_idle = idle_check and idle_timer > 1.8 and is_on_floor()
	idle_bob_blend = lerp(idle_bob_blend, 1.0 if is_idle else 0.0, delta)
	
	if idle_bob_blend > 0.001:
		
		idle_bob_time += delta * IDLE_BREATHE_FREQUENCY * idle_bob_blend
		
		# asymmetric breathe — slow rise (inhale), quicker fall (exhale)
		var breathe = sin(idle_bob_time * TAU)
		var breathe_asymmetric = breathe - sin(idle_bob_time * TAU * 2.0) * 0.18
		
		bob_offset_y += breathe_asymmetric * IDLE_BREATHE_AMPLITUDE_Y * idle_bob_blend
		bob_offset_x += sin(idle_bob_time * TAU + 0.6) * IDLE_BREATHE_AMPLITUDE_X * idle_bob_blend
		bob_offset_z += cos(idle_bob_time * TAU * 0.9) * IDLE_BREATHE_AMPLITUDE_Z * idle_bob_blend

	if camera_attach_smooth_timer > 0.0:
		camera_attach_smooth_timer -= delta

	if is_falling and not is_ragdoll:
		var fallen = fall_start_y - global_position.y
		var t = clamp((fallen - FALL_ONSET_DISTANCE) / (FALL_FULL_DISTANCE - FALL_ONSET_DISTANCE), 0.0, 1.0)
		t = t * t
		var drift_a = sin(fall_drift_time * TAU * 0.7) * 0.8
		var drift_b = sin(fall_drift_time * TAU * 1.3 + 1.1) * 0.5
		var drift_c = sin(fall_drift_time * TAU * 0.4 + 2.4) * 0.3
		bob_offset_y += (drift_a + drift_b + drift_c) * FALL_DRIFT_AMPLITUDE * t
		bob_offset_x += sin(fall_drift_time * TAU * 0.9 + 0.8) * FALL_DRIFT_AMPLITUDE * 1.2 * t
		bob_offset_z += cos(fall_drift_time * TAU * 0.5 + 0.4) * FALL_DRIFT_AMPLITUDE * 0.7 * t
	
	if is_climbing and not is_climb_attaching:
		var climb_speed_t = clamp(climb_input_anim_cache.length(), 0.0, 1.0)
		var speed_mod = _get_climb_speed_modifier() * 1.4
		climb_bob_blend = lerp(climb_bob_blend, climb_speed_t * speed_mod, 6.0 * delta)
		climb_bob_time += delta * CLIMB_BOB_FREQUENCY * climb_bob_blend
		
		# sharpen the vertical — quick pull, slow settle
		var raw_y = sin(climb_bob_time)
		var t_y = (raw_y + 1.0) * 0.5                        # remap to 0..1            # square root curve = fast up, slow down
		var shaped_y = pow(t_y, 0.78) * 2.0 - 1.0    # was 0.5, softer curve
		
		# alternating hand sway — sign flips every half cycle
		var hand_side = sin(climb_bob_time * 0.5)
		var hand_t = pow(max(0.0, sin(climb_bob_time)), 1.4)
		var hand_sway = hand_side * hand_t * CLIMB_BOB_AMPLITUDE_X * 1.0
		
		bob_offset_y += shaped_y * CLIMB_BOB_AMPLITUDE_Y * climb_bob_blend
		bob_offset_x += (sin(climb_bob_time * 0.5) * CLIMB_BOB_AMPLITUDE_X + hand_sway * 0.4) * climb_bob_blend
		bob_offset_z += sin(climb_bob_time + 0.9) * 0.007 * climb_bob_blend
	else:
		climb_bob_blend = lerp(climb_bob_blend, 0.0, 8.0 * delta)
	
	# CLIMB STAMINA TREMOR
	if is_climbing or is_hanging:
		var target_shake = _get_climb_shake_strength()
		climb_shake_blend = lerp(climb_shake_blend, target_shake, 4.0 * delta)
		if climb_shake_blend > 0.001:
			climb_shake_time += delta * CLIMB_SHAKE_FREQUENCY
			# tight high-freq tremor on two slightly offset phases — feels like muscle shake
			# Y: golden ratio second layer breaks the metronomic feel
			bob_offset_y += (sin(climb_shake_time) * 0.7 + sin(climb_shake_time * 1.618) * 0.3) \
				* CLIMB_SHAKE_AMPLITUDE_Y * climb_shake_blend
			
			bob_offset_x += sin(climb_shake_time * 1.05 + 1.3) \
				* CLIMB_SHAKE_AMPLITUDE_X * climb_shake_blend
			
			# Z: slow grip-strain roll
			bob_offset_z += sin(climb_shake_time * 0.27 + 0.9) \
				* CLIMB_SHAKE_AMPLITUDE_Z * climb_shake_blend
	else:
		climb_shake_blend = lerp(climb_shake_blend, 0.0, 6.0 * delta)
	
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
	
	var target_pos = global_position + Vector3(0, eye_height_current, 0)

	var xz_speed = smooth_speed
	var y_speed = smooth_speed
	
	
	#NEEDED TO SPEED LERP SPEED DURING THE TERMINAKL VELOCITIES
	var fall_catchup = clamp(-velocity.y / abs(TERMINAL_VELOCITY), 0.0, 1.0)
	y_speed = lerp(y_speed, 64.0, fall_catchup)
	
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
	var bob_local = camera_mount.global_transform.basis * Vector3(bob_offset_x, bob_offset_y, bob_offset_z)
	camera_mount.global_position = camera_smooth_pos + bob_local

func _spring(current: float, target: float, velocity: float, stiffness: float, damping: float, delta: float) -> Array:
	var force = (target - current) * stiffness - velocity * damping
	velocity += force * delta
	current += velocity * delta
	return [current, velocity]

func _screen_shake(strength: float):
	small_error_shake_cooldown = SMALL_ERROR_SHAKE_COOLDOWN
	small_error_shake_value = 1.0

func _notify_teleport_if_remote() -> void:
	if !is_multiplayer_authority():
		tick_interpolator.teleport()

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name == "facepalm":
		emote_anim = "null"
