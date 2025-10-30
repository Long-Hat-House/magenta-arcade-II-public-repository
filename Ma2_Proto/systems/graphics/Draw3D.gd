class_name Draw3D

static func line(parent:Node, pos1: Vector3, pos2: Vector3, color:Color = Color.WHITE_SMOKE, persist_ms:int = 0) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new();
	var immediate_mesh := ImmediateMesh.new();
	var material := ORMMaterial3D.new();
	
	mesh_instance.mesh = immediate_mesh;
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material);
	immediate_mesh.surface_add_vertex(pos1);
	immediate_mesh.surface_add_vertex(pos2);
	immediate_mesh.surface_end();
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;
	material.albedo_color = color;
	
	parent.add_child(mesh_instance)
	if persist_ms:
		await parent.get_tree().create_timer(persist_ms).timeout
		mesh_instance.queue_free()
		return null;
	else:
		return mesh_instance
		

static func make_capsule(height:float, material:ORMMaterial3D, radius:float = 0.5) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new();
	var capsule_mesh := CapsuleMesh.new();
	
	mesh_instance.mesh = capsule_mesh;
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;

	capsule_mesh.height = height;
	capsule_mesh.radius = radius;
	capsule_mesh.rings = 2;
	
	capsule_mesh.material = material;
	mesh_instance.name = "capsule_made";
	
	return mesh_instance;
		
static func make_capsule_line(parent:Node, pos1:Vector3, pos2:Vector3, material:ORMMaterial3D, radius:float = 0.5) -> MeshInstance3D:
	var capsule = make_capsule((pos2 - pos1).length(), material, radius);
	parent.add_child(capsule); #this should happen before move or else move wont work
	move_capsule_line(capsule, pos1, pos2, false);
	return capsule;
	
static func move_capsule_line(capsule:MeshInstance3D, pos1:Vector3, pos2:Vector3, changeLength:bool = true):
	var rot:Quaternion = Quaternion.from_euler(Vector3(90,0,0));
	var trans:Transform3D = capsule.global_transform;
	print("brefore %s (%s)" % [trans, capsule.global_transform]);
	trans.basis = Math.apply_quaternion_to_basis(capsule.global_transform.basis.looking_at(pos2 - pos1, Vector3.UP, false), rot);
	capsule.global_transform.basis = trans.basis;
	capsule.global_transform.origin = (pos1 + pos2) * 0.5;
	print("after %s (%s)" % [trans, capsule.global_transform]);
		
