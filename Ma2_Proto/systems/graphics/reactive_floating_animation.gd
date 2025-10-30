extends Node3D

@export var origin_rotation_vector = Vector3.UP;
@export var late_distance:Vector3 = Vector3(0,4,0.25);
@export var max_inertia_distance:float = 1;
@export var inertia_absolute_velocity:float = 1;
@export var inertia_relative_velocity:float = 5;
@export var allow_inertia_to_overshoot:bool = true;
@export var yaw_project:Vector3 = Vector3.RIGHT;
@export var yaw_multiplier:float;
@export var yaw_max_degrees:float = 12;
var yaw_max:float;


var pos_inertia:Vector3;

func centralize():
	pos_inertia = global_position;
	
func _ready():
	centralize();
	yaw_max = deg_to_rad(absf(yaw_max_degrees));

func _process(delta:float) -> void:
	var pos:Vector3 = global_position;
	
	var dist:Vector3 = pos - pos_inertia;
	if dist.length() > max_inertia_distance:
		pos_inertia = pos - dist.normalized() * max_inertia_distance;
		dist = pos - pos_inertia;
	var vel:Vector3 = dist.normalized() * inertia_absolute_velocity + dist * inertia_relative_velocity;
	if allow_inertia_to_overshoot:
		pos_inertia += vel * delta;
	else:
		pos_inertia = pos_inertia.move_toward(pos, vel.length() * delta)
	
	var yaw_value:float = dist.project(yaw_project).length();
	yaw_value = clampf(yaw_value, -yaw_max, yaw_max);
	
	
	##Rotate to balance
	var b:Basis = Basis(
			## Rotate up
			Quaternion(
				Vector3.UP,
				(pos_inertia + late_distance) - pos
				) 
			## Yaw
			* Quaternion(Vector3.UP, yaw_multiplier * yaw_value)
			)
			
	
	
	## Set data
	self.basis = b;
