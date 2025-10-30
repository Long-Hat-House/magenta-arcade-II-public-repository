extends Node3D

@export var flickering:Node3D = null;
@export var time_on:float = 0.5;
@export var time_off:float = 0.2;

func get_flickering_node()->Node3D:
	if flickering: 
		return flickering;
	else: 
		return self;

func _enter_tree() -> void:
	if not is_node_ready(): await ready;
	var t:= create_tween();
	t.tween_interval(time_on);
	t.tween_callback(func(): get_flickering_node().visible = false);
	t.tween_interval(time_off);
	t.tween_callback(func(): get_flickering_node().visible = true);
	t.set_loops(-1);
