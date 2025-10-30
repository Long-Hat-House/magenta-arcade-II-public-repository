extends Node3D

@onready var boeing: MeshInstance3D = $boeing

func set_boeing_rotation_degrees(angle:float):
	set_boeing_rotation(deg_to_rad(angle));

func set_boeing_rotation(angle:float):
	print("[BOEING] setting rot %s" % [angle]);
	boeing.rotation.z = angle;

var current_rot:float;
var current_force:float;
@export var max_rot:float = 5;
@export var max_rot_vel:float = 10;
@export var force_multiplier:float = 0.25;
@export var max_rotation_degrees:float = 8;
@export var rotation_multiplier:float = 2;
@export var spring_force:float = 4;
@export var decay_relative:float = 2;
@export var decay_absolute:float = 2;
@export var force_receiver:Array[ForceReceiver];

func _ready() -> void:
	for receiver in force_receiver:
		receiver.force_received.connect(func(force:Vector3, delta:float):
			var relative_pos:Vector3 = receiver.position;
			var angle_z:float = -relative_pos.normalized().signed_angle_to(to_local(force.normalized()), Vector3.FORWARD) * force_multiplier * force.length();
			#print("[BOEING] adding force %s %s %s (current %s with vel %s)" % [relative_pos, force, angle_z, current_rot, current_force]);
			add_force(angle_z, 0.001);
			)

func add_force(force:float, instant:float = 0.5):
	current_force += force * (1.0 -instant)
	current_rot += force * (instant)
	
#func _process(delta: float) -> void:
	#print("[BOEING] process rot %s, force %s -> force += %s and mt0 w %s" % [current_rot, current_force, current_rot * -spring_force * delta, (decay_absolute + absf(current_force) * decay_relative) * delta]);
	#current_rot += current_force * delta;
	#current_force -= current_rot * spring_force * delta;
	#current_force = move_toward(current_force, 0, (decay_absolute + absf(current_force) * decay_relative) * delta)
	#
	#current_rot = clampf(current_rot, -max_rot, max_rot)
	#current_force = clampf(current_force, -max_rot_vel, max_rot_vel)
	#
	#set_boeing_rotation_degrees(clampf(current_rot * rotation_multiplier, -max_rotation_degrees, max_rotation_degrees));
