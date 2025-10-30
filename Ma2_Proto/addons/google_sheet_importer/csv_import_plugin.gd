## import_plugin.gd
#@tool
#extends EditorImportPlugin
#
#var _file_system: EditorFileSystem
#
#var _importing:bool
#var _waiting_request:bool
#var _data_buffer:String
#
#enum Presets {
	#DEFAULT = 0,
	 #}
#
#func _get_importer_name():
	#return "lhh.googlesheet"
#
#func _get_import_order() -> int:
	#return 0
	#
#func _get_priority() -> float:
	#return 1.0
#
#func _get_visible_name():
	#return "Google Sheet CSV"
#
#func _get_recognized_extensions():
	#return ["googlesheet"]
#
#func _get_save_extension():
	#return "csv"
#
#func _get_resource_type():
	#return "Resource"
	#
#func _get_preset_count():
	#return Presets.size()
	#
#func _get_preset_name(preset_index):
	#match preset_index:
		#Presets.DEFAULT:
			#return "Default"
		#_:
			#return "Unknown"
#
#func _get_import_options(path, preset_index):
	#match preset_index:
		#Presets.DEFAULT:
			#return [{
					   #"name": "spreadsheet_id",
					   #"default_value": "0123"
					#},
					#{
					   #"name": "sheet_id",
					   #"default_value": "main"
					#},
					#]
		#_:
			#return []
			#
#func _get_option_visibility(path, option_name, options):
	#return true
#
#func _import(source_file, save_path, options, r_platform_variants, r_gen_files):
	#print("Started Importing: " + source_file)
	#if _importing:
		#print("Already Importing!")
		##return
	#_importing = true
	#_file_system = EditorInterface.get_resource_filesystem()
	#
##	var input_file = FileAccess.open(source_file, FileAccess.READ)
##	if input_file == null:
##		print("Finishing with error")
##		return FileAccess.get_open_error()
	#
	#if await _http_requset(options.spreadsheet_id, options.sheet_id) != OK:
		#return;
#
	#var full_save_path:String = source_file.get_slice('.', 0) + "." +_get_save_extension()
	#var save_file = FileAccess.open(full_save_path, FileAccess.WRITE)
	#if save_file == null:
		#print("Finishing with error")
		#return FileAccess.get_open_error()
		#
	#save_file.store_string(_data_buffer)
	#save_file.flush()
	#
	##_file_system.scan()
	#save_file.close()
	#
	##_file_system.update_file(full_save_path)
	#_importing = false
	#r_gen_files.push_back(full_save_path)
	#_file_system.scan()
	#print("Finished Importing Sheet: " + source_file + " \nInto File: " + full_save_path)
	#return

@tool
extends EditorImportPlugin

func _get_importer_name():
	return "lhh_googlesheet_translation"

func _get_import_order() -> int:
	return 0

func _get_priority() -> float:
	return 1.0

func _get_visible_name():
	return "Google Sheet Translation"

func _get_recognized_extensions():
	return ["sheet"]

func _get_option_visibility(path, option_name, options):
	return true

func _get_save_extension():
	return ""

func _get_resource_type():
	return "Translation"

func _get_preset_count():
	return 0

func _get_preset_name(preset_index):
	return ""


func _get_import_options(path, preset_index):
	return [{
			   "name": "spreadsheet_id",
			   "default_value": ""
			},
			{
			   "name": "sheet_id",
			   "default_value": ""
			},
			]

func _import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var delimiter:String = ","

	var stri:String = "asdasd"

	var f = FileAccess.open(source_file, FileAccess.WRITE)
	if f == null:
		printerr("Import error: Could not open source file (for writing) " + source_file)
		return FileAccess.get_open_error()

	var err = await _request_sheets_data(options.spreadsheet_id, options.sheet_id)
	if err:
		print("Import error: Something wrong for the request")
		return

	f.store_string(_data_buffer)
	f.flush()
	f.close()

	f = FileAccess.open(source_file, FileAccess.READ)
	if f == null:
		printerr("Import error: Could not open source file (for reading) " + source_file)
		return FileAccess.get_open_error()

	var line:PackedStringArray = f.get_csv_line(delimiter)

	var locales:Array[String];
	var translations:Array[Translation];
	var skipped_locales:Dictionary;

	var line_check:String = line[0].strip_edges().to_lower()
	if line_check != "key" && line_check != "keys":
		printerr("First cell and column of sheet must be 'key' so the importer knows the request went correctly. Found '%s'. (%s)" % [line_check, source_file])
		return

	for i in range(1, line.size()):
		var locale:String = TranslationServer.standardize_locale(line[i])

		if line[i].left(1) == "_":
			skipped_locales[i] = true
			continue;
		elif locale.is_empty():
			skipped_locales[i] = true
			printerr(str("Error importing CSV translation: Invalid locale format '%s', should be 'language_Script_COUNTRY_VARIANT@extra'. This column will be ignored.", line[i]))

		locales.push_back(locale);
		var translation:Translation;
		translation = Translation.new()
		translation.locale = locale;
		translations.push_back(translation);

	while !f.eof_reached():
		line = f.get_csv_line(delimiter)
		var key:String = line[0];
		if !key.is_empty():
			if line.size() != (locales.size() + skipped_locales.size() + 1):
				printerr(str("Error importing CSV translation: expected %d locale(s), but the '%s' key has %d locale(s).", locales.size(), key, line.size() - 1))

			var write_index:int = 0 # Keep track of translations written in case some locales are skipped.
			for i in range(1, line.size()):
				if skipped_locales.has(i):
					continue
				translations[write_index].add_message(key, line[i].c_unescape())
				write_index += 1

	for i in range(0, translations.size()):
		var xlt:Translation = translations[i];

		#if (compress) {
			#Ref<OptimizedTranslation> cxl = memnew(OptimizedTranslation);
			#cxl->generate(xlt);
			#xlt = cxl;
		#}

		var new_save_path:String = source_file.get_basename() + "." + translations[i].locale + ".translation"

		ResourceSaver.save(xlt, new_save_path)
		r_gen_files.push_back(new_save_path)

	return OK;

var _waiting_request:bool
var _data_buffer:String

func _request_sheets_data(spreadsheet_id:String, sheet_id:String) -> Error:
	if spreadsheet_id.is_empty():
		return FAILED

	print("Starting Request!")
	if _waiting_request:
		print("Already Requesting!")
	_waiting_request = true
	var root = EditorInterface.get_edited_scene_root()
	var tree = null
	if root:
		tree = EditorInterface.get_edited_scene_root().get_tree()
		if not tree:
			push_error("Does not have a tree! Open a scene before reimporting the translations.sheet, please!");
			return FAILED;
	else:
		push_error("Does not have a root! Open a scene before reimporting the translations.sheet, please!");
		return FAILED;
	var http_request = HTTPRequest.new()
	tree.root.add_child(http_request)
	http_request.request_completed.connect(self.on_import_completed.bind("main"))
	var desired_url = get_spreadsheet_url(spreadsheet_id,sheet_id)

	var error = http_request.request(desired_url)
	if error != OK:
		push_error("An error occurred in the HTTP request.")

	while _waiting_request:
		print("Waiting Request!")
		await tree.process_frame

	print("Finishing up!")
	http_request.queue_free()
	_waiting_request = false
	return error

func on_import_completed(result, response_code, headers, body, sheet_id):
	_data_buffer = body.get_string_from_utf8()
	print("DATA: =====================\n" + _data_buffer.substr(0, 300) + ("\n..." if _data_buffer.length()> 300 else "") + "\n ========================")
	_waiting_request = false

func get_spreadsheet_url(spreadsheet_id:String, sheet_id:String) -> String:
	return "https://docs.google.com/a/google.com/spreadsheets/d/{0}/gviz/tq?tqx=out:csv&sheet={1}".format({0:spreadsheet_id,1: sheet_id});
