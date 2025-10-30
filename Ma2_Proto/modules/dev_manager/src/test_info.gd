class_name TestInfo extends Resource

@export var test_name:String = "Test"

@export var hard_lock_levels:Array[LevelInfo]
@export var hard_lock_title:String = "🚧"
@export_multiline var hard_lock_message:String

func is_hard_locked_level(lvl:LevelInfo) -> bool:
	return hard_lock_levels.has(lvl)
