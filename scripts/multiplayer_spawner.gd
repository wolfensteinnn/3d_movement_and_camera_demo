extends MultiplayerSpawner

@onready var stamina_bar: ProgressBar = $"../StaminaBar"
@onready var hanging_bar: ProgressBar = $"../HangingBar"
@onready var velocity_debug: Label = $"../velocityDebug"
@export var player: PackedScene
@onready var cursor: TextureRect = $"../Cursor"
@onready var a_shader: ColorRect = $"../CanvasLayer/ColorRect"
@onready var emote_wheel: Control = $"../UiEmoteWheel"
@onready var water: MeshInstance3D = $"../Water"




func _init() -> void:
	spawn_function = _spawn_custom

func _spawn_custom(data: Variant) -> Node:
	var scene = player.instantiate()
	scene.name = str(data.peer_id)
	scene.initial_transform = data.initial_transform
	scene._set_water(water)
	scene._ui_setup(emote_wheel)
	scene._set_debug_velocityLabel(velocity_debug)
	scene._set_stamina_bar(stamina_bar)
	scene._set_hanging_bar(hanging_bar)
	scene._set_cursor(cursor)
	scene._set_screen_fx(a_shader)
	#ANY FUCNTION OR INIT OR SETUP

	return scene
