@tool
extends GoThroughAllFilesScript

var to_change:Dictionary[String, Resource]
var ignore_path:Array[String] = [
	"editor_scripts"
]

var to_delete:Array[String] = [
	"ase",
	"aseprite",
	"bnk",
]
func get_name()->String:
	return "Deleting all assets!"
	
func start():
	to_change = {
		"glb" : preload("res://editor_scripts/suzanne_blender_monkey.glb"),
		"png" : preload("res://editor_scripts/base_texture.png"),
	}


func for_every_file(path:String, file_name:String):
	for ignore:String in ignore_path:
		if path.contains(ignore):
			print_rich("[color=cyan]Ignoring [/color]%s" % [path + file_name]);
			return;
			
	var extension:String = file_name.get_extension();
	if extension in to_delete:
		print_rich("[color=red]Deleting [/color]%s!" % [path+file_name]);
		print(OS.move_to_trash(path+file_name));
		print(DirAccess.remove_absolute(path + file_name));
	elif extension in to_change.keys():
		print_rich("[color=white]Changing [/color]%s to %s!" % [path+file_name, to_change[extension]]);
		var loaded = ResourceLoader.load(path + file_name);
		print(ResourceSaver.save(to_change[extension], path + file_name));
