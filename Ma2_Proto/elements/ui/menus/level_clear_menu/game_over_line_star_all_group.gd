class_name GameOverLineStarAllGroup extends BoxContainer

enum AnimStyle{
	Off,
	On,
	New
}

@export var _sfx_star:WwiseEvent
@export var _sfx_star_switch_off:WwiseSwitch
@export var _sfx_star_switch_on:WwiseSwitch
@export var _sfx_star_switch_new:WwiseSwitch
@export var _anim:AnimationPlayer
@export var _text:Label

var _style:AnimStyle

func set_value(text_value:String, style:AnimStyle):
	_text.text = text_value
	_style = style

func animate():
	match _style:
		AnimStyle.Off:
			_anim.play("off")
			if _sfx_star_switch_off: _sfx_star_switch_off.set_value(self)
		AnimStyle.On:
			_anim.play("on")
			if _sfx_star_switch_on: _sfx_star_switch_on.set_value(self)
		AnimStyle.New:
			_anim.play("new")
			if _sfx_star_switch_new: _sfx_star_switch_new.set_value(self)
	if _sfx_star: _sfx_star.post(self)

func skip():
	match _style:
		AnimStyle.Off:
			_anim.play("off")
		AnimStyle.On:
			_anim.play("on")
		AnimStyle.New:
			_anim.play("new")
	_anim.speed_scale = 20

func is_animating() -> bool:
	return _anim.is_playing()
