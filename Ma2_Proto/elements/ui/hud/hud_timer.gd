class_name HUD_Timer extends Node

@export var label:Label
var ok_color:Color = Color.WHITE;
var not_ok_color:Color = MA2Colors.RED_LIGHT;
var warning_seconds:float = 10

var _max_time:float

func set_times(max_time:float):
	_max_time = max_time

func set_timer(seconds:float):
	display_time(seconds);
	if seconds <= _max_time - warning_seconds:
		label.modulate = ok_color
	elif seconds <= _max_time:
		label.modulate = ok_color.lerp(not_ok_color, 0.5)
	else:
		label.modulate = not_ok_color
	pass;

func display_time(seconds:float):
	var minutes:int = floor(seconds/60.0);
	var seconds_only:int = seconds - (minutes * 60);
	label.text = "%02d:%02d" % [minutes, seconds_only]
