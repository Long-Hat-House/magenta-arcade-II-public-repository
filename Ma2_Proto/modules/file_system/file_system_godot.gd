class_name FileSystemGodot extends FileSystem

func _file_path(file_name:String) -> String:
	return "user://" + file_name

func _get_data(file_name:String, success_callback:Callable, fail_callback:Callable):
	var path = _file_path(file_name)

	if !FileAccess.file_exists(path):
		success_callback.call("")
		return

	var access:FileAccess = FileAccess.open(path, FileAccess.READ)
	if !access:
		fail_callback.call("Error loading file: {0}.\nError: {1}".format([file_name, FileAccess.get_open_error()]))
		return

	var data = access.get_as_text()
	access.close()
	success_callback.call(data)

func _save_data(file_name:String, data:String, success_callback:Callable, fail_callback:Callable):
	var path = _file_path(file_name)

	var access:FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if !access:
		fail_callback.call("Error opening file: {0}.\nError: {1}".format([file_name, FileAccess.get_open_error()]))
		return

	access.store_line(data)
	access.close()
	success_callback.call()

func _clear_data(file_name:String, success_callback:Callable, fail_callback:Callable):
	var path = _file_path(file_name)

	if !FileAccess.file_exists(path):
		fail_callback.call("File {0} doesn't exist.".format([file_name]))
		return

	var access:FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if !access:
		fail_callback.call("Error opening file: {0}.\nError: {1}".format([file_name, FileAccess.get_open_error()]))
		return

	access.store_line("")
	access.close()
	success_callback.call()
