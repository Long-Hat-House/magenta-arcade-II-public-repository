class_name CreditsEndgame extends CreditsMenu

@export var _animation:Switch_Oning_Offing_AnimationPlayer
@export var _buttons_animation:Switch_Oning_Offing_AnimationPlayer
@export var _control_to_scroll:Control
@export var _middle_marker:Control
@export var _finish_marker:Control
@export var _base_scroll_speed:float = 2
@export var _acceleration_speed:float = 5

@export_category("Buttons")
@export var _button_pause:Button
@export var _button_back:Button
@export var _button_play:Button
@export var _button_ffw:Button

var finished:bool = false
var _target_speed_ratio:float = 0
var _current_speed_ratio:float = 0

func _ready() -> void:
	super._ready()

	_button_pause.button_down.connect(set_speed_pause)
	_button_back.button_down.connect(set_speed_back)
	_button_play.button_down.connect(set_speed_normal)
	_button_ffw.button_down.connect(set_speed_ffw)

func play_credits() -> void:
	_current_speed_ratio = 0
	_control_to_scroll.position.y = 0
	_animation.set_switch(true)
	await _animation.turned_on

	_buttons_animation.set_switch(true)
	set_speed_normal()
	while !finished:
		await get_tree().process_frame

	_animation.set_switch(false)
	await _animation.turned_off


func set_speed_ratio_target(speed:float):
	_target_speed_ratio = -speed

func set_speed_normal():
	set_speed_ratio_target(1)
	_button_play.set_pressed_no_signal(true)

func set_speed_pause():
	set_speed_ratio_target(0)
	_button_pause.set_pressed_no_signal(true)

func set_speed_ffw():
	set_speed_ratio_target(5)
	_button_ffw.set_pressed_no_signal(true)

func set_speed_back():
	set_speed_ratio_target(-1)
	_button_back.set_pressed_no_signal(true)

func _process(delta: float) -> void:
	if finished: return
	_current_speed_ratio = move_toward(_current_speed_ratio, _target_speed_ratio, delta*_acceleration_speed)

	print("[CREDITS] position %s %s %s" % [_control_to_scroll.size.y, _control_to_scroll.position.y, finished]);

	var max_position:float = 0

	_control_to_scroll.position.y += _base_scroll_speed * _current_speed_ratio * delta

	if _control_to_scroll.position.y > max_position && _target_speed_ratio > 0:
		set_speed_pause()

	if _finish_marker.get_screen_position().y < _middle_marker.get_screen_position().y && _target_speed_ratio < 0:
		_buttons_animation.set_switch(false)
		finished = true
