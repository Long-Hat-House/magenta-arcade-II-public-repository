class_name FileManager

class FileInfo extends RefCounted:
	var file_name:String
	var device_name:String
	var modification_unix_time:int

	func _to_string() -> String:
		var date = Time.get_datetime_string_from_unix_time(modification_unix_time)
		return "FileInfo(%s on %s at %s [%s])" % [file_name, device_name, date, modification_unix_time]
		
class ConflictResolver extends RefCounted:
	func resolve_file_conflicts(file_infos:Array[FileInfo], on_conflict_resolved_callback:Callable):
		var selected_file = file_infos.reduce(get_most_recent_file)

		print("[FileManager - Default ConflictResolver] Selected most recent file: " + str(selected_file))
		on_conflict_resolved_callback.call(selected_file)

	func get_most_recent_file(file1:FileInfo, file2:FileInfo) -> FileInfo:
		return file1 if file1.modification_unix_time > file2.modification_unix_time else file2

static var _main_system:FileSystem
static var _conflict_resolver:ConflictResolver = ConflictResolver.new()
static var _files_changed_externally_callback:Callable = func(file_info:FileInfo): print("[FileManager] File has changed externally! " + str(file_info))

static func set_conflict_resolver(resolver:ConflictResolver):
	_conflict_resolver = resolver

static func resolve_file_conflicts(file_infos:Array[FileInfo], on_conflict_resolved_callback:Callable):
	if !_conflict_resolver:
		printerr("[FileManager] No Conflict Resolver found!")
		return

	_conflict_resolver.resolve_file_conflicts(file_infos, on_conflict_resolved_callback)

static func set_files_changed_externally_callback(callback:Callable):
	_files_changed_externally_callback = callback

static func call_file_changed_externally_callback(file_info:FileInfo):
	if _files_changed_externally_callback:
		_files_changed_externally_callback.call(file_info)

static func set_main_system(system:FileSystem) -> void:
	_main_system = system

static func get_data(file_name:String, success_callback:Callable, fail_callback:Callable):
	if !_main_system:
		fail_callback.call("File System not defined when loading file: {0}".format([file_name]))
		return

	_main_system._get_data(file_name, success_callback, fail_callback)

static func save_data(file_name:String, data:String, success_callback:Callable, fail_callback:Callable):
	if !_main_system:
		fail_callback.call("File System not defined when saving file: {0}".format([file_name]))
		return

	_main_system._save_data(file_name, data, success_callback, fail_callback)

static func clear_data(file_name:String, success_callback:Callable, fail_callback:Callable):
	if !_main_system:
		fail_callback.call("File System not defined when removing file: {0}".format([file_name]))
		return

	_main_system._clear_data(file_name, success_callback, fail_callback)
