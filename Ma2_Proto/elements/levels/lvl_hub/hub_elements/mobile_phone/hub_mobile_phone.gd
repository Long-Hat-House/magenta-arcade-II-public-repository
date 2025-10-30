class_name HUBMobilePhone extends Path3D

signal zap_finished

@export var _animation:Switch_Oning_Offing_AnimationPlayer
@export var _ringing_animation:Switch_Oning_Offing_AnimationPlayer
@export var _zap_player:TextFlowPlayerZap

@export_category("Phone Audio")
@export var _sfx_phone_ringing_start:WwiseEvent
@export var _sfx_phone_ringing_stop:WwiseEvent
@export var _sfx_phone_open:WwiseEvent
@export var _sfx_phone_close:WwiseEvent

var _ringing:bool = false

func is_on():
	return _animation.is_set_to_on()

func is_ringing() -> bool:
	return _ringing

func start_ringing():
	if !_ringing:
		_sfx_phone_ringing_start.post(self)
	_ringing = true
	if !is_on():
		_ringing_animation.set_switch(true)

func stop_ringing():
	if _ringing:
		_sfx_phone_ringing_stop.post(self)
	_ringing = false
	_ringing_animation.set_switch(false)

func _exit_tree() -> void:
	if _ringing:
		_sfx_phone_ringing_stop.post(self)

func _ready() -> void:
	_zap_player.hide()

func show_zap():
	if is_on(): return
	_animation.set_switch(true)
	stop_ringing()
	_sfx_phone_open.post(self)

	Player.instance.lock_touches()

	while _animation.is_set_to_on() && _animation._state != Switch_Oning_Offing_AnimationPlayer.State.On:
		await get_tree().process_frame
		if !is_instance_valid(self): return
	if !is_instance_valid(self) || _animation.is_set_to_off(): return

	await _zap_player.zap_show()
	if !is_instance_valid(self): return

	zap_finished.emit()
	Player.instance.unlock_touches()

	if _animation.is_set_to_off(): return
	_animation.set_switch(false)
	_sfx_phone_close.post(self)
	while _animation.is_set_to_off() && _animation._state != Switch_Oning_Offing_AnimationPlayer.State.Off:
		await get_tree().process_frame
		if !is_instance_valid(self): return
	if !is_instance_valid(self) || _animation.is_set_to_on(): return

	if is_ringing():
		_ringing_animation.set_switch(true)
