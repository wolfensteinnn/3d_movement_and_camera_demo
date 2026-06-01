extends CharacterBody3D
@onready var camera_mount: Node3D = $CameraMount
@onready var camera_main: Camera3D = $CameraMount/Camera3D
@onready var meshes: Skeleton3D = $duck/Armature/Skeleton3D

var debug_velocity

#UI
var stamina_bar

# FOV AND CAMERA STUFF
const FOV_DEFAULT = 70.0
const FOV_SPRINT = 66.0
const FOV_LERP_SPEED = 8.0
const FOV_CLIMB = 70.0
const CLIMB_TILT_STRENGTH = 0.1
const CLIMB_TILT_SPEED = 6.0
var was_climbing: bool = false #WE NEED THIS TO SNAP ON TRANSITION TO CLIMBING

#FOR CUSTOM MULTIPLAYER SPAWNING
var is_master: bool
var initial_transform: Vector3

# MOVEMENT AND PHYSICS
var SPEED = 0.8
var ACCELERATION = 10.0

# CLIMBING
var is_climbing = false
var climb_speed: float = 1.0
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
const GRAVITY_DOWN = -16.0

const GRAVITY_PEAK_THRESHOLD = 1.0
const GRAVITY_PEAK_MULTIPLIER = 0.4

var gravity_climb: float = 4.0

#JUMP
const JUMP_VELOCITY = 1.48
const JUMP_GRACE_TIME = 0.07
const JUMP_BUFFER_TIME = 0.12
var jump_grace_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var AIR_ACCELERATION = 5.6
const JUMP_MOMENTUM_BOOST = 1.36

# LANDING DIP
const LANDING_DIP_STRENGTH = 0.06
const LANDING_DIP_SPEED = 14.0
var landing_dip: float = 0.0
var was_on_floor: bool = true

# CAMERA AND LOOKING
const LOOK_SMOOTHING = 17.0
const MOUSE_SENSITIVITY = 0.002

# CAMERA BOB
const BOB_FREQUENCY = 4.8
const BOB_AMPLITUDE_Y = 0.036
const BOB_AMPLITUDE_X = 0.01
var bob_time: float = 0.0

# LOOK TARGETS
var target_rotation_y: float = 0.0
var target_rotation_x: float = 0.0

##ANIMATIONS
#@onready var animation_tree: AnimationTree = $duck/AnimationTree


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

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
	
	#FOV
	if is_climbing and not was_climbing:
		camera_main.fov = 62.0  # punch value — tweak this for more/less snap

	var target_fov = FOV_SPRINT if is_sprinting else (FOV_CLIMB if is_climbing else FOV_DEFAULT)
	camera_main.fov = lerp(camera_main.fov, target_fov, FOV_LERP_SPEED * delta)
	was_climbing = is_climbing
	
	if is_instance_valid(debug_velocity):
		debug_velocity.text = "%.2f" % Vector2(velocity.x, velocity.z).length()

	rotation.y = lerp_angle(rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
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
		var wall_normal = get_wall_normal()
		var climbing_input = Vector2(Input.get_axis("move_right", "move_left"), Input.get_axis("move_forward", "move_back"))
		var up_dir = wall_normal.cross(global_basis.x).normalized()
		var right_dir = global_basis.x
		if stamina >= STAMINA_CLIMB_COST:
			velocity  = right_dir * climbing_input.x * climb_speed
			velocity += up_dir * climbing_input.y * climb_speed
			velocity -= wall_normal * 2.0
			stamina = max(stamina - STAMINA_CLIMB_COST, 0.0)
			stamina_regen_timer = STAMINA_REGEN_DELAY
		else:
			is_climbing = false
			velocity  = Vector3.ZERO
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
	
	if is_on_floor():
		_update_bob(delta)
		
	move_and_slide()
	_update_stamina(delta)
	
	if Input.is_action_pressed("climb") and is_on_wall():
		is_climbing = true
	if not Input.is_action_pressed("climb"):
		is_climbing = false
	if not is_on_wall():
		is_climbing = false

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

	# Camera dip
	landing_dip = lerp(landing_dip, 0.0, LANDING_DIP_SPEED * delta)
	camera_mount.position.y += landing_dip
