extends MultiplayerSpawner

@export var npc: PackedScene


func _init() -> void:
	spawn_function = _spawn_custom

func _spawn_custom(data: Variant) -> Node:
	var scene = npc.instantiate()
	scene.initial_transform = data.initial_transform
	#ANY FUCNTION OR INIT OR SETUP

	return scene
