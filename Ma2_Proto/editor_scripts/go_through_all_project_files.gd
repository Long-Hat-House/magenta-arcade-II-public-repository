@tool
class_name GoThroughAllFilesScript extends EditorScript

func get_name():
	return "Go through all files!"

func start():
	pass;

func for_every_file(path:String, file:String):
	pass;		

func _run():
	print();
	print("== Running: %s ==" % get_name());
	# Get the EditorInterface and FileSystem
	var editor_interface = get_editor_interface()
	var file_system = editor_interface.get_resource_filesystem()
	
	# Get all files in the filesystem
	var files := file_system.get_filesystem()
	
	# Recursive function to traverse the directory structure
	start();
	_traverse_filesystem(files)
		

# This function traverses the virtual filesystem to find all .ase files
func _traverse_filesystem(files:EditorFileSystemDirectory):
	for index_dir:int in range(files.get_subdir_count()):
		var sub_dir:EditorFileSystemDirectory = files.get_subdir(index_dir);
		_traverse_filesystem(sub_dir);
	for index_file:int in range(files.get_file_count()):
		var file_name:String = files.get_file(index_file);
	
		for_every_file(files.get_path(), file_name);
