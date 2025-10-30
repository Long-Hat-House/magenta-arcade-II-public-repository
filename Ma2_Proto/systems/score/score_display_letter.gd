class_name ScoreDisplayLetter extends Control

@export var _letter_label:Label
@export var _shaker:ControlShaker
@export var _shaker_amplitude_curve:Curve
@export var _shaker_frequency_curve:Curve
@export var _animation_player:AnimationPlayer
@export var _to_set_leading_zero_feedback:Control
@export var _intensity_color:Gradient

@export_category("Boost Feedbac")
@export var _to_set_letter_position:Control
@export var _position_multiplier:float = 1
@export var _wave_speed:float = 1
@export var _height_multiplier:float = 1
@export var _force_boost:bool = false

var _delay_id:int = 0
var _last_delay_id:int = 0
var _letter_set:String
var _is_leading_zero:bool = false
var _current_intensity = 0
var _position = 0

func letter_set() -> String:
	return _letter_set

func set_letter(position:int, letter:String, intensity:float, animate:bool, change_delay:float, is_leading_zero:bool):
	_position = position
	_is_leading_zero = is_leading_zero
	_letter_set = letter

	var current_delay_id:int = _delay_id + 1

	if change_delay > 0:
		await get_tree().create_timer(change_delay).timeout
		if current_delay_id < _last_delay_id: #A more recent change already happened
			return

	_last_delay_id = current_delay_id

	if animate:
		_animation_player.play(&"change")
	_letter_label.text = letter

	if _is_leading_zero:
		_to_set_leading_zero_feedback.modulate = Color.WHITE
		_to_set_leading_zero_feedback.modulate.a = 0.5
		_to_set_leading_zero_feedback.scale = Vector2.ONE * 0.8
	else:
		_to_set_leading_zero_feedback.modulate.a = 1
		_to_set_leading_zero_feedback.scale = Vector2.ONE * 1

	set_intensity(intensity)

func set_intensity(intensity:float):
	if !_is_leading_zero:
		_to_set_leading_zero_feedback.modulate = _intensity_color.sample(intensity)

	if _shaker:
		_shaker.set_shake_amplitude(_shaker_amplitude_curve.sample(intensity))
		_shaker.set_shake_frequency(_shaker_frequency_curve.sample(intensity))

	_current_intensity = intensity

func _process(delta: float) -> void:
	if !is_instance_valid(ScoreManager.instance): return

	if _current_intensity > 0:
		set_intensity(_current_intensity - delta*0.1)
	else:
		set_intensity(0)

	if ScoreManager.instance.is_in_max_boost() or _force_boost:
		_to_set_letter_position.position.y = _height_multiplier *  sin(_position * _position_multiplier + Time.get_ticks_msec() * 0.001 * _wave_speed)
	else:
		_to_set_letter_position.position.y = 0
