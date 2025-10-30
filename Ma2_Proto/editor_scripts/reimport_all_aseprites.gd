@tool
extends EditorScript

func _run():
	print();
	print("== Running Reimport all .ase! ==");
	# Get the EditorInterface and FileSystem
	var editor_interface = get_editor_interface()
	var file_system = editor_interface.get_resource_filesystem()
	
	# Get all files in the filesystem
	var files := file_system.get_filesystem()
	
	# List to store paths of .ase files
	var ase_files:PackedStringArray = []
	
	# Recursive function to traverse the directory structure
	traverse_filesystem(files, ase_files)
	
	print("Found %d .ase files to reimport." % ase_files.size())
	
	# Reimport each found .ase file
	for file_path in ase_files:
		print("Reimporting: ", file_path)
		
	file_system.reimport_files(ase_files);
		#file_system.reimport_file(file_path)

func condition(file_path:String, file_name:String)->bool:
	var extension:String = file_name.get_extension().to_lower() 
	return extension.contains("ase");

# This function traverses the virtual filesystem to find all .ase files
func traverse_filesystem(files:EditorFileSystemDirectory, ase_files:PackedStringArray):
	for index_dir:int in range(files.get_subdir_count()):
		var sub_dir:EditorFileSystemDirectory = files.get_subdir(index_dir);
		traverse_filesystem(sub_dir, ase_files);
	for index_file:int in range(files.get_file_count()):
		var file_name:String = files.get_file(index_file);
	
		# Check if it's an .ase file
		if condition(files.get_path(), file_name):
			## Append
			ase_files.append(files.get_path() + file_name);
