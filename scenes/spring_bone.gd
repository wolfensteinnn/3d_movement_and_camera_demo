class_name SpringBone3D
extends PhysicalBone3D

var _queued_force: Vector3 = Vector3.ZERO
var _queued_torque: Vector3 = Vector3.ZERO

var _debug_timer: float = 0.0
const DEBUG_INTERVAL = 0.5

func queue_force(f: Vector3) -> void:
	_queued_force += f

func queue_torque(t: Vector3) -> void:
	_queued_torque += t

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# Brake angular velocity directly every frame
	state.angular_velocity *= 0.7

	if _queued_force != Vector3.ZERO:
		state.apply_central_force(_queued_force)
		_queued_force = Vector3.ZERO
	if _queued_torque != Vector3.ZERO:
		state.apply_torque(_queued_torque)
		_queued_torque = Vector3.ZERO
