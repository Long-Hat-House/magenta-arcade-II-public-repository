class_name RandomRotationLocal extends Node3D

@export var _y:bool = true

@export var _range_min:float = 0
@export var _range_max:float = 360

@export var spawn_from_y:float = 0;
@export var spawn_from_y_duration:float = 0.25;
@export var spawn_from_node:Node3D;

func _enter_tree() -> void:
	if visible:
		randomize_rotation_local()

func randomize_rotation_local() -> void:
	if _y:
		rotate_y(deg_to_rad(randf_range(_range_min,_range_max)))
	if spawn_from_y != 0:
		var posY = spawn_from_node.position.y;
		spawn_from_node.position.y += spawn_from_y;
		create_tween().tween_property(spawn_from_node, "position:y", posY, spawn_from_y_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT);
