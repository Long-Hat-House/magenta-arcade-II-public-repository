extends Node

signal active_save_changed(new_save:GameSave)
signal active_save_will_change(old_save:GameSave)

const _GAME_SETTINGS_NAME:StringName = &"game_settings"
const GAME_SAVE_WARNING = preload("res://modules/game_save_system/game_save_warning.tscn")

class PromptConflictResolver extends FileManager.ConflictResolver:
	var resolver_enabled:bool = true
	var _solving_conflicts:Dictionary[String, bool]

	func resolve_file_conflicts(file_infos:Array[FileInfo], on_conflict_resolved_callback:Callable):
		var filename:String = file_infos[0].file_name

		print("[GaneSaveManager - Prompt ConflictResolver] "+filename+" Recieved nfiles:" + str(file_infos.size()))

		if filename == _GAME_SETTINGS_NAME:
			var selected_file:FileInfo = file_infos.reduce(get_most_recent_file)
			print("[GaneSaveManager - Prompt ConflictResolver] It was settings, Selected most recent file: " + str(selected_file))
			on_conflict_resolved_callback.call(selected_file)
			return

		if !resolver_enabled:
			print("[GaneSaveManager - Prompt ConflictResolver] Not Resolving Now")
			return

		if _solving_conflicts.has(filename):
			print("[PromptConflictResolver] Already had conflict with filename:" + filename)
			return

		print("[GaneSaveManager - Prompt ConflictResolver] Will Resolve")

		_solving_conflicts[filename] = true

		var prompt_entries:Array[PromptWindow.PromptEntry]

		var i:int = 0
		for info in file_infos:
			prompt_entries.append(
				PromptWindow.PromptEntry.CreateButton(
					info.device_name + "\n" +
					Time.get_date_string_from_unix_time(info.modification_unix_time) + "\n" +
					Time.get_time_string_from_unix_time(info.modification_unix_time)
					)
			)
			i += 1

		PromptWindow.new_prompt_advanced(
			"File Conflict!",
			"File '" + filename + "' has conflicted, choose which file to keep from the following options",
			func(id:int):
				var selected_file:FileInfo = file_infos[id]
				print("[GaneSaveManager - Prompt ConflictResolver] Selected file: " + str(id) + str(selected_file))
				on_conflict_resolved_callback.call(selected_file)
				_solving_conflicts.erase(filename)
				SaveManager.reload_game_saves()
				,
			prompt_entries, false
				)

var conflict_resolver:PromptConflictResolver
var _active_save:StringName

var available_saves:Dictionary[StringName, GameSave]

var _is_ready:bool

func reload_game_saves(include_settings:bool = false):
	print("[GANE SAVE MANAGER] Reloading game saves, include_settings: "+str(include_settings))
	for save in available_saves:
		if !include_settings && save == _GAME_SETTINGS_NAME:
			continue
		available_saves[save].reload()

func get_save_by_name(save_name:StringName) -> GameSave:
	if save_name.is_empty():
		return null

	print("[GANE SAVE MANAGER] Getting Save By Name: "+str(save_name))
	var s:GameSave
	if available_saves.has(save_name):
		s = available_saves[save_name]
	else:
		s = GameSave.new()
		add_child(s)
		available_saves[save_name] = s
		s.load_from_file(save_name)

	while !s.is_data_ready():
		print("[GANE SAVE MANAGER] Getting Save By Name Waiting Data: "+str(save_name))
		await get_tree().process_frame
		if !is_instance_valid(self):
			return null

	return s

func set_active_save(new_active_save_name:StringName):
	var old_save:GameSave = await get_save_by_name(_active_save)
	if !is_instance_valid(self):
		return

	var new_save:GameSave = await get_save_by_name(new_active_save_name)
	if !is_instance_valid(self):
		return

	active_save_will_change.emit(old_save)
	_active_save = new_active_save_name
	active_save_changed.emit(new_save)

func use_save(callback:Callable):
	while _active_save.is_empty():
		await get_tree().process_frame
		if !is_instance_valid(self):
			return

	use_save_by_name(_active_save, callback)

func use_settings(callback:Callable):
	use_save_by_name(_GAME_SETTINGS_NAME, callback)

func use_save_by_name(save_name:StringName, callback:Callable):
	while !_is_ready:
		print("[GAME SAVE MANAGER] Use Save Waiting Ready: " + save_name)
		await get_tree().process_frame
		if !is_instance_valid(self):
			return

	var s:GameSave = await get_save_by_name(save_name)
	if !is_instance_valid(self):
		return

	if callback:
		callback.call(s)

func _ready() -> void:
	print("[GAME SAVE MANAGER] Readying!")
	process_mode = Node.PROCESS_MODE_ALWAYS

	print("[GAME SAVE MANAGER] Starting File System!")
	conflict_resolver = PromptConflictResolver.new()
	FileManager.set_conflict_resolver(conflict_resolver)
	if !FileManager._main_system:
		var file_system = FileSystemFallback.new()
		file_system.main_file_system = FileSystemSocial.new()
		file_system.fallback_file_system = FileSystemGodot.new()
		FileManager.set_main_system(file_system)

	_is_ready = true

func save() -> void:
	print("[GAME SAVE MANAGER] Will save!")
	var save_warning = GAME_SAVE_WARNING.instantiate()

	var target_time = Time.get_ticks_msec() + 1000

	if save_warning is Switch_Oning_Offing_AnimationPlayer:
		save_warning.set_switch(true)

	for game_save in available_saves.values():
		game_save.save_to_file()

		while game_save.is_saving():
			print("[GAME SAVE MANAGER] Saving: " + game_save.get_file_name())
			await get_tree().process_frame
			if !is_instance_valid(self):
				return

	print("[GAME SAVE MANAGER] Saved all!")
	if save_warning is Switch_Oning_Offing_AnimationPlayer:
		while Time.get_ticks_msec() < target_time:
			await get_tree().process_frame
			if !is_instance_valid(save_warning):
				return
		save_warning.turned_off.connect(func(): save_warning.queue_free())
		save_warning.set_switch(false)
	else:
		save_warning.queue_free()

func _notification(what: int) -> void:
	var should_save:bool = false
	var should_quit:bool = false

	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		should_save = true
		should_quit = true
		print("[GAME SAVE MANAGER] Quit requested!")

	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		should_save = false
		print("[GAME SAVE MANAGER] Back requested! Will ignore because the game doesn't respond to back")

	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		should_save = true
		print("[GAME SAVE MANAGER] App out of focus!")

	if should_save:
		# do save stuff here
		await save()
		if !is_instance_valid(self):
			return

	if should_quit:
		print("[GAME SAVE MANAGER] Will quit!")
		get_tree().quit()
