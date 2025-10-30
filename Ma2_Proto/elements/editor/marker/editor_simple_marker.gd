@tool
class_name Editor_SimpleMarker extends LHH3D

@onready var mesh: MeshInstance3D = $MeshInstance3D

var tool_material:Material;

func set_ball_color(color:Color):
	if mesh:
		if not tool_material:
			tool_material = mesh.get_active_material(0).duplicate();
			mesh.set_surface_override_material(0, tool_material);
		tool_material.set("albedo_color", color);
