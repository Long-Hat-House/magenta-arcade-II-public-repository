class_name VectorUtils

static func rand_vector3_range(min:float, max:float)->Vector3:
	return Vector3(randf_range(min, max), randf_range(min, max), randf_range(min, max));

static func rand_vector3_range_vector(vec:Vector3, only_positive_values:bool = false)->Vector3:
	if only_positive_values:
		return Vector3(randf() * vec.x, randf() * vec.y, randf() * vec.z);
	else:
		return Vector3((randf() - 0.5) * vec.x, (randf() - 0.5) * vec.y, (randf() - 0.5) * vec.z);
		
static func rand_vector3_in_aabb(transform:Transform3D, aabb:AABB):
	return transform * (aabb.position + rand_vector3_range_vector(aabb.size, true));
	
static func rand_vector3_in_screen_notifier(notifier:VisibleOnScreenNotifier3D):
	return rand_vector3_in_aabb(notifier.global_transform, notifier.aabb);

static func get_random_unitary_circle_point()->Vector2:
	var t:float = PI * randf() * 2.0;
	return Vector2(sin(t), cos(t));

static func get_random_unitary_circle_point_xz()->Vector3:
	var t:float = PI * randf() * 2.0;
	return Vector3(sin(t), 0, cos(t));
	
static func get_circle_point_2d(parametrical:float)->Vector2:
	return Vector2(sin(parametrical), cos(parametrical));
	
static func get_circle_point(parametrical:float, up:Vector3 = Vector3.UP, circ_multiplier:Vector2 = Vector2.ONE):
	var circle_orthonormal:Vector3 = Vector3(sin(parametrical) * circ_multiplier.x, 0, cos(parametrical) * circ_multiplier.y)
	var rot:Quaternion = Quaternion(Vector3.UP, up.normalized());
	return rot * circle_orthonormal;
	
static func get_ellipsis_point(t:float, ellipsis_pow:Vector2 = Vector2.ONE, ellipsis_freq:Vector2 = Vector2.ONE, up:Vector3 = Vector3.UP, circ_multiplier:Vector2 = Vector2.ONE):
	var ellipsis_orthonormal:Vector3 = Vector3(
			sin(pow(t, ellipsis_pow.x) * ellipsis_freq.x) * circ_multiplier.x, 
			0, 
			cos(pow(t, ellipsis_pow.y) * ellipsis_freq.y) * circ_multiplier.y)
	var rot:Quaternion = Quaternion(Vector3.UP, up.normalized());
	return rot * ellipsis_orthonormal;
	
	
