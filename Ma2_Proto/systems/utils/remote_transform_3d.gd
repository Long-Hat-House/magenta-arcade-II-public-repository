class_name CustomRemoteTransform3D extends Node3D

@export var who:NodePath;
@export var follow_position:bool = true;
@export var follow_rotation:bool = true;
@export var follow_scale:bool = true;
@export var global_get:bool;
@export var global_set:bool;

var follow:Node3D;

func _ready() -> void:
	follow = get_node(who);

func _process(delta: float) -> void:
	var tr:Transform3D;
	if global_get:
		tr = follow.global_transform;
	else:
		tr = follow.transform;
		
	if !follow_position: tr.origin = Vector3.ZERO;
	if !follow_rotation: tr.basis = Basis.IDENTITY;
	if !follow_scale: tr = tr.orthonormalized()
	
	if global_set:
		global_transform = tr;
	else:
		transform = tr;
