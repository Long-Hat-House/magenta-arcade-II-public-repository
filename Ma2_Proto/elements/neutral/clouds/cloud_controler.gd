extends Node3D

@export var transform_obj:Node3D

func _ready() -> void:
	var random_rotation = deg_to_rad(randf()*360)
	transform_obj.rotate_x(random_rotation)
