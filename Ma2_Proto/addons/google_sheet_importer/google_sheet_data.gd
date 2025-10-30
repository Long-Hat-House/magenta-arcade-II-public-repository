# res://addons/google_sheet_importer/sheet_data.gd
@tool
extends Resource
class_name SheetData

## User-configurable properties
@export var spreadsheet_id: String = ""
@export var sheet_id: String = ""

## Data fields
@export_category("Data")
@export var fields: PackedStringArray = []
@export var rows: Array[Dictionary] = []

var _waiting_request: bool = false
var _data_buffer: String = ""

# ----------------------------------------------------------------------
# Public API for Inspector Button
# ----------------------------------------------------------------------
func reimport() -> int:
	# 1) Download CSV
	var err = await _request_sheets_data(spreadsheet_id, sheet_id)
	if err != OK:
		printerr("SheetData Reimport error: failed to request sheet data.")
		return ERR_CANT_CONNECT

	# 2) Process CSV
	err = _process_csv_data()
	if err != OK:
		printerr("SheetData Reimport error: failed to process CSV data.")
		return err

	# 3) Save Resource to disk
	var out_path := get_path()
	if out_path.is_empty():
		push_error("Cannot reimport unsaved SheetData resource.")
		return ERR_UNAVAILABLE

	var err_save: int = ResourceSaver.save(self, out_path)
	if err_save != OK:
		printerr("Failed to save SheetData resource: %s" % out_path)
		return err_save

	print("SheetData Reimport OK: %s" % out_path)
	return OK


# ----------------------------------------------------------------------
# Internal CSV Processing (Copied from original _import logic)
# ----------------------------------------------------------------------
func _process_csv_data() -> int:
	if _data_buffer.strip_edges() == "":
		printerr("Process error: empty data buffer.")
		return ERR_FILE_CORRUPT

	var delimiter := ","
	var lines := _split_csv_lines(_data_buffer)

	if lines.size() == 0:
		printerr("Process error: no lines in CSV data.")
		return ERR_FILE_CORRUPT

	# 3) Lê cabeçalho
	var header: Array = lines[0].split(delimiter)
	var new_fields: Array[String] = []
	var seen := {}
	for i in range(header.size()):
		var raw: String = _unquote_csv_value(header[i])
		var name: String = raw if raw != "" else "column_%d" % i
		if seen.has(name):
			var idx := 2
			var candidate := "%s_%d" % [name, idx]
			while seen.has(candidate):
				idx += 1
				candidate = "%s_%d" % [name, idx]
			name = candidate
		seen[name] = true
		new_fields.push_back(name)

	self.fields = new_fields # Update resource property

	# 4) Lê linhas de dados
	var new_rows: Array[Dictionary] = []
	for j in range(1, lines.size()):
		var line_str := lines[j].strip_edges()
		if line_str == "":
			continue
		var row_vals: Array = line_str.split(delimiter)
		var obj := {}
		for i in range(new_fields.size()):
			var val: String = ""
			if i < row_vals.size():
				val = _unquote_csv_value(row_vals[i])
			obj[new_fields[i]] = val
		new_rows.push_back(obj)

	self.rows = new_rows # Update resource property

	return OK

# ----------------------------------------------------------------------
# Async HTTP Request (Copied from original _request_sheets_data logic)
# ----------------------------------------------------------------------
func _request_sheets_data(spreadsheet_id: String, sheet_id: String) -> int:
	if spreadsheet_id == "":
		printerr("Request error: spreadsheet_id is empty")
		return FAILED

	if _waiting_request:
		printerr("Already requesting a sheet.")
		return FAILED

	_waiting_request = true
	var tree = Engine.get_main_loop() # Use Engine.get_main_loop() for editor context

	var http_request := HTTPRequest.new()
	tree.root.add_child(http_request)
	http_request.request_completed.connect(self._on_import_completed)

	var url := get_spreadsheet_url(spreadsheet_id, sheet_id)
	var err := http_request.request(url)
	if err != OK:
		push_error("HTTP request error.")
		_waiting_request = false
		http_request.queue_free()
		return err

	while _waiting_request:
		await tree.process_frame

	if is_instance_valid(http_request):
		http_request.queue_free()

	return OK

func _on_import_completed(result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	if typeof(body) == TYPE_NIL:
		_data_buffer = ""
	else:
		_data_buffer = body.get_string_from_utf8()
	print("Fetched sheet data (len=%d), response_code=%d" % [_data_buffer.length(), response_code])
	_waiting_request = false
	notify_property_list_changed()

func get_spreadsheet_url(spreadsheet_id: String, sheet_id: String) -> String:
	return "https://docs.google.com/a/google.com/spreadsheets/d/{0}/gviz/tq?tqx=out:csv&sheet={1}".format({0: spreadsheet_id, 1: sheet_id})

func _unquote_csv_value(value: String) -> String:
	# 1. Strip leading/trailing whitespace, then strip the surrounding quotes.
	var result = value.strip_edges()

	if result.begins_with("\"") and result.ends_with("\""):
		# Remove surrounding quotes
		result = result.substr(1, result.length() - 2)

		# Replace escaped quotes ("") with a single quote (")
		result = result.replace("\"\"", "\"")

	# 2. Finally, apply c_unescape for other standard escapes (\n, \t, etc.)
	return result.c_unescape()

func _split_csv_lines(csv_text: String) -> PackedStringArray:
	var lines: PackedStringArray = []
	var current_line: String = ""
	var in_quotes: bool = false

	for i in range(csv_text.length()):
		var char: String = csv_text[i]

		# Toggle quote state if we encounter an unescaped double quote
		if char == "\"":
			# Standard CSV rules: "a""b" means a"b. If we're inside quotes,
			# check for a second quote to skip it (it's escaped).
			if in_quotes and i + 1 < csv_text.length() and csv_text[i + 1] == "\"":
				# It's an escaped quote (""), skip the next character (the second quote)
				current_line += char
				i += 1
				continue

			# Otherwise, it's a quote boundary
			in_quotes = !in_quotes

		# Check for newline
		if char == "\n":
			if in_quotes:
				# Newline is inside quotes, so treat it as part of the data
				current_line += char
			else:
				# Newline is outside quotes, so it's a true row break
				lines.append(current_line.strip_edges())
				current_line = ""
				continue

		# Handle carriage return if present (Windows line endings: \r\n)
		elif char == "\r" and i + 1 < csv_text.length() and csv_text[i + 1] == "\n":
			continue # Skip \r if it precedes \n, \n will handle the split
		elif char != "\r":
			current_line += char

	# Append the last line if the file didn't end with a newline
	if !current_line.is_empty():
		lines.append(current_line.strip_edges())

	return lines
