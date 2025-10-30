class_name Graphic_Carpa extends LHH3D

@export var face_progress:Curve;

@onready var head: MeshInstance3D = $rig_peixe/Skeleton3D/head


func set_fear(face01:float):
	head.set_blend_shape_value(0, remap(face_progress.sample(face01), 0.0, 1.0, -1.0, 1.0));
