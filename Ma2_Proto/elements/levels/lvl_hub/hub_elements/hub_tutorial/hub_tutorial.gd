class_name Tutorial extends Node

@export var _animation:Switch_Oning_Offing_AnimationPlayer
@export var _tutorial_node:Node3D
@export var _rotation_node:Node3D

var _current_target:Node3D

func play_tutorial_target(target:Node3D, scale:float = 1, rotation:float = 0):
	_current_target = target
	_animation.set_switch(true)
	_tutorial_node.scale = Vector3.ONE*scale
	_rotation_node.rotation_degrees = Vector3(0,0,rotation)
	_update_position()

func stop_tutorial():
	_animation.set_switch(false)

func _process(delta: float) -> void:
	if _current_target && _animation._state != Switch_Oning_Offing_AnimationPlayer.State.Off:
		_update_position()

func _update_position():
	_tutorial_node.global_position = _current_target.global_position
