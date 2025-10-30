# Save this script as an EditorScript (e.g., res://process_tres.gd)
@tool
extends GoThroughAllFilesScript

var shading_mode_from:StandardMaterial3D.ShadingMode = StandardMaterial3D.ShadingMode.SHADING_MODE_PER_PIXEL;
var shading_mode_to:StandardMaterial3D.ShadingMode = StandardMaterial3D.ShadingMode.SHADING_MODE_PER_VERTEX;

var count:int = 0;

func get_name()->String:
	return "Making all materials vector illumination!"
	
func start():
	count = 0;

func for_every_file(path:String, file_name:String):
	if file_name.ends_with(".tres"):
		var resource = ResourceLoader.load(path + file_name)
		if resource is StandardMaterial3D:
			if !resource.normal_enabled and resource.shading_mode == shading_mode_from:
				count += 1;
				print("\tChanged %s:%s%s!" % [count, path, file_name]);
				resource.shading_mode = shading_mode_to;
				ResourceSaver.save(resource, path+file_name);
