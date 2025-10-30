class_name Condition_MetaInteger extends Condition

enum ValueToCheck {
	UpgradeUnlockStage,
	StarsUnlocked,
	StarsUnused,
}

enum CheckMode {
	InBetween,
	UnderMin,
	AboveMax,
	EqualMin
}

@export var value_to_check:ValueToCheck
@export var check_mode:CheckMode
@export var check_min:int = 0
@export var check_max:int = 100
@export var negate:bool = false

func _ready() -> void:
	_call_condition_changed(is_condition())

func is_condition() -> bool:
	var val:int = 0

	match value_to_check:
		ValueToCheck.StarsUnlocked:
			val = Ma2MetaManager.get_unlocked_stars_count()
		ValueToCheck.StarsUnused:
			val = Ma2MetaManager.get_unlocked_stars_count()
		ValueToCheck.UpgradeUnlockStage:
			val = Ma2MetaManager.get_upgrade_unlock_stage()

	var ret:bool = false
	match check_mode:
		CheckMode.InBetween:
			ret = val > check_min && val < check_max
		CheckMode.UnderMin:
			ret = val < check_min
		CheckMode.AboveMax:
			ret = val > check_max
		CheckMode.EqualMin:
			ret = (val == check_min)

	if negate: ret = !ret
	return ret
