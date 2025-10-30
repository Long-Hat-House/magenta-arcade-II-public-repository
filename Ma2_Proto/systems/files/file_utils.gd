class_name FileUtils

static func get_all_files(path: String, file_ext := "", get_file_path := false, files := []):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()

		var file_name = dir.get_next()

		while file_name != "":
			if dir.current_is_dir():
				files = get_all_files(\
					dir.get_current_dir() + "/" + (file_name),\
					file_ext,\
					get_file_path,\
					files)
			else:
				if file_ext and file_name.get_extension() != file_ext:
					file_name = dir.get_next()
					continue
					
				files.append(dir.get_current_dir() + "/" + file_name)

			file_name = dir.get_next()
	else:
		print_debug("[FILE UTILS] Error when trying to access %s." % path)
		print_debug(DirAccess.get_open_error())

	return files
