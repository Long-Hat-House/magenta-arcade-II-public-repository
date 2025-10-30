class_name QuaternionUtils

static func from_to_rotation(from:Vector3, to:Vector3)->Quaternion:
	var axis = from.cross(to).normalized();
	var angle = from.angle_to(to);
	var quat = Quaternion(axis, angle);
	return quat;
	
static func linear_rotation(now:Vector3, target:Vector3, axis:Vector3, delta:float, max_angle_deg:float, snap_angle_deg:float = 0)->Quaternion:
	var angle_to_direction:float = now.signed_angle_to(target, axis);
	var angle_to:float  = clamp(angle_to_direction, -max_angle_deg, max_angle_deg) * delta;
	if angle_to < deg_to_rad(snap_angle_deg):
		angle_to = angle_to_direction;
	return Quaternion(axis, angle_to);
