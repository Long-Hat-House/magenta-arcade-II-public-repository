extends EditorNode3DGizmoPlugin

func _get_gizmo_name():
	return "LevelGizmo";
	
func _has_gizmo(for_node_3d:Node3D):
	return for_node_3d is Burst and for_node_3d.visible;
	
func _init():
	create_material("main", Color(0.45, 0.85, 0.45))
	create_material("handles", Color(0.45, 0.85, 0.45))
	
func _get_handle_name(gizmo, handle_id, secondary):
	return "Level Burst";
	
func _redraw(gizmo:EditorNode3DGizmo):
	gizmo.clear()

	var node3d := gizmo.get_node_3d()

	var lines := PackedVector3Array()
	
	var distance:float = 8;
	var left:Vector3 = node3d.position + Vector3.LEFT * distance * 0.5;
	var right:Vector3 = node3d.position + Vector3.RIGHT * distance * 0.5;

	lines.push_back(left);
	lines.push_back(right);

	var handles := PackedVector3Array()

	handles.push_back(left);
	handles.push_back(right);

	gizmo.add_lines(lines, get_material("main", gizmo), false)
	gizmo.add_handles(handles, get_material("handles", gizmo), [])
	pass;
