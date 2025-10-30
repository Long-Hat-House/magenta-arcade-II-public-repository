class_name ShopTextTitle extends Node3D

@export var _label3d:Label3D
@export var _animation:AnimationPlayer

func _ready() -> void:
	_animation.speed_scale = 0.9 + randf() * .2

func set_title(title:String):
	_label3d.text = title
