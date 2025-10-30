class_name ProgressBarIndexedElementSwitchAnimation extends ProgressBarIndexedElement

@export var _animation:Switch_Oning_Offing_AnimationPlayer
@export var _when_disabling_play_off_first:bool = false
var _state_on:bool = false

func set_state(index:int, max:int, fill:int, imediate:bool):
	_state_on = index < max
	if imediate or _state_on or !_when_disabling_play_off_first:
		visible = _state_on

	if imediate:
		_animation.set_switch_immediate(index < fill, true)
	else:
		_animation.set_switch(index < fill)

	if !imediate and !_state_on and _when_disabling_play_off_first:
		_animation.set_switch(false)
		await _animation.await_turned_off()
		visible = _state_on
