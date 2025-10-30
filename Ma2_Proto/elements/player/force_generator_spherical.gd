class_name ForceGenerator_Spherical extends ForceGenerator

@export var min_distance:float;
@export var max_distance:float;
@export var curve:Curve;
@export var force_far_max_percentage:float = 0;
@onready var force_far:float = FORCE_MAX * force_far_max_percentage;
var force_close:float = FORCE_MAX;

func get_force_now(to:Node3D)->Vector3:
	var distance:Vector3 = to.global_position - self.global_position;
	var distanceLength := distance.length();
	var forceLength;
	if distanceLength < max_distance:
		var value:float = inverse_lerp(min_distance, max_distance, distanceLength);
		value = curve.sample(value);
		forceLength = lerpf(force_far, force_close, value);
		forceLength = clamp(forceLength, 0, force_close);
		return distance.normalized() * forceLength;
	return Vector3.ZERO;
	
