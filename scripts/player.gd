extends CharacterBody3D
@onready var camera_mount: Node3D = $CameraMount
@onready var camera_main: Camera3D = $CameraMount/Camera3D
@onready var meshes: Node3D = $duckduck/meshes

var debug_velocity

#FOR CUSTOM MULTIPLAYER SPAWNING
var is_master: bool
var initial_transform: Vector3

# MOVEMENT AND PHYSICS
var SPEED = 1.65
var ACCELERATION = 10.0

# GRAVITY
const GRAVITY_UP = -7.0
const GRAVITY_DOWN = -16.0
const GRAVITY_PEAK_THRESHOLD = 1.2  # velocity range considered "at the peak" - SHOULD BE AROUND 70% +- IMO of JUMP_VELOCITY
const GRAVITY_PEAK_MULTIPLIER = 0.4  # how floaty the peak feels

#JUMP
const JUMP_VELOCITY = 1.78
const JUMP_GRACE_TIME = 0.07 #ITS JUST A GUARDRAIL AGAINST ON_THE_FLOOR FRAME INCOSISTENCIES
const JUMP_BUFFER_TIME = 0.12 #ALLOWS US TO MAKE JUMPS SLIGHTLY BEFORE WE TOUCH THE GROUND - FEELS GOOD (FORGIVING)
var jump_grace_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var AIR_ACCELERATION = 3.2
const JUMP_MOMENTUM_BOOST = 1.36  # horizontal velocity multiplier on jump

# LANDING DIP
const LANDING_DIP_STRENGTH = 0.06
const LANDING_DIP_SPEED = 14.0
var landing_dip: float = 0.0
var was_on_floor: bool = true

# CAMERA AND LOOKING
const LOOK_SMOOTHING = 17.0
const MOUSE_SENSITIVITY = 0.002

# CAMERA BOB
const BOB_FREQUENCY = 3.2
const BOB_AMPLITUDE_Y = 0.024
const BOB_AMPLITUDE_X = 0.01
var bob_time: float = 0.0

# LOOK TARGETS
var target_rotation_y: float = 0.0
var target_rotation_x: float = 0.0

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
		
	#THIS IS PURELY FOR UNLOCKING A MOUSE (DEBUG FEATURE) I WILL DELETE IT LATER
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

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
	
	if is_instance_valid(debug_velocity):
		debug_velocity.text = "%.2f" % Vector2(velocity.x, velocity.z).length()
	
	rotation.y = lerp_angle(rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
	camera_mount.rotation.x = lerp_angle(camera_mount.rotation.x, target_rotation_x, LOOK_SMOOTHING * delta)

	# Gravity
	if not is_on_floor():
		jump_grace_timer -= delta
		var grav: float
		if velocity.y > GRAVITY_PEAK_THRESHOLD:
			grav = GRAVITY_UP
		elif velocity.y > -GRAVITY_PEAK_THRESHOLD:
			grav = GRAVITY_UP * GRAVITY_PEAK_MULTIPLIER  # hang time at peak
		else:
			grav = GRAVITY_DOWN  # heavier fall
		velocity.y += grav * delta
	else:
		jump_grace_timer = JUMP_GRACE_TIME

	#CAMERA DIP ON JUMPS
	var on_floor_now = is_on_floor()
	if on_floor_now and not was_on_floor:
		landing_dip = -LANDING_DIP_STRENGTH
	was_on_floor = on_floor_now

	# Jump
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	# Jump
	if jump_buffer_timer > 0.0 and jump_grace_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		velocity.x *= JUMP_MOMENTUM_BOOST
		velocity.z *= JUMP_MOMENTUM_BOOST
		jump_grace_timer = 0.0
		jump_buffer_timer = 0.0


	# Movement
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(-input.x, 0, -input.y)).normalized()
	var accel = ACCELERATION if is_on_floor() else AIR_ACCELERATION
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * SPEED, accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * SPEED, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, accel * delta) if not is_on_floor() else 0
		velocity.z = move_toward(velocity.z, 0, accel * delta) if not is_on_floor() else 0

	move_and_slide()
	_update_bob(delta)

func _update_bob(delta: float) -> void:
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	var speed_ratio = clamp(horizontal_speed / SPEED, 0.0, 1.0)
	if horizontal_speed > 0.1 and is_on_floor():
		bob_time += delta * BOB_FREQUENCY * horizontal_speed
		var target_y = sin(bob_time) * BOB_AMPLITUDE_Y * speed_ratio
		var target_x = cos(bob_time * 0.5) * BOB_AMPLITUDE_X * speed_ratio
		camera_mount.position.y = lerp(camera_mount.position.y, target_y, delta * 10.0)
		camera_mount.position.x = lerp(camera_mount.position.x, target_x, delta * 10.0)
	else:
		camera_mount.position.y = lerp(camera_mount.position.y, 0.0, delta * 10.0)
		camera_mount.position.x = lerp(camera_mount.position.x, 0.0, delta * 10.0)
	
	#CAMERA DIP
	landing_dip = lerp(landing_dip, 0.0, LANDING_DIP_SPEED * delta)
	camera_mount.position.y += landing_dip
