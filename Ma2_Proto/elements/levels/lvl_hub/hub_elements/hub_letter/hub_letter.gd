class_name HUBLetter extends Node3D

signal letter_closed

@export var _animation:AnimationPlayer
@export var _pressable:Pressable

func show_letter():
	_animation.play(&"starting")
	await _animation.animation_finished
	_animation.play(&"waiting")
	await _pressable.pressed
	_animation.play(&"opening")
	await _animation.animation_finished
	_animation.play(&"open")

func close_letter():
	_animation.play(&"exiting")
	await _animation.animation_finished
	letter_closed.emit()
