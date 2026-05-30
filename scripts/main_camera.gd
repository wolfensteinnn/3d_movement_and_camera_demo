extends Camera3D

## Sensitivity of camera movement
@export var sensitivity: float = 1.0
## How quickly the camera smooths to the target rotation
@export var smoothing: float = 16.0
## Vertical look angle limit in degrees
@export var camera_limits: float = 55.0
## Default offset of the camera from the pivot point
@export var default_camera_offset: Vector3 = Vector3(0, 1.2, -1.0)
## Collision mask to ignore the player layer
@export_flags_3d_physics var ignored_player_layer: int

@onready var player_transform: Node3D = $"../Player"

var target_yaw: float = 0.0
var target_pitch: float = 0.0
var yaw: float = 0.0
var pitch: float = 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var look_input: Vector2 = event.relative

		target_yaw += look_input.x * sensitivity * 0.01
		target_pitch -= look_input.y * sensitivity * 0.01
		target_pitch = clamp(target_pitch, -camera_limits, camera_limits)


func _process(delta: float) -> void:
	yaw = lerp(yaw, target_yaw, smoothing * delta)
	pitch = lerp(pitch, target_pitch, smoothing * delta)

	rotation_degrees = Vector3(pitch, yaw, 0.0)
	global_position = player_transform.global_position

	var desired_cam_position: Vector3 = to_global(default_camera_offset)
	var direction: Vector3 = (desired_cam_position - global_position).normalized()
	var distance: float = global_position.distance_to(desired_cam_position)

	# Invert the layer mask to exclude the player layer (mirrors ~IgnoredPlayerLayer)
	var collision_mask: int = ~ignored_player_layer

	var space_state := get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = 0.15

	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis.IDENTITY, global_position)
	params.motion = direction * distance
	params.collision_mask = collision_mask

	var result = space_state.cast_motion(params)

	# result[0] is the safe fraction (no collision), result[1] is the unsafe fraction
	if result[0] < 1.0:
		global_position = global_position + direction * distance * result[0]
	else:
		global_position = desired_cam_position
