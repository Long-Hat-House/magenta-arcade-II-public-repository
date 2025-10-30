class_name ProgressBarFloat extends Control

const PROP_MAX_VALUE:StringName = &"max_value"
const PROP_COLOR_BASE:StringName = &"color_base"
const PROP_COLOR_HIGHLIGHT:StringName = &"color_highlight"

@export var _progress_bar:ProgressBar
@export var _texture_progress_bar:TextureProgressBar
@export var _to_set_color_base:Array[Control]
@export var _to_set_color_highlight:Array[Control]
@export var _to_set_size_y:Array[Control]
@export var _size_per_fill_y:float = 5

@export var _animation_on_off:Switch_Oning_Offing_AnimationPlayer
@export var _animation_charged:Switch_Oning_Offing_AnimationPlayer

var _max_fill:float

#returns the amount of actual fill
func set_bar_data(on:bool, data:Dictionary, fill:float = 0) -> float:
	if _animation_on_off:
		_animation_on_off.set_switch(on)

	_max_fill = 1

	if data.has(PROP_COLOR_BASE):
		for control in _to_set_color_base:
			control.modulate = data[PROP_COLOR_BASE]
		if _texture_progress_bar:
			_texture_progress_bar.tint_under = data[PROP_COLOR_BASE]
	if data.has(PROP_COLOR_HIGHLIGHT):
		for control in _to_set_color_highlight:
			control.modulate = data[PROP_COLOR_HIGHLIGHT]
		if _texture_progress_bar:
			_texture_progress_bar.tint_over = data[PROP_COLOR_HIGHLIGHT]
	if data.has(PROP_MAX_VALUE):
		_max_fill = data[PROP_MAX_VALUE]

	if _progress_bar:
		_progress_bar.max_value = _max_fill

	if _texture_progress_bar:
		_texture_progress_bar.max_value = _max_fill

	for sizable in _to_set_size_y:
		sizable.custom_minimum_size.y = _size_per_fill_y * _max_fill

	return set_fill(fill)

#returns the amount of actual fill
func set_fill(fill:float) -> float:
	fill = max(min(fill, _max_fill), 0)

	if _animation_charged:
		var filled:bool = fill >= _max_fill
		if filled && !_animation_charged.is_set_to_on():
			_animation_charged.set_switch(true)
		elif !filled && !_animation_charged.is_set_to_off():
			_animation_charged.set_switch(false)

	if _progress_bar:
		_progress_bar.value = fill

	if _texture_progress_bar:
		_texture_progress_bar.value = fill

	return fill
