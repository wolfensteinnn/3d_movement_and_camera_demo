extends Node

@onready var wave_manager: Node = $"../WaveManager"



func _ready() -> void:
	wave_manager.set_shore_factor(0)
	wave_manager.set_state(&"super_calm")
	wave_manager.set_wind_direction(15)


func _on_button_4_pressed() -> void:
	wave_manager.set_state(&"rogue_wave_calm")
	await get_tree().create_timer(8.6).timeout
	wave_manager.set_state(&"super_calm")
