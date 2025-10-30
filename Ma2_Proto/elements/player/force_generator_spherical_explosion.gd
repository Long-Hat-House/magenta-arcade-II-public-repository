class_name ForceGenerator_Spherical_Explosion extends ForceGenerator_Spherical

signal ended;

@export var force_multiplier_begin:float = 1;
@export var force_multiplier_end:float = 0;
@export var duration:float = 0.5;
@export var ease:Tween.EaseType;
@export var trans:Tween.TransitionType;

var force_multiplier:float = 1;

func _enter_tree() -> void:
	super._enter_tree();
	
	if !is_node_ready():
		await ready;
	
	start_tween();
	
func get_force_now(to:Node3D)->Vector3:
	return super.get_force_now(to);	
	
func start_tween():
	var t:= create_tween();
	force_multiplier = force_multiplier_begin;
	t.tween_property(self, "force_multiplier", force_multiplier_end, duration)\
			.set_ease(ease).set_trans(trans);
	t.tween_callback(ended.emit)
