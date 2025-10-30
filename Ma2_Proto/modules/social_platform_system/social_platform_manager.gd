extends Node
## Manager for social platforms such as Android's Google Play Games and iOS Game Center
##
## Available as SocialPlatformManager singleton

const DEFAULT_ICON_ACHIEVEMENTS = preload("res://modules/social_platform_system/game_center_icons/icon_achievements.png")
const DEFAULT_ICON_LEADERBOARDS = preload("res://modules/social_platform_system/game_center_icons/icon_leaderboards.png")

signal initialized()

## Achievement IDs
enum Achievement {
	ACH_NONE,
	ACH_BEAT_LVL_1,
	ACH_BEAT_LVL_2,
	ACH_BEAT_LVL_3,
	ACH_BEAT_LVL_4,
	ACH_BEAT_LVL_5,
	ACH_BEAT_LVL_ARCADE,
	ACH_START,
	ACH_ENDING,
	ACH_USE_STAR_1,
	ACH_GET_STAR_9,
	ACH_GET_STAR_12,
	ACH_GET_STAR_18,
}

## Leaderboard IDs
enum Leaderboard {
	HS_NONE,
	HS_LVL_1,
	HS_LVL_2,
	HS_LVL_3,
	HS_LVL_4,
	HS_LVL_5,
	HS_LVL_ARCADE,
	HS_RICHEST,
}

var is_initialized := false

var _social_platform_system: SocialPlatformSystem = null


## Initialize the Social platform system.
## This will start an automatic login and should be called in the game initialization.
func initialize():
	print("[SOCIAL PLATFORM MANAGER] - WILL INITIALIZE")

	if OS.has_feature("android"):
		_social_platform_system = load("res://modules/social_platform_system/social_platform_google_play_games.gd").new()
	elif OS.has_feature("ios"):
		_social_platform_system = load("res://modules/social_platform_system/social_platform_game_center.gd").new()

	if _social_platform_system:
		add_child(_social_platform_system)
		_social_platform_system.process_mode = Node.PROCESS_MODE_ALWAYS
		await _social_platform_system.initialize_async()
	is_initialized = true
	initialized.emit()

	print("[SOCIAL PLATFORM MANAGER] - INITIALIZED")

## Returns whether the user is authenticated in the social platform.
func is_authenticated() -> bool:
	if _social_platform_system:
		return _social_platform_system.is_authenticated()
	else:
		return false


## Manually authenticate a user if it is not signed in yet.
## This could be called from a button in the UI for manually signing in the player if necessary.
func authenticate() -> void:
	if _social_platform_system:
		_social_platform_system.authenticate()


## Unlocks the specified achievement in the social platform.
func unlock_achievement(achievement_id: Achievement) -> void:
	if achievement_id == Achievement.ACH_NONE: return
	if _social_platform_system:
		_social_platform_system.unlock_achievement(achievement_id)


## Reveal a hidden achievement to the user.
func reveal_achievement(achievement_id: SocialPlatformManager.Achievement) -> void:
	if achievement_id == Achievement.ACH_NONE: return
	if _social_platform_system:
		_social_platform_system.reveal_achievement(achievement_id)


## Shows all achievements for the social platform in the system native UI.
func show_all_achievements():
	if _social_platform_system:
		_social_platform_system.show_all_achievements()


## Shows a specific leaderboard for the social platform in the system native UI.
func show_leaderboard(leaderboard_id: SocialPlatformManager.Leaderboard) -> void:
	if _social_platform_system:
		_social_platform_system.show_leaderboard(leaderboard_id)


## Submit a score to the specified leaderboard.
func submit_score(leaderboard_id: Leaderboard, score: int) -> void:
	if leaderboard_id == Leaderboard.HS_NONE: return
	if _social_platform_system:
		_social_platform_system.submit_score(leaderboard_id, score)


## Shows all leaderboards for the social platform in the system native UI.
func show_all_leaderboards() -> void:
	if _social_platform_system:
		_social_platform_system.show_all_leaderboards()


## Returns whether the social platform supports cloud save
func supports_cloud_save() -> bool:
	if _social_platform_system:
		return _social_platform_system.supports_cloud_save()
	else:
		return false


## Loads cloud save data from the social platform.
## This method works like FileSystem._get_data.
func get_cloud_save_data(file_name:String, success_callback:Callable, fail_callback:Callable):
	assert(supports_cloud_save(), "FIXME: check supports_cloud_save() before calling get_cloud_save_data")
	_social_platform_system.get_cloud_save_data(file_name, success_callback, fail_callback)


## Save data to the cloud using social platform.
## This method works like FileSystem._save_data.
func save_cloud_save_data(file_name:String, data:String, success_callback:Callable, fail_callback:Callable):
	assert(supports_cloud_save(), "FIXME: check supports_cloud_save() before calling save_cloud_save_data")
	_social_platform_system.save_cloud_save_data(file_name, data, success_callback, fail_callback)


## Clear saved data from the cloud using social platform.
## This method works like FileSystem._clear_data.
func clear_cloud_save_data(file_name:String, success_callback:Callable, fail_callback:Callable):
	assert(supports_cloud_save(), "FIXME: check supports_cloud_save() before calling clear_cloud_save_data")
	_social_platform_system.clear_cloud_save_data(file_name, success_callback, fail_callback)


func get_leaderboards_icon() -> Texture2D:
	if _social_platform_system:
		return _social_platform_system.get_leaderboards_icon()
	return DEFAULT_ICON_LEADERBOARDS

func get_achievements_icon() -> Texture2D:
	if _social_platform_system:
		return _social_platform_system.get_achievements_icon()
	return DEFAULT_ICON_ACHIEVEMENTS

func get_leaderboards_text() -> String:
	if _social_platform_system:
		return _social_platform_system.get_leaderboards_text()
	return "playgames_leaderboards"

func get_achievements_text() -> String:
	if _social_platform_system:
		return _social_platform_system.get_achievements_text()
	return "playgames_achievements"
