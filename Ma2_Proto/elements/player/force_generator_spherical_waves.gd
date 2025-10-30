class_name ForceGenerator_Spherical_Waves extends ForceGenerator_Spherical

@export var period:float = 1.15;
@export var another_curve:Curve;
var count:float;
const two_pi = PI * 2;
var delta_multiplier:float;

func _ready():
	#super._ready();
	delta_multiplier = two_pi / period;
	

func _process(delta: float) -> void:
	count += delta * delta_multiplier;
	
func get_force_now(to:Node3D)->Vector3:
	var to_position:Vector3 = to.global_position;
	var distance:Vector3 = to_position - self.global_position;
	var distanceModifier:Vector3 = Vector3(pingpong(distance.x, 1) - 0.5, 0, pingpong(distance.z + distance.y, 1) - 0.5);
	var distanceLength := distance.length();
	var forceLength;
	if distanceLength < max_distance:
		var distance_value:float = inverse_lerp(min_distance, max_distance, distanceLength);
		var value = another_curve.sample(distance_value);
		forceLength = lerpf(force_far, force_close, value);
		forceLength = clamp(forceLength, 0, force_close);
		return super.get_force_now(to).lerp(distance.normalized() * forceLength, distance_value * 0.5 * (cos(count * to_position.x + to.position.z) + 1.0));
	return Vector3.ZERO;
