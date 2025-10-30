class_name Graphic_SnakeBody extends LHH3D

@export var fine_material:Material;
@export var broken_material:Material;
@export var meshes:Array[MeshInstance3D]

func set_broken(broken:bool):
	for mesh in meshes:
		mesh.set_surface_override_material(0, broken_material if broken else fine_material);
