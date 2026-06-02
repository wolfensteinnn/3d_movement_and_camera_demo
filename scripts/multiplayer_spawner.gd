extends MultiplayerSpawner

@onready var stamina_bar: ProgressBar = $"../StaminaBar"
@onready var velocity_debug: Label = $"../velocityDebug"
@export var player: PackedScene
@onready var cursor: TextureRect = $"../Cursor"

func _init() -> void:
	spawn_function = _spawn_custom

func _spawn_custom(data: Variant) -> Node:
	var scene = player.instantiate()
	scene.name = str(data.peer_id)
	scene.initial_transform = data.initial_transform
	scene._set_debug_velocityLabel(velocity_debug)
	scene._set_stamina_bar(stamina_bar)
	scene._set_cursor(cursor)
	
	#ANY FUCNTION OR INIT OR SETUP

	return scene
