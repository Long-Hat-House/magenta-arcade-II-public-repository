extends Node

@export var material_shutdown:Material;

func all_meshes(node:Node3D, method:Callable):
	for child:Node in node.get_children():
		if child is Node3D:
			if child is MeshInstance3D:
				method.call(child as MeshInstance3D);
			all_meshes(child, method);


func set_material(mesh:MeshInstance3D, with_material:bool):
	print("DEACTIVATED ROBOTO set %s -> %s" % [mesh, with_material]);
	if with_material:
		mesh.material_overlay = material_shutdown;
	else:
		mesh.material_overlay = null;

var deactivated_enemies:Array[Node3D];

func activate(node:Node3D):
	if is_instance_valid(node):
		node.process_mode = Node.PROCESS_MODE_INHERIT;
		all_meshes(node, set_material.bind(false));
		deactivated_enemies.erase(node);
	
	
func deactivate(node:Node3D):
	node.process_mode = Node.PROCESS_MODE_DISABLED;
	all_meshes(node, set_material.bind(true));
	deactivated_enemies.push_back(node);
	node.tree_exiting.connect(func():
		deactivated_enemies.erase(node);
		, CONNECT_ONE_SHOT);

func get_free_enemy()->Node3D:
	var to_delete:int = -1;
	for i:int in range(deactivated_enemies.size()):
		if is_instance_valid(deactivated_enemies[i]):
			
			if to_delete != -1:
				deactivated_enemies.remove_at(to_delete);
			
			return deactivated_enemies[i];
		else:
			to_delete = i;
		
	if to_delete != -1:
		deactivated_enemies.remove_at(to_delete);
	
	return null;
