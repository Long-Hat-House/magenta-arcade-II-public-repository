class_name ForceTumbleDataValues extends Resource
	
@export_range(0,1) var target_force_percentage:float;
@export var direction_velocity:float = 1;
@export var base_tumble:float;
@export var circle_amplitude:float;
@export var circle_frequency:float;
@export_range(0,1) var ellipsis_factor:float = 0.95;

func get_target_force()->float:
	return target_force_percentage * ForceGenerator.FORCE_MAX;
	
func _to_string() -> String:
	return "tumble values: force %s -> tumble:%s circle amp:%s freq:%s" % [
		get_target_force(), 
		base_tumble, 
		circle_amplitude, 
		circle_frequency
		]
