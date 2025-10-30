class_name VariatorOverPosition extends Node3D

@export var max_distance:float = 6
@export var expected_position:float = 10
@export var repeat:bool = true
@export var invert:bool = false
@export var debug:bool = false

func _enter_tree() -> void:
	var check = _check_position()
	if invert: check = !check
	if !check:
		queue_free()
		
func _check_position() -> bool:
	var obj_world_z:float = global_transform.origin.z
	
	# Calculate the difference between the object's world Y position and the target world Y position
	var z_difference:float = abs(obj_world_z - expected_position)
	
	# Check if the object's world Z position is within the specified range
	var within_range:bool = z_difference <= max_distance
	
	if debug:
		print_debug("[VARIATOR] pos: {pos}, z dif: {dif}, within range: {within}".format({"pos" : obj_world_z, "dif" : z_difference, "within" : within_range}))
	
	if repeat:
		# If repeat is enabled, check if the object's world Y position is close to a multiple of world_y
		var is_multiple = fmod(z_difference, expected_position) < max_distance
		
		# Return true if either within the range or close to a multiple of world_y
		return within_range || is_multiple
	else:
		# Return true only if the object's world Y position is within the specified range
		return within_range && obj_world_z < expected_position
