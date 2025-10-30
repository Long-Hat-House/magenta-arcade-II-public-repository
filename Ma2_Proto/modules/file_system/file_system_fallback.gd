class_name FileSystemFallback extends FileSystem


var main_file_system: FileSystem
var fallback_file_system: FileSystem


func _get_data(file_name:String, success_callback:Callable, fail_callback:Callable):
	print("FILE SYSTEM FALLBACK - _get_data: " + file_name)
	
	var _success = func(data: String):
		if data.is_empty():
			fallback_file_system._get_data(file_name, success_callback, fail_callback)
		else:
			success_callback.call(data)
	
	var _fail = func(error: String):
		fallback_file_system._get_data(file_name, success_callback, fail_callback)
	
	main_file_system._get_data(file_name, _success, _fail)


func _save_data(file_name:String, data:String, success_callback:Callable, fail_callback:Callable):
	var _fail = func(error: String):
		fallback_file_system._save_data(file_name, data, success_callback, fail_callback)
	
	main_file_system._save_data(file_name, data, success_callback, _fail)


func _clear_data(file_name:String, success_callback:Callable, fail_callback:Callable):
	fallback_file_system._clear_data(file_name, Callable(), Callable())
	main_file_system._clear_data(file_name, success_callback, fail_callback)
