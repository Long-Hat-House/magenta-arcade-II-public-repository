extends GPUParticles3D

@export var speed_max:float = 8
@export var smooth_speed_change:float = 0.1

var current_speed:float
var old_position:Vector3
var old_ratio:float;

signal changed_ratio(ratio:float);

func _ready() -> void:
	old_position = global_position
	amount_ratio = old_ratio;
	
func _enter_tree() -> void:
	old_position = global_position;

func _process(delta: float) -> void:
	var speed:float = (old_position).distance_to(global_position)/delta
	old_position = global_position
	#current_speed = smooth_speed_change * speed + (1.0 - smooth_speed_change) * current_speed
	current_speed = move_toward(current_speed, speed, 
			delta * 2.5 +\
			delta * 20 * absf(speed - current_speed)
			)
	if (current_speed < 0.01): current_speed = 0;
	#print("[Movement Particle VFX] Speed %s amount %s for %s" % [
		#current_speed,
		#inverse_lerp(0, speed_max, current_speed),
		#self.name
	#]);
	var ratio:float = inverse_lerp(0, speed_max, current_speed);
	if ratio != old_ratio:
		amount_ratio = inverse_lerp(0, speed_max, current_speed);
		changed_ratio.emit(amount_ratio);
		old_ratio = ratio;
