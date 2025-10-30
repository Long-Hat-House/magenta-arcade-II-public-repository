extends Node3D

@export var forward_velocity:float = 5;
@export var amplitude:float;
@export var frequency:float = 1;

var count:float;
var direction:Vector3;
var cross:Vector3;
var origin:Vector3;
var initialized:bool;

func _ready() -> void:
	if not initialized:
		initialize();
	
func initialize():
	direction = global_basis.z.normalized();
	cross = global_basis.x.normalized();
	origin = global_position;
	initialized = true;
	#print("[SNAKE MOVE] origin: %s, direction %s, cross %s" % [origin, direction, cross]);

func get_snake_local_position(count:float)->Vector3:
	if not initialized:
		initialize();
	return get_local_position(direction, cross, count);
	
func get_snake_position(count:float)->Vector3:
	var target_position:Vector3 = origin + get_snake_local_position(count);
	return target_position;

func walk(delta:float):
	count += delta;
	var target_position:Vector3 = get_snake_position(count);
	var translation:Vector3 = target_position - global_position;
	global_position += translation;
	
func get_local_position(direction:Vector3, cross:Vector3, t:float)->Vector3:
	var straight:Vector3 = direction * forward_velocity * t;
	var curve:Vector3 = cross * sin(t * frequency * PI) * amplitude;
	return straight + curve;
