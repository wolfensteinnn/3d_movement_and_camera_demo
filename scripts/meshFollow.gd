extends Node3D

var smooth_pos: Vector3
var smooth_basis: Basis
const POS_SMOOTH = 24.0
const ROT_SMOOTH = 18.0
const POS_DEADZONE = 0.0008

var target_pitch: float = 0.0  # set from player script

func _ready() -> void:
	top_level = true
	smooth_pos = global_position
	smooth_basis = global_basis

func _process(delta: float) -> void:
	var parent = get_parent() as Node3D
	if parent == null:
		return
	
	var target_pos = parent.global_position
	var diff = target_pos - smooth_pos
	if diff.length() > POS_DEADZONE:
		smooth_pos = smooth_pos.lerp(target_pos, POS_SMOOTH * delta)
	
	# follow parent yaw/roll only, pitch applied separately
	smooth_basis = smooth_basis.slerp(parent.global_basis, ROT_SMOOTH * delta)
	
	global_position = smooth_pos
	# apply smooth basis then pitch on top
	global_basis = smooth_basis * Basis(Vector3.RIGHT, target_pitch)
