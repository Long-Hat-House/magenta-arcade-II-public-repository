class_name TweenUtils

static func tween_jump_vector2(node:Node, tween:Tween, property_path:String, origin:Vector2, destination:Vector2, jump_height_and_direction:Vector2, duration:float)->MethodTweener:
	return tween.tween_method(func(value:float):
		var bell_value:float = remap(value, 0.0, 1.0, -1.0, 1.0);
		bell_value = 1.0 - (bell_value * bell_value);
		node.set(property_path, destination * value + origin * (1 - value) + jump_height_and_direction * bell_value); 
	,0.0, 1.0, duration);

static func tween_jump_vector3(node:Node, tween:Tween, property_path:String, origin:Vector3, destination:Vector3, jump_height_and_direction:Vector3, duration:float)->MethodTweener:
	return tween.tween_method(func(value:float):
		var bell_value:float = remap(value, 0.0, 1.0, -1.0, 1.0);
		bell_value = 1.0 - (bell_value * bell_value);
		var value_vec3:Vector3 = destination * value + origin * (1 - value) + jump_height_and_direction * bell_value;
		if node:
			node.set(property_path, value_vec3); 
	,0.0, 1.0, duration);
	
static func tween_jump_vector3_dynamic(node:Node, tween:Tween, property_path:String, origin_vec3:Callable, destination_vec3:Callable, jump_height_and_direction:Vector3, duration:float)->MethodTweener:
	return tween.tween_method(func(value:float):
		var bell_value:float = remap(value, 0.0, 1.0, -1.0, 1.0);
		bell_value = 1.0 - (bell_value * bell_value);
		var value_vec3:Vector3 = destination_vec3.call() * value + origin_vec3.call() * (1 - value) + jump_height_and_direction * bell_value;
		if node:
			node.set(property_path, value_vec3); 
	,0.0, 1.0, duration);
