extends Marker3D

@export var projectile:PackedScene;

signal instantiated(proj_node:Node3D);

func get_projectile()->PackedScene:
	return projectile;
	
func instantiated_here(proj:Node3D):
	instantiated.emit(proj);
