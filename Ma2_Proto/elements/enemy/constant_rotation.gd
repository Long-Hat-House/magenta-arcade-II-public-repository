class_name ConstantRotation extends Node3D

@export var axis:Vector3 = Vector3.UP;
@export var angleVelocity:float;
@export var angle_degrees:bool;

func _ready() -> void:
	axis = axis.normalized();
	if angle_degrees:
		angleVelocity = deg_to_rad(angleVelocity);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	transform.basis = transform.basis.rotated(axis, angleVelocity * delta);
