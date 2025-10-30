class_name TransformUtils

static func linear_rotation_angle_rad(current_direction:Vector3, target_direction:Vector3, axis:Vector3, delta:float, max_angle_deg:float)->float:
	var angle_to_direction_rad:float = current_direction.signed_angle_to(target_direction, axis);
	var max_angle_rad:float = deg_to_rad(max_angle_deg);
	var angle_to_rad:float  = clamp(angle_to_direction_rad, -max_angle_rad, max_angle_rad);
	angle_to_rad = angle_to_rad * delta;
	return angle_to_rad;

static func tumble_rect(node:Node3D, force:Vector3, corner_size_xz:Vector3 = Vector3.ZERO, up:Vector3 = Vector3.UP):
	tumble_rotation_only(node, force, up);
	if corner_size_xz.length_squared() > 0.01:
		var angle:Vector3 = node.basis.get_euler();
		var sine_x:float = abs(sin(angle.x));
		var sine_z:float = abs(sin(angle.z));
		node.position = up * (sine_x * abs(corner_size_xz.x) + sine_z * abs(corner_size_xz.z));


static func tumble_circle(node:Node3D, force:Vector3, radius:float = 0, up:Vector3 = Vector3.UP):
	tumble_rotation_only(node, force, up);
	if radius > 0.0:
		var angle:Vector3 = node.basis.get_euler();
		var sine_x:float = abs(sin(angle.x));
		var sine_z:float = abs(sin(angle.z));
		node.position = up * (sine_x * radius + sine_z * radius);

static func tumble_rotation_only(node:Node3D, force:Vector3, up:Vector3)->Node3D:
	var parent := node.get_parent_node_3d();
	force = parent.global_transform.inverse().basis * force;
	node.basis = BasisUtils.rotate_from_up_to(Vector3.UP + force * 0.1);
	#node.global_basis = BasisUtils.rotate_from_up_to(Quaternion(Vector3.UP, up) * force * 0.1, node.get_parent_node_3d().global_basis);
	#node.basis = node.basis.orthonormalized().scaled(scale);
	#node.basis = parent.global_basis.inverse() * node.basis.().scaled(scale);
	return node;

static func tween_fall(node:Node3D, tween:Tween, duration:float = 0.85, bounce_duration:float = 0.65, from:Vector3 = Vector3.UP * 25, property:String = "global_position")->Tween:
	node.global_position += from;
	tween.tween_property(node, property, -from, duration).as_relative().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD);
	tween.tween_property(node, property, Vector3.UP * 2.5, bounce_duration * 0.5).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART);
	tween.tween_property(node, property, -Vector3.UP * 2.5, bounce_duration * 0.5).as_relative().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART);
	return tween;

static func tremble_up_rotation_coin(node:Node3D, tween:Tween, circular_radius:float, amount_of_circles:float,  pendulum_radius:Vector3, amount_of_pendulums:float, duration:float, up:Vector3 = Vector3.UP)->MethodTweener:
	const pi2:float = 2.0 * PI;
	
	return tween.tween_method(func(value01:float):
		var circle:Vector3 = VectorUtils.get_circle_point(value01 * amount_of_circles * pi2) * circular_radius * (1.0 - value01);
		var pendulum:Vector3 = pendulum_radius * sin(value01 * amount_of_pendulums * pi2) * (1.0 - value01);
		tumble_rotation_only(node, circle + pendulum, up);
		, 0.0, 1.0, duration);
	return null;

static func tremble(node:Node3D, force:Vector3, origin:Vector3 = Vector3.ZERO):
	node.position = origin + get_tremble_vector(force);

static func get_tremble_vector(force:Vector3)->Vector3:
	return	Vector3(randf_range(-force.x, force.x), randf_range(-force.y, force.y), randf_range(-force.z, force.z)) * 0.5;

static func tween_jump_global(node:Node3D, tween:Tween, destination_global:Vector3, jump_height_and_direction:Vector3, duration:float)->MethodTweener:
	return tween_jump_global_dynamic(node, tween, func(): return destination_global, jump_height_and_direction, duration);

static func tween_jump_global_dynamic(node:Node3D, tween:Tween, destination_global:Callable, jump_height_and_direction:Vector3, duration:float)->MethodTweener:
	var origin:Vector3 = node.global_position;
	return tween.tween_method(func(value:float):
		var bell_value:float = 2 * (value - 0.5);
		bell_value = 1 - (bell_value * bell_value);
		node.global_position = destination_global.call() * value + origin * (1 - value) + jump_height_and_direction * bell_value;
	,0.0, 1.0, duration);
