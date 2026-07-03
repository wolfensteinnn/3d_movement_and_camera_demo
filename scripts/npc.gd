extends CharacterBody3D
class_name Npc_Char
@onready var meshes: Skeleton3D = $duck_wholebody_transform/duck/Armature/Skeleton3D
@onready var hit_detector: Area3D = $HitDetector


@onready var duck_mesh: Node3D = $duck_wholebody_transform

#FOR CUSTOM MULTIPLAYER SPAWNING
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

#SPRINT
const SPRINT_SPEED = 0.48
var is_sprinting: bool = false

# SLOPE MOVEMENT
var slope_speed_modifier: float = 1.0        # read this in animation system
var slope_steepness: float = 0.0             # 0 = flat, 1 = max uphill (read for anims)
const SLOPE_SPEED_MIN = 0.32                 # how slow at max uphill angle
const SLOPE_UPHILL_THRESHOLD = 0.08          # dot product before slowdown kicks in
const SLOPE_MODIFIER_LERP = 8.0              # smoothing speed
const SLOPE_SPRINT_BLOCK = 0.3               # steepness above which sprint is cut

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


#MOVING OBJECTS
var held_object: InteractableObject = null

@onready var collision_normal: CollisionShape3D = $CollisionShape3D

@onready var collision_ragdoll: RigidBody3D = $Ragdoll

# ANIMATIONS
@onready var anim_tree: AnimationTree = $duck_wholebody_transform/duck/AnimationTree


# BLINKING
@onready var eyes: MeshInstance3D = $duck_wholebody_transform/duck/Armature/Skeleton3D/eyes
var blink_timer: float = 0.0
var blink_interval: float = 0.0
var blink_value: float = 0.0
var is_blinking: bool = false
const BLINK_SPEED_CLOSE = 18.0
const BLINK_SPEED_OPEN = 10.0

# NETCODE
@onready var tick_interpolator: TickInterpolator = $TickInterpolator

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
	
	velocity = Vector3.ZERO
	_reset_blink_timer()
	hit_detector.body_entered.connect(_on_hit)
	global_position = initial_transform
	
	# IS_SERVER() IS A HOST PEER
	if not multiplayer.is_server():
		tick_interpolator.enabled = true
		tick_interpolator.enable_recording = true

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
	
	is_falling = false
	
	_notify_teleport_if_remote()

func _stop_ragdoll() -> void:
	is_falling = false
	fall_distance = 0.0
	
	var recovery_pos = collision_ragdoll.global_position 
	
	is_ragdoll = false
	collision_ragdoll.linear_velocity = Vector3.ZERO
	collision_ragdoll.angular_velocity = Vector3.ZERO
	collision_ragdoll.freeze = true
	collision_ragdoll.top_level = false
	collision_normal.set_deferred("disabled",false)
	velocity = Vector3.ZERO
	global_position = recovery_pos

	ragdoll_timer = 0.0
	ragdoll_recovery_timer = -1.0
	ragdoll_smoothing_timer = RAGDOLL_SMOOTHING_TIMER 
	
	
	var ragdoll_yaw = collision_ragdoll.global_transform.basis.get_euler().y
	rotation = Vector3(0.0, ragdoll_yaw, 0.0)
	
	_notify_teleport_if_remote()

func _on_hit(body: Node3D):
	if not multiplayer.is_server():
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

@rpc("any_peer", "reliable")
func set_held(held: bool, holder_id: int) -> void:
	is_held = held
	holder_authority = holder_id
	if not held:
		holder_authority = -1

@rpc("any_peer", "unreliable_ordered")
func receive_hold_position(pos: Vector3):
	if is_held and multiplayer.is_server():
		hold_target_position = pos
		velocity = Vector3.ZERO

@rpc("any_peer", "reliable")
func receive_throw(throw_velocity: Vector3) -> void:
	if multiplayer.is_server():
		rpc("_sync_start_ragdoll", throw_velocity)


func _update_anim_properties():
	var local_velocity = global_transform.basis.inverse() * velocity
	var flat_velocity = Vector2(local_velocity.x, local_velocity.z)
	var speed = flat_velocity.length()
	
	anim_tree.set("parameters/conditions/run", speed > 0.1 and !is_sprinting)
	anim_tree.set("parameters/conditions/idle", speed <= 0.1)
	anim_tree.set("parameters/conditions/sprint", is_sprinting)
	
	
	anim_tree.set("parameters/conditions/ragdoll",is_ragdoll)
	anim_tree.set("parameters/conditions/recovery",!is_ragdoll)
	
	var state = _get_direction_state()
	var all_states = ["runforward", "runback", "runleft", "runright"]
	for s in all_states:
		anim_tree.set("parameters/run/conditions/" + s, s == str(state))
	
	anim_tree.set("parameters/conditions/fell",!is_falling)
	
func _get_direction_state() -> String:
	var local_velocity = global_transform.basis.inverse() * velocity
	var flat = Vector2(local_velocity.x, local_velocity.z)
	if abs(flat.y) > abs(flat.x):
		return "runforward" if flat.y > 0 else "runback"
	else:
		return "runright" if flat.x > 0 else "runleft"


func _handle_falling(delta: float):
	if not is_on_floor():
		if not is_falling:
			is_falling = true
			fall_start_y = global_position.y
	else:
		if is_falling:
			pre_impact_velocity = velocity
			fall_distance = fall_start_y - global_position.y
			if fall_distance > RAGDOLL_FALL_THRESHOLD:
				rpc("_sync_start_ragdoll")
				return

func _am_i_sprinting() -> bool:
	# нужно решать когда спринтить - можно сделать облегченную систему со стаминой / паникой etc
	return false


func _physics_process(delta: float) -> void:
	_update_anim_properties()
	_update_blink(delta)
	if is_ragdoll:
		_close_eyes()
	
	if not multiplayer.is_server():
		return
	
	if is_held:
		velocity = Vector3.ZERO
		# MAX 
		# target_rotations 
		#rotation.y = lerp_angle(rotation.y, target_rotation_y, LOOK_SMOOTHING * delta)
		global_position = global_position.lerp(hold_target_position, 8.0 * delta)
	
	#RAGDOLL
	if is_ragdoll:
		ragdoll_timer += delta
		var spd = collision_ragdoll.linear_velocity
		global_position = collision_ragdoll.global_position
		rotation = collision_ragdoll.rotation
		
		if ragdoll_timer >= RAGDOLL_MIN_DURATION:
			if Vector2(spd.x, spd.z).length() < RAGDOLL_SETTLE_SPEED and abs(spd.y) < RAGDOLL_SETTLE_SPEED:
				if ragdoll_recovery_timer < 0.0:
					ragdoll_recovery_timer = RAGDOLL_RECOVERY_TIME
			if ragdoll_recovery_timer > 0.0:
				ragdoll_recovery_timer -= delta
				if ragdoll_recovery_timer <= 0.0:
					rpc("_sync_stop_ragdoll")
		return
	
	
	#FALLING
	_handle_falling(delta)
	

	if ragdoll_smoothing_timer > 0.0:
		ragdoll_smoothing_timer -= delta
	
	# Gravity
	if not is_on_floor():
		
		var fall_t = clamp(inverse_lerp(1.0, -2.6, velocity.y), 0.0, 1.0)
		fall_t = fall_t * fall_t  # ease-in for hang time at apex
		var grav = lerp(GRAVITY_UP, GRAVITY_DOWN, fall_t)
		velocity.y += grav * delta
		velocity.y = max(velocity.y, TERMINAL_VELOCITY)

	# Movement
	# MAX 2) 
	var direction = (transform.basis * Vector3(-move_input_smooth.x, 0, -move_input_smooth.y))
	var forward = global_basis.z
	is_sprinting = _am_i_sprinting()
	var target_speed
	if is_sprinting:
		target_speed = SPRINT_SPEED
	else:
		target_speed = SPEED
	speed_target = lerp(speed_target, target_speed * slope_speed_modifier, 14.0 * delta)

	if is_sprinting:
		# MAX 3)
		pass
	
	var current_air_accel = AIR_ACCELERATION
	var target_accel = ACCELERATION if is_on_floor() else current_air_accel
	var target_decel = DECELERATION if is_on_floor() else AIR_FRICTION
	accel = lerp(accel, target_accel, 12.0 * delta)
	decel = lerp(decel, target_decel, 12.0 * delta)
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * speed_target, accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed_target, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, decel * delta)
		velocity.z = move_toward(velocity.z, 0, decel * delta)

	move_and_slide()

func _notify_teleport_if_remote() -> void:
	if not multiplayer.is_server():
		tick_interpolator.teleport()
