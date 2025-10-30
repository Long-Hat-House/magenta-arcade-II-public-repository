extends SocialPlatformSystem

const ICON_ACHIEVEMENTS = preload("res://modules/social_platform_system/game_center_icons/icon_achievements.png")
const ICON_LEADERBOARDS = preload("res://modules/social_platform_system/game_center_icons/icon_leaderboards.png")


var game_center: Object:
	get:
		if not _game_center:
			_game_center = Engine.get_singleton("GameCenter")
			assert(_game_center, "[GameCenter] FIXME: GameCenter singleton could not be found. Only iOS platform is supported")
		return _game_center

var _game_center: Object

# Sign in
var _is_authenticated := false
# Achievements
var _achievement_id_map = {
	SocialPlatformManager.Achievement.ACH_START: "ACH_START",
	SocialPlatformManager.Achievement.ACH_BEAT_LVL_1: "ACH_BEAT_LVL_1",
	SocialPlatformManager.Achievement.ACH_BEAT_LVL_2: "ACH_BEAT_LVL_2",
	SocialPlatformManager.Achievement.ACH_BEAT_LVL_3: "ACH_BEAT_LVL_3",
	SocialPlatformManager.Achievement.ACH_BEAT_LVL_4: "ACH_BEAT_LVL_4",
	SocialPlatformManager.Achievement.ACH_BEAT_LVL_5: "ACH_BEAT_LVL_5",
	SocialPlatformManager.Achievement.ACH_ENDING: "ACH_ENDING",
	SocialPlatformManager.Achievement.ACH_BEAT_LVL_ARCADE: "ACH_BEAT_LVL_ARCADE",
	SocialPlatformManager.Achievement.ACH_USE_STAR_1: "ACH_USE_STAR_1",
	SocialPlatformManager.Achievement.ACH_GET_STAR_9: "ACH_GET_STAR_9",
	SocialPlatformManager.Achievement.ACH_GET_STAR_12: "ACH_GET_STAR_12",
	SocialPlatformManager.Achievement.ACH_GET_STAR_18: "ACH_GET_STAR_18",
}
# Leaderboards
var _leaderboard_id_map = {
	SocialPlatformManager.Leaderboard.HS_LVL_1: "HS_LVL_1",
	SocialPlatformManager.Leaderboard.HS_LVL_2: "HS_LVL_2",
	SocialPlatformManager.Leaderboard.HS_LVL_3: "HS_LVL_3",
	SocialPlatformManager.Leaderboard.HS_LVL_4: "HS_LVL_4",
	SocialPlatformManager.Leaderboard.HS_LVL_5: "HS_LVL_5",
	SocialPlatformManager.Leaderboard.HS_LVL_ARCADE: "HS_LVL_ARCADE",
	SocialPlatformManager.Leaderboard.HS_RICHEST: "HS_RICHEST",
}
# Snapshots (cloud save)
var _is_load_snapshots_in_progress := false
var _loading_save_game: Dictionary[String, bool] = {}
var _save_game_success_callbacks: Dictionary[String, Array] = {}  # value is Array[Callable]
var _save_game_failure_callbacks: Dictionary[String, Array] = {}  # value is Array[Callable]
var _load_game_success_callbacks: Dictionary[String, Array] = {}  # value is Array[Callable]
var _load_game_failure_callbacks: Dictionary[String, Array] = {}  # value is Array[Callable]
var _conflicting_saves: Dictionary[String, Array] = {}  # value is Array[GameCenterSavedGame]


func initialize_async() -> void:
	authenticate()
	await user_authenticated


func is_authenticated() -> bool:
	return game_center.is_authenticated()


func authenticate() -> void:
	var result: Error = game_center.authenticate()
	if result != OK:
		printerr("[GameCenter] Authenticate failed: ", error_string(result))
		# Wait for a frame so that initialize_async can catch the emitted signal
		await get_tree().process_frame
		user_authenticated.emit(false)


func unlock_achievement(achievement_id: SocialPlatformManager.Achievement, show_completion_banner: bool = true) -> void:
	if is_authenticated():
		game_center.award_achievement({
			"name": _achievement_id_map[achievement_id],
			"progress": 100,
			"show_completion_banner": show_completion_banner,
		})


func reveal_achievement(achievement_id: SocialPlatformManager.Achievement) -> void:
	if is_authenticated():
		game_center.award_achievement({
			"name": _achievement_id_map[achievement_id],
			"progress": 0,
			"show_completion_banner": true,
		})


func show_all_achievements():
	if is_authenticated():
		game_center.show_game_center({
			"view": "achievements",
		})


func submit_score(leaderboard_id: SocialPlatformManager.Leaderboard, score: int) -> void:
	if is_authenticated():
		game_center.post_score({
			"category": _leaderboard_id_map[leaderboard_id],
			"score": score,
		})


func show_all_leaderboards() -> void:
	if is_authenticated():
		game_center.show_game_center({
			"view": "leaderboards",
		})


func show_leaderboard(leaderboard_id: SocialPlatformManager.Leaderboard) -> void:
	if is_authenticated():
		game_center.show_game_center({
			"view": "leaderboards",
			"leaderboard_name": _leaderboard_id_map[leaderboard_id],
		})

func get_achievements_icon() -> Texture2D:
	return ICON_ACHIEVEMENTS

func get_leaderboards_icon() -> Texture2D:
	return ICON_LEADERBOARDS

func get_leaderboards_text() -> String:
	return "gamecenter_leaderboards"

func get_achievements_text() -> String:
	return "gamecenter_achievements"


func supports_cloud_save() -> bool:
	return is_authenticated()


func get_cloud_save_data(file_name:String, success_callback:Callable, fail_callback:Callable):
	print("[GAME CENTER] get_cloud_save_data: " + file_name)

	_load_game_success_callbacks.get_or_add(file_name, []).append(success_callback)
	_load_game_failure_callbacks.get_or_add(file_name, []).append(fail_callback)
	if not _is_load_snapshots_in_progress and not _loading_save_game.get(file_name, false):
		_is_load_snapshots_in_progress = true
		game_center.fetch_saved_games()


func save_cloud_save_data(file_name:String, data:String, success_callback:Callable, fail_callback:Callable):
	print("[GAME CENTER] save_cloud_save_data: " + file_name)
	
	_save_game_success_callbacks.get_or_add(file_name, []).append(success_callback)
	_save_game_failure_callbacks.get_or_add(file_name, []).append(fail_callback)
	game_center.save_game_data({
		"name": file_name,
		"data": data.to_utf8_buffer(),
	})


func clear_cloud_save_data(file_name:String, success_callback:Callable, fail_callback:Callable):
	# For simplicity, just save empty content instead of deleting snapshot.
	save_cloud_save_data(file_name, "", success_callback, fail_callback)


func _process(delta: float) -> void:
	for i in game_center.get_pending_event_count():
		var event: Dictionary = game_center.pop_pending_event()
		var event_type = event.get("type")
		if not event_type:
			continue

		match event_type:
			"authentication":
				_on_authentication(event)
			"post_score":
				_on_post_score(event)
			"award_achievement":
				_on_award_achievement(event)
			#"achievement_descriptions": pass
			#"achievements": pass
			#"reset_achievements": pass
			#"identity_verification_signature": pass
			#"show_game_center": pass
			"save_game_data":
				_on_save_game_data(event)
			"fetch_saved_games":
				_on_fetch_saved_games(event)
			#"delete_saved_games": pass
			"saved_game_loaded":
				_on_saved_game_loaded(event)
			"conflicting_saved_games":
				_on_conflicting_saved_games(event)
			"resolve_conflicting_saved_games":
				_on_resolve_conflicting_saved_games(event)
			"player_did_modify_saved_game":
				_on_player_did_modify_saved_game(event)


func _print_event_error(event: Dictionary) -> void:
	var err = event.get("error_description")
	printerr("[GameCenter][", event.get("type"), "] Error: ", err if err else error_string(event.get("error_code")))


func _on_authentication(event: Dictionary) -> void:
	if event.get("result", "ok") == "ok":
		_print_debug("[GameCenter] User authenticated")
		_is_authenticated = true
		user_authenticated.emit(true)
	else:
		_print_event_error(event)
		user_authenticated.emit(false)


func _on_post_score(event: Dictionary) -> void:
	if event.get("result", "ok") == "ok":
		_print_debug("[GameCenter] Score posted to leaderboard")
	else:
		_print_event_error(event)


func _on_award_achievement(event: Dictionary) -> void:
	if event.get("result", "ok") == "ok":
		_print_debug("[GameCenter] Achievement awarded")
	else:
		_print_event_error(event)


func _on_save_game_data(event: Dictionary) -> void:
	var saved_game_name = event["name"]
	if event.get("result", "ok") == "ok":
		_print_debug("[GameCenter] Saved game " + saved_game_name)
		_call_save_success(saved_game_name)
	else:
		_print_event_error(event)
		var error_description = event.get("error_description")
		_call_save_failure(saved_game_name, error_description)


func _on_fetch_saved_games(event: Dictionary) -> void:
	_is_load_snapshots_in_progress = false
	if event.get("result", "ok") == "ok":
		_print_debug("[GameCenter] Fecthed saved games ==== ")

		var snapshot_map = {}
		for s in event["saved_games"]:
			_print_debug(str(s))
			snapshot_map[s.name] = s

		# Process pending load requests
		for file_name in _load_game_success_callbacks:
			if snapshot_map.has(file_name):
				_loading_save_game[file_name] = true
				snapshot_map[file_name].load_data()
			else:
				_call_load_success(file_name, "")
	else:
		_print_event_error(event)
		var error_description = event.get("error_description")
		_call_all_load_failure(error_description)


func _on_saved_game_loaded(event: Dictionary) -> void:
	var saved_game_name = event["name"]
	_loading_save_game.erase(saved_game_name)

	print("[GAME CENTER] SAVED GAME LOADED: " + saved_game_name)

	if event.get("result", "ok") == "ok":
		var data: PackedByteArray = event["data"]
		if _conflicting_saves.has(saved_game_name):
			game_center.resolve_conflicting_saved_games({
				"saved_games": _conflicting_saves[saved_game_name],
				"data": data,
				"name": saved_game_name,
			})
			_conflicting_saves.erase(saved_game_name)
		_call_load_success(saved_game_name, data.get_string_from_utf8())
	else:
		_print_event_error(event)
		var error_description = event.get("error_description")
		_call_load_failure(saved_game_name, error_description)


func _on_conflicting_saved_games(event: Dictionary) -> void:
	_print_debug("[GameCenter] Conflicting saved games " + str(event["saved_games"]))
	_conflicting_saves[event["saved_games"].front().name] = event["saved_games"]
	
	var file_infos: Array[FileManager.FileInfo] = []
	for saved_game in event["saved_games"]:
		file_infos.append(FileInfoGameCenter.new(saved_game))
	var on_conflict_resolved_callback = func(file_info: FileManager.FileInfo):
		assert(file_info is FileInfoGameCenter)
		_loading_save_game[file_info.file_name] = true
		file_info.saved_game.load_data()
	FileManager.resolve_file_conflicts(file_infos, on_conflict_resolved_callback)


func _on_resolve_conflicting_saved_games(event: Dictionary) -> void:
	if event.get("result", "ok") == "ok":
		_print_debug("[GameCenter] Resolved conflicting saved games")
	else:
		_print_event_error(event)


func _on_player_did_modify_saved_game(event: Dictionary) -> void:
	if event.get("result", "ok") == "ok":
		var saved_game = event["saved_game"]
		_print_debug("[GameCenter] Player did modify saved game: " + str(saved_game))
		if not saved_game.is_current_device():
			FileManager.call_file_changed_externally_callback(FileInfoGameCenter.new(saved_game))
	else:
		_print_event_error(event)


func _call_load_success(filename: String, data: String) -> void:
	_print_debug("[GameCenter] _call_load_success: " + filename)
	if !_load_game_success_callbacks.has(filename): return

	_print_debug("[GameCenter] "+filename+" callbacks: " + str(_load_game_success_callbacks[filename].size()))
	for callback in _load_game_success_callbacks[filename]:
		_print_debug("[GameCenter] "+filename+" calling callback: " + str(callback))
		callback.call(data)
	_load_game_success_callbacks[filename].clear()
	_load_game_failure_callbacks[filename].clear()


func _call_load_failure(filename: String, error: String) -> void:
	_print_debug("[GameCenter] _call_load_failure: " + filename + ", error: " + error)
	if !_load_game_failure_callbacks.has(filename): return

	for callback in _load_game_failure_callbacks[filename]:
		#_print_debug("[GameCenter] calling callback: " + callback)
		callback.call(error)
	_load_game_success_callbacks[filename].clear()
	_load_game_failure_callbacks[filename].clear()


func _call_all_load_failure(error: String) -> void:
	_print_debug("[GameCenter] _call_all_load_failure: " + error)
	if !_load_game_failure_callbacks: return

	for filename in _load_game_failure_callbacks:
		for callback in _load_game_failure_callbacks[filename]:
			#_print_debug("[GameCenter] calling callback: " + callback)
			callback.call(error)
	_load_game_success_callbacks.clear()
	_load_game_failure_callbacks.clear()


func _call_save_success(filename: String) -> void:
	_print_debug("[GameCenter] _call_save_success: " + filename)
	if !_save_game_success_callbacks: return

	_print_debug("[GameCenter] "+filename+" callbacks: " + str(_save_game_success_callbacks[filename].size()))
	for callback in _save_game_success_callbacks[filename]:
		_print_debug("[GameCenter] "+filename+" calling callback: " + str(callback))
		callback.call()
	_save_game_success_callbacks[filename].clear()
	_save_game_failure_callbacks[filename].clear()


func _call_save_failure(filename: String, error: String) -> void:
	_print_debug("[GameCenter] _call_save_failure: " + filename + ", error: " + error)
	if !_save_game_failure_callbacks.has(filename): return

	for callback in _save_game_failure_callbacks[filename]:
		#_print_debug("[GameCenter] calling callback: " + callback)
		callback.call(error)
	_save_game_success_callbacks[filename].clear()
	_save_game_failure_callbacks[filename].clear()


class FileInfoGameCenter extends FileManager.FileInfo:
	## Native GameCenterSavedGame object
	var saved_game: RefCounted:
		get:
			return _saved_game
		set(value):
			_saved_game = value
			file_name = _saved_game.name
			device_name = _saved_game.device_name
			modification_unix_time = _saved_game.modification_date
	
	var _saved_game: RefCounted
	
	
	func _init(saved_game: RefCounted):
		self.saved_game = saved_game
