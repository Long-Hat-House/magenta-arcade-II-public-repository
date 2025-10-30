extends SocialPlatformSystem

const ICON_ACHIEVEMENTS = preload("res://modules/social_platform_system/play_games_icons/icon_achievements.png")
const ICON_LEADERBOARDS = preload("res://modules/social_platform_system/play_games_icons/icon_leaderboards.png")

# Sign in
var _sign_in_client: PlayGamesSignInClient
var _is_authenticated := false
# Achievements
var _achievements_client: PlayGamesAchievementsClient
var _achievement_id_map = {
	SocialPlatformManager.Achievement.ACH_START: "CgkIiJLV6rwIEAIQAw",
	SocialPlatformManager.Achievement.ACH_BEAT_LVL_1: "CgkIiJLV6rwIEAIQBA",
	SocialPlatformManager.Achievement.ACH_BEAT_LVL_2: "CgkIiJLV6rwIEAIQBQ",
	SocialPlatformManager.Achievement.ACH_BEAT_LVL_3: "CgkIiJLV6rwIEAIQBg",
	SocialPlatformManager.Achievement.ACH_BEAT_LVL_4: "CgkIiJLV6rwIEAIQBw",
	SocialPlatformManager.Achievement.ACH_BEAT_LVL_5: "CgkIiJLV6rwIEAIQCA",
	SocialPlatformManager.Achievement.ACH_ENDING: "CgkIiJLV6rwIEAIQCQ",
	SocialPlatformManager.Achievement.ACH_BEAT_LVL_ARCADE: "CgkIiJLV6rwIEAIQCg",
	SocialPlatformManager.Achievement.ACH_USE_STAR_1: "CgkIiJLV6rwIEAIQCw",
	SocialPlatformManager.Achievement.ACH_GET_STAR_9: "CgkIiJLV6rwIEAIQDA",
	SocialPlatformManager.Achievement.ACH_GET_STAR_12: "CgkIiJLV6rwIEAIQDQ",
	SocialPlatformManager.Achievement.ACH_GET_STAR_18: "CgkIiJLV6rwIEAIQDg",
}
# Leaderboards
var _leaderboards_client: PlayGamesLeaderboardsClient
var _leaderboard_id_map = {
	SocialPlatformManager.Leaderboard.HS_LVL_1: "CgkIiJLV6rwIEAIQDw",
	SocialPlatformManager.Leaderboard.HS_LVL_2: "CgkIiJLV6rwIEAIQEA",
	SocialPlatformManager.Leaderboard.HS_LVL_3: "CgkIiJLV6rwIEAIQEQ",
	SocialPlatformManager.Leaderboard.HS_LVL_4: "CgkIiJLV6rwIEAIQEg",
	SocialPlatformManager.Leaderboard.HS_LVL_5: "CgkIiJLV6rwIEAIQEw",
	SocialPlatformManager.Leaderboard.HS_LVL_ARCADE: "CgkIiJLV6rwIEAIQFA",
	SocialPlatformManager.Leaderboard.HS_RICHEST: "CgkIiJLV6rwIEAIQFQ",
}
# Snapshots (cloud save)
var _snapshots_client: PlayGamesSnapshotsClient
var _loading_save_game: Dictionary[String, bool] = {}
var _save_game_success_callbacks: Dictionary[String, Array] = {}  # value is Array[Callable]
var _save_game_failure_callbacks: Dictionary[String, Array] = {}  # value is Array[Callable]
var _load_game_success_callbacks: Dictionary[String, Array] = {}  # value is Array[Callable]
var _load_game_failure_callbacks: Dictionary[String, Array] = {}  # value is Array[Callable]


func initialize_async() -> void:
	if GodotPlayGameServices.initialize() != GodotPlayGameServices.PlayGamesPluginError.OK:
		return

	_sign_in_client = PlayGamesSignInClient.new()
	add_child(_sign_in_client)
	_sign_in_client.user_authenticated.connect(_on_user_authenticated)

	_achievements_client = PlayGamesAchievementsClient.new()
	add_child(_achievements_client)

	_leaderboards_client = PlayGamesLeaderboardsClient.new()
	add_child(_leaderboards_client)

	_snapshots_client = PlayGamesSnapshotsClient.new()
	add_child(_snapshots_client)
	_snapshots_client.game_loaded.connect(_on_game_loaded)
	_snapshots_client.game_saved.connect(_on_game_saved)
	_snapshots_client.conflict_emitted.connect(_on_snapshots_conflict)
	
	_sign_in_client.is_authenticated()
	await user_authenticated


func is_authenticated() -> bool:
	return _is_authenticated


func authenticate() -> void:
	_sign_in_client.sign_in()


func unlock_achievement(achievement_id: SocialPlatformManager.Achievement, show_completion_banner: bool = true) -> void:
	if _is_authenticated:
		_achievements_client.unlock_achievement(_achievement_id_map[achievement_id])


func reveal_achievement(achievement_id: SocialPlatformManager.Achievement) -> void:
	if _is_authenticated:
		_achievements_client.reveal_achievement(_achievement_id_map[achievement_id])


func show_all_achievements():
	if _is_authenticated:
		_achievements_client.show_achievements()


func submit_score(leaderboard_id: SocialPlatformManager.Leaderboard, score: int) -> void:
	if _is_authenticated:
		_leaderboards_client.submit_score(_leaderboard_id_map[leaderboard_id], score)


func show_all_leaderboards() -> void:
	if _is_authenticated:
		_leaderboards_client.show_all_leaderboards()


func show_leaderboard(leaderboard_id: SocialPlatformManager.Leaderboard) -> void:
	if _is_authenticated:
		_leaderboards_client.show_leaderboard(_leaderboard_id_map[leaderboard_id])


func get_achievements_icon() -> Texture2D:
	return ICON_ACHIEVEMENTS


func get_leaderboards_icon() -> Texture2D:
	return ICON_LEADERBOARDS

func get_leaderboards_text() -> String:
	return "playgames_leaderboards"

func get_achievements_text() -> String:
	return "playgames_achievements"


func supports_cloud_save() -> bool:
	return _snapshots_client != null and _is_authenticated


func get_cloud_save_data(file_name:String, success_callback:Callable, fail_callback:Callable):
	_load_game_success_callbacks.get_or_add(file_name, []).append(success_callback)
	_load_game_failure_callbacks.get_or_add(file_name, []).append(fail_callback)
	if not _loading_save_game.get(file_name, false):
		_loading_save_game[file_name] = true
		_snapshots_client.load_game(file_name, true)


func save_cloud_save_data(file_name:String, data:String, success_callback:Callable, fail_callback:Callable):
	_save_game_success_callbacks.get_or_add(file_name, []).append(success_callback)
	_save_game_failure_callbacks.get_or_add(file_name, []).append(fail_callback)
	_snapshots_client.save_game(file_name, "", data.to_utf8_buffer())


func clear_cloud_save_data(file_name:String, success_callback:Callable, fail_callback:Callable):
	# For simplicity, just save empty content instead of deleting snapshot.
	save_cloud_save_data(file_name, "", success_callback, fail_callback)


func _on_user_authenticated(authenticated: bool) -> void:
	_print_debug("[PlayGames] User authenticated: " + str(authenticated))
	_is_authenticated = authenticated
	user_authenticated.emit(authenticated)


func _on_game_loaded(snapshot: PlayGamesSnapshot):
	if snapshot != null:
		var saved_game_name = snapshot.metadata.unique_name
		_loading_save_game.erase(saved_game_name)
		_print_debug("[PlayGames] _on_game_loaded " + str(saved_game_name))
		_call_load_success(saved_game_name, snapshot.content.get_string_from_utf8())
	else:
		printerr("[PlayGames] Loaded snapshot is null, this should not happen")


func _on_game_saved(is_saved: bool, save_data_name: String, save_data_description: String):
	_print_debug("[PlayGames] _on_game_saved " + str([is_saved, save_data_name, save_data_description]))
	if is_saved:
		_call_save_success(save_data_name)
	else:
		_call_save_failure(save_data_name, "Game was not saved")


func _on_snapshots_conflict(conflict: PlayGamesSnapshotConflict):
	_print_debug("[PlayGames] _on_snapshots_conflict " + str([conflict.server_snapshot.metadata.unique_name, conflict.server_snapshot.metadata.snapshot_id, conflict.conflicting_snapshot.metadata.snapshot_id]))
	
	FileManager.resolve_file_conflicts([
		FileInfoPlayGames.new(conflict.server_snapshot),
		FileInfoPlayGames.new(conflict.conflicting_snapshot),
	], func(file_info: FileManager.FileInfo):
		assert(file_info is FileInfoPlayGames)
		_snapshots_client.delete_snapshot(file_info.snapshot.metadata.snapshot_id)
	)


func _call_load_success(filename: String, data: String) -> void:
	if !_load_game_success_callbacks.has(filename): return
	
	for callback in _load_game_success_callbacks[filename]:
		callback.call(data)
	_load_game_success_callbacks[filename].clear()
	_load_game_failure_callbacks[filename].clear()


func _call_load_failure(filename: String, error: String) -> void:
	if !_load_game_failure_callbacks.has(filename): return
	
	for callback in _load_game_failure_callbacks[filename]:
		callback.call(error)
	_load_game_success_callbacks[filename].clear()
	_load_game_failure_callbacks[filename].clear()


func _call_save_success(filename: String) -> void:
	if !_save_game_success_callbacks: return
	
	for callback in _save_game_success_callbacks[filename]:
		callback.call()
	_save_game_success_callbacks[filename].clear()
	_save_game_failure_callbacks[filename].clear()


func _call_save_failure(filename: String, error: String) -> void:
	if !_save_game_failure_callbacks.has(filename): return
	
	for callback in _save_game_failure_callbacks[filename]:
		callback.call(error)
	_save_game_success_callbacks[filename].clear()
	_save_game_failure_callbacks[filename].clear()


class FileInfoPlayGames extends FileManager.FileInfo:
	var snapshot: PlayGamesSnapshot:
		get:
			return _snapshot
		set(value):
			_snapshot = value
			file_name = _snapshot.metadata.unique_name
			device_name = _snapshot.metadata.device_name
			modification_unix_time = int(_snapshot.metadata.last_modified_timestamp / 1000.0)
	var _snapshot: PlayGamesSnapshot
	
	
	func _init(snapshot: PlayGamesSnapshot):
		self.snapshot = snapshot
