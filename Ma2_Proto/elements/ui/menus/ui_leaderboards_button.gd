@tool
class_name LeaderboardButton extends ExtendedButton

@export var leaderboard_to_show:SocialPlatformManager.Leaderboard = SocialPlatformManager.Leaderboard.HS_NONE

@export var _enable_text:bool:
	get: return _enable_text
	set(val):
		_enable_text = val
		_update_text()

@export var _enable_icon:bool:
	get: return _enable_icon
	set(val):
		_enable_icon = val
		_update_icon()

func _update_text():
	if _enable_text:
		if Engine.is_editor_hint():
			text = "Placar"
		else:
			text = SocialPlatformManager.get_leaderboards_text()
	else:
		text = ""

func _update_icon():
	if _enable_icon:
		if Engine.is_editor_hint():
			icon = load("uid://bp2u67flr6r7")
		else:
			icon = SocialPlatformManager.get_leaderboards_icon()
	else:
		icon = null

func _ready() -> void:
	if Engine.is_editor_hint():
		_update_text()
		_update_icon()
		return

	var integrations_ui:bool = (
		DevManager.get_setting(DevManager.SETTING_INTEGRATIONS_UI_ENABLED)
		or
		SocialPlatformManager.is_authenticated()
		)

	visible = integrations_ui

	if !visible: return

	_update_text()
	_update_icon()

func _pressed() -> void:
	super._pressed()

	if leaderboard_to_show != SocialPlatformManager.Leaderboard.HS_NONE:
		SocialPlatformManager.show_leaderboard(leaderboard_to_show)
	else:
		SocialPlatformManager.show_all_leaderboards()
