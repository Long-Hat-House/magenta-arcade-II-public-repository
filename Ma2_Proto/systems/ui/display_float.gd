class_name DisplayFloat extends Control

@export var label_id:Label
@export var label_min:Label
@export var label_max:Label
@export var label_value:Label
@export var label_value_percent:Label
@export var progress_bar:ProgressBar
@export var enable_bellow_min:Control
@export var enable_above_max:Control

var _min:float
var _max:float
var _value:float
var _amount_digits:int;

func set_display(id:String, min_value:float, max_value:float, value:float, color:Color = Color.WHITE, amount_digits:int = 0):
	_min = min_value
	_max = max_value
	_amount_digits = amount_digits;

	if label_id: label_id.text = id
	if label_min: label_min.text = value_to_str(_min)
	if label_max: label_max.text = value_to_str(_max)

	if progress_bar:
		progress_bar.modulate = color
	set_display_value(value)

func value_to_str(value:float)->String:
	return "%.*f" % [_amount_digits, value];

func set_display_value(value:float):
	_value = value
	if label_value: label_value.text = value_to_str(_value)
	if label_value_percent: label_value_percent.text = str(inverse_lerp(_min, _max, _value))
	if progress_bar:
		progress_bar.min_value = _min
		progress_bar.max_value = _max
		progress_bar.value = _value
	if enable_bellow_min:
		enable_bellow_min.visible = _value < _min
	if enable_above_max:
		enable_above_max.visible = _value > _max
