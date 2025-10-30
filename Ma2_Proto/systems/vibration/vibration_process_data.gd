class_name VibrationProcess extends Resource

@export_category("Vibration Data")
@export var base_duration_ms:int = 50;
@export var extra_duration_multiplier:float = 20;
@export var base_amplitude:float = 0.05;
@export var extra_amplitude_multiplier:float = 0.005;

@export_category("Input data")
@export var translation_xz_distance_add:float = 0.25;
@export var inactive_time_add:float = 0.25;
@export var active_time_add:float = 3;
@export var vertical_up_add:float = 1;
@export var vertical_down_add:float = -2;
@export var fall_vibration:VibrationSingle;
@export var fall_distance:float = 2;
@export var fall_distance_extra_multiplier:float;

@export var disable:bool;


var old_pos:Vector3;
func vibration_follow_node_process(node:Node3D, delta:float):
	if disable: return;
	
	var now_pos:Vector3 = node.global_position;
	var translation:Vector3 = now_pos - old_pos;
	old_pos = now_pos;
	
	var amount:float = 0.0;
	var height_change:float = translation.y;
	translation.y = 0;
	var walk_change:float = translation.length();
	
	amount += walk_change * translation_xz_distance_add;
	if walk_change > 0.0025:
		amount += delta * active_time_add;
	else:
		amount += delta * inactive_time_add;
	if height_change > 0:
		amount += height_change * vertical_up_add;
	else:
		amount -= height_change * vertical_down_add;
		if fall_vibration and absf(height_change) > fall_distance:
			fall_vibration.vibrate(node, 1.0 + amount * extra_amplitude_multiplier, 1.0 + amount * extra_duration_multiplier);
			return;
	
	vibration_process(node, amount);
	
var count:float;
func vibration_process(node:Node, delta_translation:float):
	count += delta_translation;
	if count >= 1:
		count -= 1;
		VibrationManager.vibrate(
			-1,
			floori(base_duration_ms + count * extra_duration_multiplier),
			base_amplitude + count * extra_amplitude_multiplier)
		count = 0;
	pass;
