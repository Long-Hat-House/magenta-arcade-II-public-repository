@tool
class_name CreditsInfo extends Resource

@export var reimport:bool = false:
	set (val):
		reimport = val
		_reimport()

@export var sheet_sets:SheetData
@export var sheet_entries:SheetData

@export var sections_list:Array[CreditsSectionInfo]

func _reimport():
	if !sheet_sets || !sheet_entries:
		print("[Credits Info Reimport] No sheets!")
		return

	if sheet_sets.fields.size() == 0 || sheet_entries.fields.size() == 0:
		print("[Credits Info Reimport] No columns!")
		return

	if sheet_sets.rows.size() == 0 || sheet_entries.rows.size() == 0:
		print("[Credits Info Reimport] No data!")
		return

	sheet_sets.reimport()
	sheet_entries.reimport()

	print("[Credits Info Reimport] Will reimport")
	sections_list = []
	var sections_dict:Dictionary[String, CreditsSectionInfo]

	for row in sheet_sets.rows:
		var set_info:CreditsSectionInfo = CreditsSectionInfo.new()
		for key in row:
			_set_key_for_object(set_info, key, row[key], sections_dict)

	for row in sheet_entries.rows:
		var entry_info:CreditsEntryInfo = CreditsEntryInfo.new()
		for key in row:
			_set_key_for_object(entry_info, key, row[key], sections_dict)

func _set_key_for_object(obj, key:String, val:String, sections_dict:Dictionary[String, CreditsSectionInfo]):
	if val.is_empty():
		return
	if key is String:
		print("TRYING: '" + key + "', with value: '" + val + "'")
		if key == "set_id":
			print("-> SET ID FOUND")
			if obj is CreditsSectionInfo:
				sections_dict[val] = obj
				sections_list.append(obj)
				print("--> ADDED TO SECTIONS")
			elif obj is CreditsEntryInfo:
				if sections_dict.has(val):
					sections_dict[val].entries_list.append(obj)
					print("--> ADDED TO ENTRIES")
				else:
					printerr("--> SECTION NOT EVENT FOUND!")
					return
		else:
			var resource:bool = key.begins_with("@")
			key = key.trim_prefix("@")
			if key in obj:
				if resource:
					print("-> IMPORTING RESOURCE")
					obj[key] = load(val)
				else:
					print("-> IMPORTING TEXT")
					obj[key] = val
			else:
				print("-> FAIL: key '" + key + "' not part of credits section!")
