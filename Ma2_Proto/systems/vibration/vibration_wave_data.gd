class_name VibrationWave extends VibrationSingle

@export_category("Wave")
@export var curve_amplitude_multiplier:Curve;
@export var sample_duration_ms:int = 50;
@export var pause_duration_base_ms:int = 0;
@export var curve_pause:Curve;
@export var disable_curve:bool;

var call_id:int;

func is_ok(node:Node, id:int)->bool:
	return is_instance_valid(node) and call_id == id;

func vibrate(node:Node, duration_multiplier:float = 1.0, amplitude_multiplier:float = 1.0):
	if disable_curve:
		super.vibrate(node, duration_multiplier, amplitude_multiplier);
		return;
	
	call_id += 1;
	var id = call_id;
	var count:float = 0;
	var total_duration:float = duration_ms / 1000.0 * duration_multiplier;
	while(count < total_duration):
		var x_curve:float = count/total_duration;
		var dur_ms:int = sample_duration_ms;
		var rest:int = floori((total_duration - count) * 1000.0);
		if dur_ms > rest:
			dur_ms = rest;
			
		var sample_duration:float = floorf(dur_ms) / 1000.0;
		var amp:float = amplitude * amplitude_multiplier * curve_amplitude_multiplier.sample_baked(x_curve)
		VibrationManager.vibrate(priority, dur_ms, amp);
		await node.get_tree().create_timer(sample_duration, true, false, true).timeout;
		if !is_ok(node, id): return;
		count += sample_duration;
		
		if pause_duration_base_ms > 0 and curve_pause:
			x_curve = count / total_duration;
			var pause_duration:float = (floorf(pause_duration_base_ms) / 1000.0) * curve_pause.sample(x_curve);
			if pause_duration > 0:
				await node.get_tree().create_timer(pause_duration, true, false, true).timeout;
				if !is_ok(node, id): return;
				count += pause_duration;
				
func interrupt():
	call_id += 1;
