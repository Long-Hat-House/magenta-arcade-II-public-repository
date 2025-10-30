class_name ForceGenerator extends Node3D

const FORCE_MAX:float = 10;

@export var debug_generator_entry_exit:bool;

static var generators:Array[ForceGenerator] = [];

func _enter_tree() -> void:
	generators.push_back(self);
	if debug_generator_entry_exit:
		print("adding generator %s" % self);
	
func _exit_tree() -> void:
	generators.erase(self);
	if debug_generator_entry_exit:
		print("removing generator %s" % self);

func get_force_now(to:Node3D)->Vector3:
	return Vector3.ZERO;
	
