@tool
extends EditorPlugin

var import_plugin
var sheed_data_inspector

func _enter_tree():
	import_plugin = preload("csv_import_plugin.gd").new()
	add_import_plugin(import_plugin)

	# 2. Add the custom inspector
	sheed_data_inspector = preload("sheet_data_inspector.gd").new()
	add_inspector_plugin(sheed_data_inspector)

func _exit_tree():
	remove_import_plugin(import_plugin)
	import_plugin = null

	# 2. Remove the custom inspector
	remove_inspector_plugin(sheed_data_inspector)
