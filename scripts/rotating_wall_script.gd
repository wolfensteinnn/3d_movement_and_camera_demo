extends CSGBox3D

@export var rotation_speed: Vector3 = Vector3(5.0, 0, 0.0)

func _process(delta: float) -> void:
	rotation_degrees += rotation_speed * delta
