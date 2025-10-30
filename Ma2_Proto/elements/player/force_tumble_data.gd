class_name ForceTumbleData extends Resource

class Moment extends RefCounted:
	var current_tumble:Vector3;
	var max_tumble_length:float = 4;
	var current_tumble_velocity:Vector3;
	var vibration_influence:float;

	var count:float;
	var random_mult1:float;
	var random_mult2:float;
	var random_mult3:float;
	var random_mult4:float;
	var random_mult5:float;

	func _init(random_strength:float = 0):
		count = PI * 2 * randf();
		if random_strength != 0:
			random_mult1 = 1 + randf_range(-1, 1) * random_strength;
			random_mult2 = 1 + randf_range(-1, 1) * random_strength;
			random_mult3 = 1 + randf_range(-1, 1) * random_strength;
			random_mult4 = 1 + randf_range(-1, 1) * random_strength;
			random_mult5 = 1 + randf_range(-1, 1) * random_strength;
		else:
			random_mult1 = 1;
			random_mult2 = 1;
			random_mult3 = 1;
			random_mult4 = 1;
			random_mult5 = 1;

	func _to_string() -> String:
		return "%s (vel %s)" % [current_tumble, current_tumble_velocity]


@export_category("On Wind")
@export var force_response_multiplier:float = 48;
@export var return_force_multiplier:float = 64;
@export var mass:float = 4;
@export var scaled_mass:bool = true;
@export var min_velocity:float = 2;
@export var min_force_to_min_velocity:float = ForceGenerator.FORCE_MAX * 0.45;
@export var velocity_dissipation:float = 2;
@export var tumble_sensitivity:float = 1;
@export var vibration_max_value_amplitude:float = 0.15;
@export var vibration_frequency:float = 32;
@export var vibration_increase:float = 4;
@export var vibration_decrease:float = 32;
@export var force_min_to_increase_vibration:float = 0.5;
@export var max_tumble:float = 20;
@export var max_tumble_velocity:float = 400;

@export_category("On Hit")
@export var add_tumble_hit_multiplier:float = 0.1;
@export var add_tumble_hit_velocity_multiplier:float = 1;
@export var add_vibration_influence_on_hit:float = 0.8;

const squared_3:float = sqrt(3);

func change_data(data:Moment, force:Vector3, scale:Vector3, delta:float)->float:
	var force_length:float = force.length();
	

	var current_force := force * force_response_multiplier * data.random_mult3 - data.current_tumble * return_force_multiplier * data.random_mult1;
	var used_mass:float = mass * data.random_mult4;
	if scaled_mass:
		used_mass *= (scale.length() / squared_3);
		
	data.current_tumble_velocity += (current_force / used_mass) * delta;
	if min_velocity > 0 and force_length > min_force_to_min_velocity and force.dot(data.current_tumble_velocity) > 0:
		if data.current_tumble_velocity.length() < min_velocity:
			data.current_tumble_velocity = data.current_tumble_velocity.normalized() * min_velocity;
			
	data.current_tumble += data.current_tumble_velocity * delta;
	data.max_tumble_length = maxf(data.max_tumble_length, data.current_tumble.length());
	
	data.current_tumble_velocity -= data.current_tumble_velocity * velocity_dissipation * delta * data.random_mult2;
	
	data.current_tumble = data.current_tumble.limit_length(max_tumble);
	data.current_tumble_velocity = data.current_tumble_velocity.limit_length(max_tumble_velocity);

	if force_length > force_min_to_increase_vibration:
		data.vibration_influence += delta * vibration_increase;
	else:
		data.vibration_influence -= delta * vibration_decrease;
	data.vibration_influence = clampf(data.vibration_influence, 0.0, 1.0);

	return inverse_lerp(0, ForceGenerator.FORCE_MAX, force_length);

func hit(damage:Health.DamageData, hitted:Node3D, data:Moment):
	var damageDirection:Vector3 = Vector3.ZERO;
	if damage.origin:
		damageDirection = (hitted.global_position - damage.origin.global_position).normalized();

	data.current_tumble += damageDirection * add_tumble_hit_multiplier;
	data.current_tumble_velocity += damageDirection * add_tumble_hit_velocity_multiplier;
	data.vibration_influence += add_vibration_influence_on_hit;

func change_and_tumble_process(data:Moment, force:Vector3, scale:Vector3, delta:float)->Vector3:
	var value:float = change_data(data, force, scale, delta);

	data.count += delta * value;

	return get_tumble_vector(data);

func get_tumble_vector(data:Moment)->Vector3:
	var t:float = data.count * vibration_frequency * data.random_mult5;
	var vibration_factor:float = data.current_tumble.length() / data.max_tumble_length;
	vibration_factor *= vibration_factor;
	var vibration:Vector3 = Vector3(cos(t), 0, sin(2 * t)) * data.vibration_influence * vibration_max_value_amplitude * vibration_factor;

	return data.current_tumble * tumble_sensitivity + vibration;
