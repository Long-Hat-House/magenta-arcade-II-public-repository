class_name CoinsChanger extends Node

var _change_amount:int

func set_change_amount(change_amount:int) -> void:
	_change_amount = change_amount

func get_change_amount() -> int:
	return _change_amount

func do_change() -> bool:
	return Ma2MetaManager.gain_coins(_change_amount)

func check_enough_coins() -> bool:
	return Ma2MetaManager.check_enough_coins(-_change_amount)
