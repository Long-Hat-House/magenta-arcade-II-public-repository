class_name GenericAltar extends Node3D

signal obj_hold_finished()

@export var _anim_onoff:Switch_Oning_Offing_AnimationPlayer
@export var _anim_pressed_onoff:Switch_Oning_Offing_AnimationPlayer
@export var _sfx_loop_open:AkEvent3DLoop
@export var _obj_pivot:Node3D
@export var _vfx_destroy:PackedScene

var _connected_altars:Dictionary
var _finished:bool
var _obj:Node3D

func add_obj(obj:Node3D):
	if !_obj_pivot:
		_obj_pivot = self

	var parent = obj.get_parent()
	if parent:
		parent.remove_child(obj);

	_anim_onoff.speed_scale = randf() * .2 + 0.9
	_anim_onoff.set_switch_immediate(false)

	_obj = obj
	_obj_pivot.add_child(_obj)

	if _obj is Pressable:
		_obj.pressed.connect(_on_obj_pressed);
		_obj.released.connect(_on_obj_released);
		_obj.set_disabled(true)
	if _obj is Holdable:
		_obj.button_hold_finished.connect(_on_obj_hold_finished)

func _on_obj_hold_finished() -> void:
	obj_hold_finished.emit()
	destroy_altar()

func _on_obj_pressed(touch = null) -> void:
	if _anim_pressed_onoff:
		_anim_pressed_onoff.set_switch(true)

func _on_obj_released() -> void:
	if _anim_pressed_onoff:
		_anim_pressed_onoff.set_switch(false)

func start_altar():
	_finished = false
	_anim_onoff.set_switch(true)
	if _sfx_loop_open: _sfx_loop_open.start_loop()

	if is_instance_valid(_obj) && _obj is Pressable:
		_obj.set_disabled(false)

func finish_altar():
	if _finished: return
	_finished = true
	_anim_onoff.set_switch(false)
	if _sfx_loop_open: _sfx_loop_open.stop_loop()

	if is_instance_valid(_obj) && _obj is Pressable:
		_obj.set_disabled(true)

	for connected_altar in _connected_altars:
		connected_altar.finish_altar()

func destroy_altar():
	if _finished: return
	_finished = true

	if _vfx_destroy:
		InstantiateUtils.InstantiateInTree(_vfx_destroy, self)

	if is_instance_valid(_obj) && _obj is Pressable:
		_obj.set_disabled(true)

	for connected_altar in _connected_altars:
		connected_altar.finish_altar()

	queue_free()


func connect_altar(other:GenericAltar):
	if _connected_altars.has(other): return
	_connected_altars[other] = true
	other.connect_altar(self)
