class_name AI_GoForward extends Node3D

@export var walker:Node3D;
@export var path:Path3D;
@export var velocity:float;

var path_count:float = 0;
var rotation_count:float = 0;

var length:float;

func _ready() -> void:
	if path:
		set_path(path, 0);

func _process(delta: float) -> void:
	walk(delta);

func set_path(path:Path3D, where_it_in_time:float = 0):
	self.path = path;
	length = path.curve.get_baked_length();
	path_count = where_it_in_time * velocity;
	walk(0);

func walk(delta_time:float) -> void:
	if path and is_instance_valid(path):
		var change:float = delta_time * velocity;

		if path_count < length:
			if (path_count + change) > length:
				walker.position = path.global_transform * path.curve.sample_baked(length, true);
				path = null;
				delta_time -= (length - path_count) / velocity;
			else:
				path_count += change;
				walker.position = path.global_transform * path.curve.sample_baked(path_count, true);
				return;
		else:
			path = null;

	walker.position += walker.global_basis.z * velocity * delta_time;
