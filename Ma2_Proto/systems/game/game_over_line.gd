class_name GameOverLine extends Control

enum LineColor{
	Default,
	Bad,
	Good
}

@export var _animation:Switch_Oning_Offing_AnimationPlayer

@export var _label_title_text:Label
@export var _label_value_text:Label
@export var _icon:TextureRect

@export var _to_set_modulate:Array[Control]
@export var _to_set_self_modulate:Array[Control]

var _show_finished:bool = false

func set_show_finished():
	_show_finished = true

func get_line_show_finished() -> bool:
	return _show_finished

func line_show():
	_animation.set_switch(true)
	await _animation.turned_on
	set_show_finished()

func skip():
	set_show_finished()
	_animation.set_switch_immediate(true, true)

func set_info(title_text:String, value_text:String, icon:Texture2D, line_color:LineColor = LineColor.Default):
	if _icon:
		_icon.texture = icon
	if _label_title_text:
		_label_title_text.text = title_text
		_label_title_text.visible = !title_text.is_empty()
	if _label_value_text:
		_label_value_text.text = value_text
		_label_value_text.visible = !value_text.is_empty()

	if line_color != LineColor.Default:
		for c in _to_set_modulate:
			if line_color == LineColor.Bad:
				c.modulate = MA2Colors.MAGENTA_VERY_BRIGHT
			if line_color == LineColor.Good:
				c.modulate = MA2Colors.GREENISH_BLUE
		for c in _to_set_self_modulate:
			if line_color == LineColor.Bad:
				c.self_modulate = MA2Colors.MAGENTA_VERY_BRIGHT
			if line_color == LineColor.Good:
				c.self_modulate = MA2Colors.GREENISH_BLUE
