class_name GameSave extends Node

signal loading_started()
signal loading_finished()

var _filename:StringName
var _data:Dictionary

var _is_data_ready:bool = false
var _is_dirty:bool = false

var _is_saving:int = 0
var _is_loading:bool = false

func is_saving() -> bool:
	return _is_saving > 0

func is_loading() -> bool:
	return _is_loading

func is_data_ready() -> bool:
	return _is_data_ready

func is_empty() -> bool:
	if !_is_data_ready:
		printerr("[GameSave] Using Game Save before it's ready")
		return false

	return _data.is_empty()

func get_file_name() -> String:
	return _filename

func clear_save():
	_data.clear()
	_log_save("[GameSave] clear_save " + _filename + " _is_dirty TRUE")
	_is_dirty = true
	save_to_file()

func has_data(key:StringName) -> bool:
	if !_is_data_ready:
		printerr("[GameSave] Using Game Save before it's ready")
		return false

	return _data.has(key)

func get_data(key:StringName, default_data:String = "") -> String:
	if !_is_data_ready:
		printerr("[GameSave] Using Game Save before it's ready")
		return ""

	if has_data(key): return _data[key]
	else: return default_data

## Gets data and then, if there's anything, return the result of json_parse_string or null
func get_json_parsed_data(key:StringName, default_data:String = ""):
	var data = get_data(key, default_data)
	if data:
		data = JSON.parse_string(data)
	return data

func set_data(key:StringName, value:String, avoid_log:bool = false):
	if !avoid_log:
		_log_save("[GameSave] Setting {1} = {2}".format({"1":key, "2":value}))

	if !_is_data_ready:
		printerr("[GameSave] Using Game Save before it's ready")
		return ""

	if !has_data(key) || get_data(key) != value:
		if !avoid_log:
			_log_save("[GameSave] Gonna set!")

		if !_is_dirty:
			_log_save("[GameSave] set_data " + _filename + " _is_dirty TRUE (became)")
		_is_dirty = true
		_data[key] = value

func reload():
	load_from_file(_filename)

func load_from_file(filename:StringName):
	_log_save("[GameSave] load_from_file %s" % filename)
	loading_started.emit()

	if _is_loading:
		printerr("[GameSave] Trying to load a file when it's already loading: " + filename)
		return

	if _is_dirty:
		_log_save("[GameSave] Trying to load a file over a game save that is dirty: " + filename)
		if !is_saving(): save_to_file()
		while _is_dirty:
			_log_save("[GameSave] " + filename + " waiting dirty, _is_data_ready(%s), _is_dirty(%s), _is_loading(%s)" % [
				_is_data_ready, _is_dirty, _is_loading
			])
			await get_tree().process_frame

	_log_save("[GameSave] " + filename + " _is_data_ready FALSE")
	_log_save("[GameSave] " + filename + " _is_dirty FALSE")
	_log_save("[GameSave] " + filename + " _is_loading TRUE")
	_is_data_ready = false
	_is_dirty = false
	_is_loading = true
	_data.clear()
	_filename = filename

	_log_save("[GameSave] " + filename + " NOW will load")
	FileManager.get_data(_filename, _on_data_loaded, _on_data_load_failed)

## Leave file empty to use this save's _filename. Or use a different file name to save a copy
func save_to_file(filename:StringName = &""):
	filename = _filename if filename.is_empty() else filename

	_log_save("[GameSave] " + _filename + " save_to_file %s" % filename)

	if !_is_data_ready:
		printerr("[GameSave] " + filename + " Saving Game Save before it's ready")
		return ""

	if _is_loading:
		printerr("[GameSave] " + filename + " Saving Save Game while still loading")
		return ""

	if !_is_dirty:
		return

	_log_save("[GameSave] " + filename + " _is_dirty FALSE")
	_is_dirty = false
	_is_saving += 1
	FileManager.save_data(filename, JSON.stringify(_data), _on_data_saved, _on_data_save_failed)

func _on_data_saved():
	_is_saving -= 1
	_log_save("[GameSave] SAVED ({missing}): {file}, with {n_entries} entries!".format({
		"missing": str(_is_saving),
		"file": _filename,
		"n_entries": _data.size()
		}))

func _on_data_save_failed(error:String):
	_log_save("[GameSave] " + _filename + " _is_dirty TRUE")
	_is_saving -= 1
	_is_dirty = true

	PromptWindow.new_prompt("Save Failed: {file}".format({"file":_filename}), error)
	_log_save("[GameSave] SAVE FAILED: {file}".format({"file": _filename}))

func _on_data_loaded(data:String):
	if !data.is_empty():
		_data = JSON.parse_string(data)
	else:
		_data = Dictionary()

	_log_save("[GameSave] " + _filename + " _is_loading FALSE")
	_log_save("[GameSave] " + _filename + " _is_data_ready TRUE")
	_is_loading = false
	_is_data_ready = true
	_log_save("[GameSave] LOADED: {file}, with {n_entries} entries!".format({"file": _filename, "n_entries": _data.size()}))
	loading_finished.emit()

func _on_data_load_failed(error:String):
	_log_save("[GameSave] " + _filename + " _is_loading FALSE")
	_is_loading = false
	PromptWindow.new_prompt("Load Failed: {file}".format({"file":_filename}), error)
	_log_save("[GameSave] LOAD FAILED: {file}".format({"file": _filename}))

func _log_save(string:String):
	if DevManager.get_setting(DevManager.SETTING_LOG_SAVE, true):
		print(string)
