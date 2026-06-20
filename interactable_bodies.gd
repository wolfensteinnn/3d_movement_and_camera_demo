extends RigidBody3D
class_name InteractableObject

@export var object_name: String = "Object"
@export var can_be_pushed: bool = true
@export var can_be_held: bool = true


const HOLD_FORCE = 15.0
const HOLD_DAMPING = 8.0
const MAX_HOLD_DISTANCE = 3.0

var is_held: bool = false
var hold_target: Node3D = null
var holder_original_authority: int = 1

func _enter_tree() -> void:
	set_multiplayer_authority(1)

func _ready() -> void:
	if not is_multiplayer_authority():
		freeze = true

func _physics_process(delta: float) -> void:
	if not is_held or hold_target == null:
		return
	if not is_multiplayer_authority():
		return

	var to_target = hold_target.global_position - global_position
	var distance = to_target.length()

	if distance > MAX_HOLD_DISTANCE:
		_do_release()
		return

	var spring_force = to_target * HOLD_FORCE
	var damping_force = -linear_velocity * HOLD_DAMPING
	apply_central_force((spring_force + damping_force))
	angular_velocity = angular_velocity.lerp(Vector3.ZERO, 5.0 * delta)

# In interactable_object.gd

@rpc("any_peer", "reliable")
func request_grab(holder_id: int, holder_node_path: NodePath) -> void:
	_do_grab(holder_id, holder_node_path)

func _do_grab(holder_id: int, holder_node_path: NodePath) -> void:
	if is_held or not can_be_held:
		return
	holder_original_authority = get_multiplayer_authority()
	set_multiplayer_authority(holder_id)
	freeze = false
	is_held = true
	gravity_scale = 0.1
	var holder = get_node(holder_node_path)
	hold_target = holder.hold_point

@rpc("any_peer", "reliable")  
func request_release() -> void:
	_do_release()

func _do_release() -> void:
	is_held = false
	hold_target = null
	angular_velocity = Vector3.ZERO
	gravity_scale = 1.0
	set_multiplayer_authority(holder_original_authority)
