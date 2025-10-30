class_name LookAtPlayer extends Node3D

@export var disabled:bool;
@export var enable_random_rotation:bool = false
@export var plane:Plane = Plane.PLANE_XZ;
var _random_angle:float = 0;

func _ready():
	if enable_random_rotation:
		_random_angle = randf_range(0,2 * PI)
		
func get_up_vector()->Vector3:
	return Vector3.UP;
		
func get_forward_rotation()->float:
	return 0;

func _process(_delta):
	if disabled:
		return
		
	if Player.instance.currentTouches.size() > 0:
		var pp:Vector3 = get_player_position();
		
		if plane and plane.normal != Vector3.ZERO:
			var dist:Vector3 = pp - self.global_position;
			dist = plane.project(dist);
			pp = self.global_position + dist;
	
		if plane.normal != Vector3.ZERO:
			var dist:Vector3 = pp - self.global_position;
			dist = plane.project(dist);
			pp = self.global_position + dist;
	
		look_at(pp, get_up_vector(), true)
		rotate_object_local(Vector3.FORWARD, get_forward_rotation() + _random_angle);
	
	
func get_player_position()->Vector3:
	return Player.instance.get_closest_position(self.global_position);
