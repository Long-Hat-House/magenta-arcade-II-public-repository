@tool
class_name AchievementsButton extends ExtendedButton

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
			text = "Conquista"
		else:
			text = SocialPlatformManager.get_achievements_text()
	else:
		text = ""

func _update_icon():
	if _enable_icon:
		if Engine.is_editor_hint():
			icon = load("uid://ytc51omb1gqo")
		else:
			icon = SocialPlatformManager.get_achievements_icon()
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

	SocialPlatformManager.show_all_achievements()
