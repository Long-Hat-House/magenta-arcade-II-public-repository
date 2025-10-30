class_name ScaledMeshLine extends Node

@export var line_to_scale:Node3D;
@export var target_origin:Node3D;
@export var target_destination:Node3D;


func set_target(origin:Node3D, destination:Node3D):
	target_origin = origin;
	target_destination = destination;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_instance_valid(target_origin) and is_instance_valid(target_destination) and line_to_scale.is_visible_in_tree():
		_make_line_process(
				target_origin.global_position,
		 		target_destination.global_position
				)

func _make_line_process(a:Vector3, b:Vector3):
	var distance:Vector3 = b - a;
	var origin:Vector3 = (a + b) * 0.5;
	var basis:Basis = Basis(Quaternion(Vector3.FORWARD, distance.normalized()));
	basis.z = basis.z * distance.length();
	line_to_scale.global_transform = Transform3D(basis, origin);
