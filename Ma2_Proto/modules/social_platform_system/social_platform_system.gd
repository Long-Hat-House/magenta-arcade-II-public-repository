class_name SocialPlatformSystem
extends Node


signal user_authenticated(authenticated: bool)


func initialize_async() -> void:
	pass


func is_authenticated() -> bool:
	return false


func authenticate() -> void:
	pass


func unlock_achievement(achievement_id: SocialPlatformManager.Achievement, show_completion_banner: bool = true) -> void:
	pass


func reveal_achievement(achievement_id: SocialPlatformManager.Achievement) -> void:
	pass


func show_all_achievements():
	pass


func submit_score(leaderboard_id: SocialPlatformManager.Leaderboard, score: int) -> void:
	pass


func show_all_leaderboards() -> void:
	pass


func show_leaderboard(leaderboard_id: SocialPlatformManager.Leaderboard) -> void:
	pass


func get_achievements_icon() -> Texture2D:
	return null


func get_leaderboards_icon() -> Texture2D:
	return null

func get_leaderboards_text() -> String:
	return "playgames_leaderboards"

func get_achievements_text() -> String:
	return "playgames_achievements"

func supports_cloud_save() -> bool:
	return false


func get_cloud_save_data(file_name:String, success_callback:Callable, fail_callback:Callable):
	fail_callback.call("Not implemented")


func save_cloud_save_data(file_name:String, data:String, success_callback:Callable, fail_callback:Callable):
	fail_callback.call("Not implemented")


func clear_cloud_save_data(file_name:String, success_callback:Callable, fail_callback:Callable):
	fail_callback.call("Not implemented")


func _print_debug(s: String):
	#if OS.is_debug_build():
	print(s)
