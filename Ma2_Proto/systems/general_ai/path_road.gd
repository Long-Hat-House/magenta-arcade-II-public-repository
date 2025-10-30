class_name PathRoad extends Path3D

@export var cubic:bool = true;

class Data:
	var origin:Transform3D;
	var velocity:float;
	var max_distance:float;
	var count:float;

var elements:Dictionary[Node3D, Data];

signal added_element(elem:Node3D);

func add_element(elem:Node3D, origin:Transform3D, velocity:float = 5, max_distance:float = 0):
	var data:Data = Data.new();
	data.origin = origin;
	data.velocity = velocity;
	data.count = 0;
	data.max_distance = max_distance;
	elem.global_position = origin * self.curve.sample_baked(0.0, cubic);
	elements[elem] = data;
	added_element.emit(elem);
	elem.tree_exited.connect(func():
		elements.erase(elem);
		, CONNECT_ONE_SHOT | CONNECT_DEFERRED);

func get_time_to_cross(velocity:float):
	return curve.get_baked_length() / velocity;
		
		
func _physics_process(delta: float) -> void:
	var keys:Array[Node3D] = elements.keys();
	var len:float = curve.get_baked_length();
	for elem:Node3D in keys:
		if is_instance_valid(elem):
			var elem3D = elem as Node3D;
			if elem3D:
				print("(%s) -> %s * %s = %s" % [
					elem,
					elements[elem].origin, self.curve.sample_baked(elements[elem].count, cubic),
					elements[elem].origin * self.curve.sample_baked(elements[elem].count, cubic)
				]);
				elem3D.global_position = elements[elem].origin * self.curve.sample_baked(elements[elem].count, cubic);
			elements[elem].count = clampf(
					elements[elem].count + delta * elements[elem].velocity, 
					0.0, 
					len - elements[elem].max_distance
			);
