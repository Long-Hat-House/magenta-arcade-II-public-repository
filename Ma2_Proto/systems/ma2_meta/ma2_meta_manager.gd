extends Node

signal meta_updated()
signal check_enough_coins_failed()

const SAVE_COMPLETED_LEVELS:StringName = &"META.LEVELS.COMPLETED_LEVELS"
const SAVE_UNLOCKED_LEVELS:StringName = &"META.LEVELS.UNLOCKED_LEVELS"

const SAVE_UNLOCKED_STARS:StringName = &"META.STARS.UNLOCKED"

const SAVE_UPGRADES_PROGRESS:StringName = &"META.UPGRADES.PROGRESS"

const SAVE_COINS_AMOUNT:StringName = &"META.COINS.AMOUNT"
const SAVE_COINS_ALL_TIME:StringName = &"META.COINS.ALL_TIME"

const SAVE_QUICK_BOOLS:StringName = &"META.QUICK_BOOLS"
const SAVE_QUICK_INTS:StringName = &"META.QUICK_INTS"
const SAVE_QUICK_FLOATS:StringName = &"META.QUICK_FLOATS"

const SAVE_HIGHSCORES:StringName = &"META.HIGHSCORES"

const SAVE_PLAYTIME:StringName = &"META.PLAYTIME"
const SAVE_LAST_PLAYED_DATE:StringName = &"META.LAST_PLAYED_DATE"
const SAVE_CREATION_DATE:StringName = &"META.CREATION_DATE"

const SAVE_SLOT_NAME:StringName = &"META.SLOT_NAME"

## TODO: THIS SHOULD BE CONST PRELOAD, BUT GODOT BUGS
var UPGRADESET_HEALTH = load("res://systems/ma2_meta/upgrades/upgradeset_health.tres")
var UPGRADESET_HOLD = load("res://systems/ma2_meta/upgrades/upgradeset_hold.tres")
var UPGRADESET_TAP = load("res://systems/ma2_meta/upgrades/upgradeset_tap.tres")

## TODO: THIS SHOULD BE CONST PRELOAD, BUT GODOT BUGS
var UPGRADE_SETS:Array[UpgradeSet] = [
	UPGRADESET_HOLD,
	UPGRADESET_TAP,
	UPGRADESET_HEALTH,
]

var _active_save:GameSave

var _completed_levels:Dictionary
var _unlocked_levels:Dictionary
var _unlocked_stars:Dictionary

var _upgrades_progress:Dictionary

var _quick_bools:Dictionary
var _quick_ints:Dictionary
var _quick_floats:Dictionary

#dictionary of ints
var _highscores:Dictionary

func _ready() -> void:
	SaveManager.use_save_by_name("slot_debug", set_current_save)

func set_current_save(save:GameSave):
	_active_save = save

	if save.is_empty():
		#first time using this save, create a name for it
		_active_save.set_data(SAVE_CREATION_DATE, JSON.stringify(Time.get_date_string_from_system()))

	#parse even if save is empty, so we clear previous save data from variables
	parse_and_load_dictionary(_completed_levels, SAVE_COMPLETED_LEVELS)
	parse_and_load_dictionary(_unlocked_levels, SAVE_UNLOCKED_LEVELS)
	parse_and_load_dictionary(_unlocked_stars, SAVE_UNLOCKED_STARS)
	parse_and_load_dictionary(_upgrades_progress, SAVE_UPGRADES_PROGRESS)
	parse_and_load_dictionary(_quick_bools, SAVE_QUICK_BOOLS)
	parse_and_load_dictionary(_quick_ints, SAVE_QUICK_INTS)
	parse_and_load_dictionary(_quick_floats, SAVE_QUICK_FLOATS)
	parse_and_load_highscores()

func parse_and_load_highscores():
	parse_and_load_dictionary(_highscores, SAVE_HIGHSCORES)
	for h in _highscores:
		if _highscores[h] is Array[int] or _highscores[h] is Array:
			_highscores[h] = _highscores[h][0]

func parse_and_load_dictionary(dict:Dictionary, id:StringName):
	dict.clear()
	if _active_save.is_empty(): return
	var data = _active_save.get_json_parsed_data(id)
	if data:
		dict.merge(data)

func get_slot_number() -> int:
	return peek_slot_number(_active_save)

func get_slot_name() -> String:
	return _active_save.get_data(SAVE_SLOT_NAME, _get_default_name_for_slot(_active_save))

func set_slot_name(slot_name:String = ""):
	set_save_slot_name(_active_save, slot_name)
	meta_updated.emit()

func process_playtime(delta:float):
	if LevelManager.is_transitioning || Menu.is_paused(): return
	_active_save.set_data(SAVE_PLAYTIME, JSON.stringify(get_playtime_seconds() + delta), true)
	_active_save.set_data(SAVE_LAST_PLAYED_DATE, JSON.stringify(Time.get_date_string_from_system()), true)

func get_playtime_seconds() -> float:
	return _active_save.get_json_parsed_data(SAVE_PLAYTIME, "0")

func get_playtime_text() -> String:
	return seconds_to_hhmmss(floori(get_playtime_seconds()))

func get_last_played_date() -> String:
	return _active_save.get_json_parsed_data(SAVE_LAST_PLAYED_DATE, "--/--/--")

func get_creation_date() -> String:
	return _active_save.get_json_parsed_data(SAVE_CREATION_DATE, "--/--/--")

func is_level_complete(level_id:StringName) -> bool:
	return _completed_levels.has(level_id)

func set_level_complete(level_id:StringName) -> bool:
	if is_level_complete(level_id): return false

	_completed_levels[level_id] = true

	if _active_save:
		_active_save.set_data(SAVE_COMPLETED_LEVELS, JSON.stringify(_completed_levels))

	meta_updated.emit()
	return true

func is_level_unlocked(level_id:StringName) -> bool:
	return _unlocked_levels.has(level_id)

#returns true if it's the first time unlocking
func set_level_unlocked(level_id:StringName) -> bool:
	if is_level_unlocked(level_id): return false

	_unlocked_levels[level_id] = true

	if _active_save:
		_active_save.set_data(SAVE_UNLOCKED_LEVELS, JSON.stringify(_unlocked_levels))

	meta_updated.emit()
	return true

func is_star_unlocked(star_id:StringName) -> bool:
	return _unlocked_stars.has(star_id)

#returns true if it's the first time unlocking
func set_star_unlocked(star_id:StringName) -> bool:
	if is_star_unlocked(star_id): return false

	_unlocked_stars[star_id] = true

	var star_count:int = get_unlocked_stars_count()
	if star_count >= 9:
		SocialPlatformManager.unlock_achievement(SocialPlatformManager.Achievement.ACH_GET_STAR_9)
	if star_count >= 12:
		SocialPlatformManager.unlock_achievement(SocialPlatformManager.Achievement.ACH_GET_STAR_12)
	if star_count >= 18:
		SocialPlatformManager.unlock_achievement(SocialPlatformManager.Achievement.ACH_GET_STAR_18)

	if _active_save:
		_active_save.set_data(SAVE_UNLOCKED_STARS, JSON.stringify(_unlocked_stars))

	meta_updated.emit()
	return true

func get_unlocked_stars_count() -> int:
	return _unlocked_stars.size()

func get_allocated_total_stars() -> int:
	var count:int = 0

	for upgradeset in UPGRADE_SETS:
		count += upgradeset.get_allocated_summed_stars()

	return count

func get_unused_stars_count() -> int:
	return get_unlocked_stars_count() - get_allocated_total_stars()

func get_upgrade_unlock_stage() -> int:
	var stars:int = get_unlocked_stars_count()
	if stars == 0:
		return 0
	elif stars <= 2:
		return 1
	elif stars <= 7:
		return 2
	else:
		return 10

func get_upgrade_sets() -> Array[UpgradeSet]:
	return UPGRADE_SETS

func get_upgrade_progress(upgrade_id:String) -> int:
	if _upgrades_progress.has(upgrade_id):
		return _upgrades_progress[upgrade_id]
	else:
		return 0

func set_upgrade_progress(upgrade_id:String, progress:int) -> void:
	_upgrades_progress[upgrade_id] = progress

	if _active_save:
		_active_save.set_data(SAVE_UPGRADES_PROGRESS, JSON.stringify(_upgrades_progress))

	meta_updated.emit()

func clear_all_upgrades_progress():
	_upgrades_progress.clear()

	if _active_save:
		_active_save.set_data(SAVE_UPGRADES_PROGRESS, JSON.stringify(_upgrades_progress))

	meta_updated.emit()

func submit_score(lvl_info:LevelInfo, score:int) -> void:
	if !lvl_info: return

	if get_highscore(lvl_info) > score:
		return

	_highscores[lvl_info.lvl_id] = score

	if _active_save:
		_active_save.set_data(SAVE_HIGHSCORES, JSON.stringify(_highscores))

	meta_updated.emit()

#returns -1 if there is no score
func get_highscore(lvl_info:LevelInfo) -> int:
	if !lvl_info: return -1

	if _highscores.has(lvl_info.lvl_id):
		return _highscores[lvl_info.lvl_id]
	return -1


func get_quick_bool(bool_id:StringName) -> bool:
	return _quick_bools.has(bool_id)

func set_quick_bool(bool_id:StringName, bool_val:bool):
	if get_quick_bool(bool_id) == bool_val:
		return

	if bool_val:
		_quick_bools[bool_id] = true
	else:
		_quick_bools.erase(bool_id)

	if _active_save:
		_active_save.set_data(SAVE_QUICK_BOOLS, JSON.stringify(_quick_bools))

	meta_updated.emit()

func get_quick_int(int_id:StringName, default_val:int = 0) -> int:
	if _quick_ints.has(int_id):
		return _quick_ints[int_id]
	return default_val

func set_quick_int(int_id:StringName, int_val:int):
	if _quick_ints.has(int_id) && _quick_ints[int_id] == int_val:
		return

	_quick_ints[int_id] = int_val

	if _active_save:
		_active_save.set_data(SAVE_QUICK_INTS, JSON.stringify(_quick_ints))

	meta_updated.emit()

func get_quick_float(float_id:StringName, default_val:float = 0) -> float:
	if _quick_floats.has(float_id):
		return _quick_floats[float_id]
	return default_val

func set_quick_float(float_id:StringName, float_val:float, emits_updated:bool = true, avoid_log:bool = false):
	if get_quick_float(float_id) == float_val:
		return

	_quick_floats[float_id] = float_val

	if _active_save:
		_active_save.set_data(SAVE_QUICK_FLOATS, JSON.stringify(_quick_floats), avoid_log)

	if emits_updated:
		meta_updated.emit()

func get_coins_all_time_amount() -> int:
	return get_quick_int(SAVE_COINS_ALL_TIME)

func set_coins_amount(amount:int) -> void:
	if amount < 0: amount = 0
	_active_save.set_data(SAVE_COINS_AMOUNT, JSON.stringify(amount))
	SocialPlatformManager.submit_score(SocialPlatformManager.Leaderboard.HS_RICHEST, amount)

	meta_updated.emit()

func get_coins_amount() -> int:
	return _active_save.get_json_parsed_data(SAVE_COINS_AMOUNT, "0")

func gain_coins(amount: int):
	if amount < 0:
		return spend_coins(-amount)

	set_coins_amount(get_coins_amount() + amount)
	set_quick_int(SAVE_COINS_ALL_TIME, get_coins_all_time_amount() + amount)
	return true

func spend_coins(amount: int) -> bool:
	if amount < 0:
		gain_coins(-amount)
		return true

	if !check_enough_coins(amount): return false

	set_coins_amount(get_coins_amount() - amount)
	return true

## values <= 0 always return true
func check_enough_coins(amount:int) -> bool:
	if amount <= 0: return true

	var current_amount = get_coins_amount()
	if amount > current_amount:
		check_enough_coins_failed.emit()
		return false
	else:
		return true

func peek_slot_number(save:GameSave) -> int:
	var sub = save.get_file_name().split("_")[1]
	return int(sub)

func peek_slot_name(save:GameSave) -> String:
	return save.get_data(SAVE_SLOT_NAME, _get_default_name_for_slot(save))

func peek_completed_levels(save:GameSave) -> Dictionary:
	var data = save.get_json_parsed_data(SAVE_COMPLETED_LEVELS)
	return data if data else {}

func peek_unlocked_levels(save:GameSave) -> Dictionary:
	var data = save.get_json_parsed_data(SAVE_UNLOCKED_LEVELS)
	return data if data else {}

func peek_unlocked_stars_count(save:GameSave) -> int:
	var data = save.get_json_parsed_data(SAVE_UNLOCKED_STARS)
	return data.size() if data else 0

func peek_coins_amount(save:GameSave) -> int:
	var data = save.get_json_parsed_data(SAVE_COINS_AMOUNT)
	return data if data else 0

func peek_playtime_seconds(save:GameSave) -> float:
	var data = save.get_json_parsed_data(SAVE_PLAYTIME)
	return data if data else 0

func peek_playtime_text(save:GameSave, include_seconds:bool = true) -> String:
	return seconds_to_hhmmss(floori(peek_playtime_seconds(save)), include_seconds)

func peek_last_played_date(save:GameSave) -> String:
	var data = save.get_json_parsed_data(SAVE_LAST_PLAYED_DATE)
	return data if data else "--/--/--"

func peek_creation_date(save:GameSave) -> String:
	var data = save.get_json_parsed_data(SAVE_CREATION_DATE)
	return data if data else "--/--/--"

func seconds_to_hhmmss(seconds:int, include_seconds:bool = true):
	var hours:int = int(seconds) / 3600
	var minutes:int = (int(seconds) % 3600) / 60
	var remaining_seconds:int = int(seconds) % 60

	# Format as hh:mm:ss
	if include_seconds:
		return "%02d:%02d:%02d" % [hours, minutes, remaining_seconds]
	else:
		return "%02d:%02d" % [hours, minutes]

func set_save_slot_name(save:GameSave, slot_name:String):
	if slot_name.is_empty():
		slot_name = _get_default_name_for_slot(save)

	save.set_data(SAVE_SLOT_NAME, slot_name)

func _get_default_name_for_slot(save:GameSave):
	var s = save.get_file_name().split("_")
	if s.size() > 1:
		return tr("menu_files_default_file_name") + " " + TextServerManager.get_primary_interface().format_number(s[1])
