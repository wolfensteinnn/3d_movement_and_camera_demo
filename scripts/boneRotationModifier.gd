@tool
class_name BoneRotationModifier3D
extends SkeletonModifier3D

@export var bone_name: String = ""
@export var bone_rotation_degrees: Vector3 = Vector3.ZERO

func _enter_tree() -> void:
	notify_property_list_changed()

func _validate_property(property: Dictionary) -> void:
	if property.name == &"bone_name":
		var skeleton := get_skeleton()
		if not skeleton:
			return
		var names: Array[String] = []
		for i in range(skeleton.get_bone_count()):
			names.append(skeleton.get_bone_name(i))
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = ",".join(names)

func _process_modification() -> void:
	var skeleton := get_skeleton()
	if not skeleton:
		return
	var bone_idx := skeleton.find_bone(bone_name)
	if bone_idx == -1:
		return

	# Read whatever rotation is already there (from their modifier)
	var current_rotation = skeleton.get_bone_pose_rotation(bone_idx)
	
	# Build our extra rotation and multiply on top
	var extra := Quaternion.from_euler(bone_rotation_degrees * PI / 180.0)
	skeleton.set_bone_pose_rotation(bone_idx, current_rotation * extra)
