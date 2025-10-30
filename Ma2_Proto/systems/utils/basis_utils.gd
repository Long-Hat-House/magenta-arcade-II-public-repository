class_name BasisUtils

static func rotate_from_up_to(direction:Vector3)->Basis:
	if direction.is_zero_approx():
		direction = Vector3.UP

	return Basis(Quaternion(Vector3.UP, direction));
