extends Control

@onready var wheel: TextureRect = $TextureRect

var states: Array = [ preload("res://ui/emote_wheel_base.png"), 
preload("res://ui/emote_wheel_0.png"),
preload("res://ui/emote_wheel_1.png"),
preload("res://ui/emote_wheel_2.png"),
preload("res://ui/emote_wheel_3.png"),
preload("res://ui/emote_wheel_4.png")]

@onready var control_1: Control = $Control2
@onready var control_2: Control = $Control3
@onready var control_3: Control = $Control4
@onready var control_4: Control = $Control5
@onready var control_5: Control = $Control

var chosen_segment: int = -1
var target_segment: int = -1

var active: bool = false

func _ready() -> void:
	var controls = [control_1, control_2, control_3, control_4, control_5]
	for i in controls.size():
		controls[i].mouse_entered.connect(_on_mouse_entered.bind(i+1))
		controls[i].mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered(an_id):
	chosen_segment = an_id
	target_segment = an_id
	wheel.material.set_shader_parameter("texture_b", states[an_id])
	wheel.material.set_shader_parameter("blend", 0.0)
	tween_blend()

func tween_blend():
	var t = create_tween()
	t.tween_method(func(v): wheel.material.set_shader_parameter("blend", v), 0.0, 1.0, 0.05)

func _on_mouse_exited():
	chosen_segment = 0
	target_segment = 0
	wheel.material.set_shader_parameter("texture_b", states[0])
	wheel.material.set_shader_parameter("blend", 0.0)
	tween_blend()

func _choose_and_close():
	_deactivate()
	match chosen_segment:
		0:
			return "null"
		1:
			return "no_anim"
		2:
			return "point_anim"
		3:
			return "facepalm"
		4:
			return "sixseven"
		5:
			return "like_anim"
	

func _show():
	if !visible:
		visible = true

func _hide():
	if visible:
		visible = false

func _activate():
	if !active:
		_on_mouse_exited()
		active = true
		Input.set_custom_mouse_cursor(load("res://ui/system_cursor.png"))
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _deactivate():
	if active:
		active = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if active:
		_show()
	else:
		_hide()
