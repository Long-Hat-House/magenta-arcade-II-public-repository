class_name LookAtCameraParentY extends LookAtCamera

@export var explanation:String = "getting parent y";

func get_forward_rotation()->float:
	return -get_parent_node_3d().rotation.z;
	return Vector3.UP.signed_angle_to(get_parent_node_3d().global_basis.y, Vector3.FORWARD);
