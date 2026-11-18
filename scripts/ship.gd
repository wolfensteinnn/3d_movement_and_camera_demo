extends Node3D
class_name ShipRoot
# ShipRoot script

var velocity = Vector3.ZERO
var angular_velocity = Vector3.ZERO

var force = Vector3.ZERO

@onready var collision_body: AnimatableBody3D = $Collision

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		if force == Vector3.ZERO:
			force = global_transform.basis.z * 78
		else:
			force =Vector3.ZERO

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return  # only the server runs the sim

	var torque = Vector3.ZERO
	# e.g. temporary: gentle forward thrust so you can see it move
		
	velocity = force * delta
	angular_velocity += torque * delta

	# integrate position
	global_position += velocity * delta

	# integrate orientation (angular_velocity in radians/sec around each axis)
	var delta_rotation := Basis.from_euler(angular_velocity * delta)
	global_transform.basis = (delta_rotation * global_transform.basis).orthonormalized()
	
	# force the AnimatableBody3D to actually register the new transform
	collision_body.global_transform = global_transform
