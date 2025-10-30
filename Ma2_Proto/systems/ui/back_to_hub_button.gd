class_name BackToHubButton extends Button

const LVL_INFO_HUB = preload("res://elements/levels/lvl_info_hub.tres")

func _ready() -> void:
	pressed.connect(reload)

func reload():
	LevelManager.change_level_by_info(LVL_INFO_HUB)
