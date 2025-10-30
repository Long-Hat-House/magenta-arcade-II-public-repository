class_name Math

static func apply_quaternion_to_basis(basis:Basis, quat:Quaternion) -> Basis:
	return Basis(quat * basis.x, quat * basis.y, quat * basis.z);

##There is Quaternion(from, to)!!!!!!!!!!!
static func get_quaternion_rotation_between(u:Vector3, v:Vector3) -> Quaternion:


	#// It is important that the inputs are of equal length when
	#// calculating the half-way vector.
	u = u.normalized();
	v = v.normalized();

	#// Unfortunately, we have to check for when u == -v, as u + v
	#// in this case will be (0, 0, 0), which cannot be normalized.
	if (u == -v):
		#// 180 degree rotation around any orthogonal vector
		var orthonormal = vector3_orthogonal(u).normalized();
		return Quaternion(0, orthonormal.x, orthonormal.y, orthonormal.z);

	var half:Vector3 = (u + v).normalized();
	var cross:Vector3 = u.cross(half);
	return Quaternion(u.dot(half), cross.x, cross.y, cross.z)

static func vector3_orthogonal(v:Vector3) -> Vector3:
	var x:float = abs(v.x);
	var y:float = abs(v.y);
	var z:float = abs(v.z);

	var other:Vector3 = (Vector3.RIGHT if x < z else Vector3.FORWARD) if x < y else (Vector3.UP if y < z else Vector3.FORWARD);

	return v.cross(other);

static func vector3_rotate_to(from:Vector3, to:Vector3, maxAngle:float)-> Vector3:
	if from == to:
		return Vector3.ZERO

	# normalise both vectors:
	var va_n := from.normalized();
	var vb_n := to.normalized();

	# take the cross product and dot product
	var cross := va_n.cross(vb_n).normalized();
	var dot:float = va_n.dot(vb_n);

	# acos(dot) gives you the angle (in radians) between the two vectors which you'll want to clamp to your maximum rotation (convert it to radians)
	var ma_rad:float = deg_to_rad(maxAngle);
	var totalAngle:float = clamp(acos(dot), -ma_rad, ma_rad);

	# and now you can rotate your original
	#print("Returning %s to %s in %s angles: %s [%s]" % [from, to, maxAngle, from.rotated(cross, totalAngle), Time.get_ticks_msec()]);
	return from.rotated(cross.normalized(), totalAngle);

## Based on Game Programming Gems 4 Chapter 1.10
static func smooth_damp (current:float, target:float, currentVelocity:float, smoothTime:float, maxSpeed:float, deltaTime:float)->float:
	smoothTime = max(0.0001, smoothTime);
	var omega := 2 / smoothTime;

	var x := omega * deltaTime;
	var exp := 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x);
	var change := current - target;
	var originalTo := target;

	# Clamp maximum speed
	var maxChange := maxSpeed * smoothTime;
	change = clamp(change, -maxChange, maxChange);
	target = current - change;

	var temp := (currentVelocity + omega * change) * deltaTime;
	currentVelocity = (currentVelocity - omega * temp) * exp;
	var output := target + (change + temp) * exp;

	# Prevent overshooting
	if (originalTo - current > 0.0) == (output > originalTo):
		output = originalTo;
		currentVelocity = (output - originalTo) / deltaTime;

	return output;
