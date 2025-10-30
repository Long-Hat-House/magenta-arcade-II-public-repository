class_name ScoreManager extends Node

const MAX_COMBO_COUNT:int = 10


const SCORE_INFO_GROUP_COPTER = preload("res://elements/score/score_info_groups/score_group_copter.tres")
const SCORE_INFO_GROUP_BOMBS = preload("res://elements/score/score_info_groups/score_group_bombs.tres")
const SCORE_INFO_GROUP_PIZZAS = preload("res://elements/score/score_info_groups/score_group_pizzas.tres")
const SCORE_INFO_GROUP_SNAKE = preload("res://elements/score/score_info_groups/score_group_snakes.tres")
const SCORE_INFO_GROUP_GENERIC = preload("res://elements/score/score_info_groups/score_group_generic.tres")

static var COLOR_NO_COMBO:Color = Color.WHITE
static var COLOR_COMBO:Color = MA2Colors.GREENISH_BLUE
static var COLOR_MAX_COMBO:Color = MA2Colors.MAGENTA

static var COMBO_TIMEOUT:Array[float] = [
	2.12, ## 1 to 2
	1.65,
	1.55, ## 3 to 4
	1.45,
	1.35, ## 5 to 6
	1.35,
	1.35, ## 7 to 8
	1.55,
	1.65, ## 9 to 10
	]

static var instance:ScoreManager
#IF TRUE, SCORE WONT BE SENT TO LEADERBOARDS. BECOMES TRUE WHEN USING "CHEAT"
var SCORE_INVALIDATED:bool = false

enum ComboFinishMode
{
	Timeout,
	Max,
	Swap,
	Hurt,
	Other #game complete, forced, etc.
}

signal score_updated(change_value:int, current_score:int)
signal score_gained(change_value:int, info:ScoreInfo, giver:ScoreGiver)

signal combo_started(bucket_score:int, starting_count:int, info:ScoreInfo, giver:ScoreGiver)
signal combo_updated(bucket_score:int, current_count:int, info:ScoreInfo, giver:ScoreGiver)
signal combo_finished(bucket_score:int, final_count:int, info:ScoreInfo, giver:ScoreGiver, mode:ComboFinishMode)

signal boost_updated()
signal entered_overtime()

class ScoreGroup:
	enum ScoreGroupState{
		Pending,
		Active,
		Fail,
		Success
	}

	var _info:ScoreInfo
	var _is_ready:bool
	var _givers:Dictionary[ScoreGiver, bool]
	var _missed:int
	var _given:int

	func _init(info:ScoreInfo) -> void:
		_info = info

	func add_giver(giver:ScoreGiver):
		_givers[giver] = true
		giver.score_given.connect(_on_score_given)
		giver.score_missed.connect(_on_score_missed)

	func add_obj_with_giver_inside(parent:Node) -> bool:
		for child in parent.get_children():
			if child is ScoreGiver:
				add_giver(child)
				return true
			elif add_obj_with_giver_inside(child):
				return true
		return false

	func get_info() -> ScoreInfo:
		return _info

	func set_group_ready():
		print("[SCORE GROUP] Group '%s' started! Givers: %s, Given: %s, Missed: %s [%s]" % [
			_info.resource_path,
			_givers.size(),
			_given,
			_missed,
			Engine.get_physics_frames()
		]);
		_is_ready = true

	func check_state() -> ScoreGroupState:
		if !_is_ready:
			return ScoreGroupState.Pending
		elif _missed > 0:
			return ScoreGroupState.Fail
		elif _given < _givers.size():
			return ScoreGroupState.Active
		else:
			return ScoreGroupState.Success

	func _on_score_given(giver:ScoreGiver):
		_given += 1

	func _on_score_missed(giver:ScoreGiver):
		_missed += 1

#Score
var _current_score:int
var _in_shop_mode:bool

#Boost
var _previous_boost:float
var _current_boost:float
var _current_boost_freeze:float
var _current_boost_punishment:float;
var _is_in_overtime:bool = false

#Combo
var _current_combo_bucket:int #Not being used. Instead of adding to the bucket, we're using the count to calculte score
var _current_combo_count:int
var _current_combo_info:ScoreInfo
var _current_combo_time_ratio:float

#Score Group
var _score_groups:Dictionary

var _debug_key_gain_score_pressed_last_frame:bool = false
var _debug_score_info = ScoreInfo.new()

#Quick Access Score
func get_current_score() -> int : return _current_score
func get_current_score_text() -> String : return get_text_for_score(get_current_score())

#Quick Access Boost
func get_current_boost() -> float : return _current_boost
func get_current_boost_multiplier() -> float : return 1 + floorf(_current_boost)/10
func is_in_max_boost() -> bool : return _current_boost >= 3

#Quick Access Combo
func is_in_combo() -> bool : return _current_combo_info != null
func get_current_combo_bucket() -> int : return _current_combo_bucket
func get_current_combo_count() -> int : return _current_combo_count
func get_current_combo_info() -> ScoreInfo : return _current_combo_info
func get_current_combo_time_ratio() -> float: return _current_combo_time_ratio

#Quick Access Overtime
func get_is_in_overtime() -> bool: return _is_in_overtime;

func _ready() -> void:
	instance = self

	_current_score = 0
	SCORE_INVALIDATED = false

	await get_tree().process_frame

	boost_updated.connect(_on_boost_updated)
	Player.instance.did_damage.connect(_on_player_did_damage)
	Player.instance.finger_took_damage.connect(_on_player_finger_took_damage)
	AudioManager.set_global_rtpc_value(AK.GAME_PARAMETERS.GAME_SCOREBOOST, 0)

func _process(delta: float) -> void:
	# OVERTIME
	var overtime:bool = false
	if LevelManager.current_level_info && Game.instance:
		overtime = Game.instance.get_timer() > LevelManager.current_level_info.score_max_seconds

	if overtime:
		if !_is_in_overtime:
			_is_in_overtime = true

			if is_in_combo():
				finish_combo(null, ComboFinishMode.Timeout)

			if _current_boost != 0:
				_current_boost = 0
				boost_updated.emit()

			entered_overtime.emit()
		return

	var key_pressed:bool = Input.is_key_pressed(KEY_1)
	if key_pressed && !_debug_key_gain_score_pressed_last_frame && DevManager.get_setting(DevManager.SETTING_DEV_SHORTCUTS_ENABLED):
		SCORE_INVALIDATED = true
		_debug_score_info.score_title = "Debug Score"
		_debug_score_info.score_value = 5000
		_debug_score_info.works_in_shop_mode = true
		gain_score(_debug_score_info, null)
	_debug_key_gain_score_pressed_last_frame = key_pressed

	# BOOST
	if _current_boost_punishment > 0:
		_current_boost_punishment -= delta ## do not let it gain boost while this is > 0
	if _current_boost_freeze > 0:
		_current_boost_freeze -= delta
		boost_updated.emit()
	elif _current_boost > 0:
		_current_boost -= delta
		if _current_boost <= 0:
			_current_boost = 0
		boost_updated.emit()

	# COMBO
	if is_in_combo():
		if get_combo_timeout() > 0:
			_current_combo_time_ratio -= delta/get_combo_timeout()
		else:
			_current_combo_time_ratio = 0

		if _current_combo_time_ratio <= 0:
			finish_combo(null, ComboFinishMode.Timeout)

	# SCORE GROUPS
	var groups_to_clear:Dictionary
	for group_id in _score_groups:
		var group:ScoreGroup = _score_groups[group_id]
		match group.check_state():
			ScoreGroup.ScoreGroupState.Success:
				gain_score(group.get_info(), null)
				groups_to_clear[group_id] = true
			ScoreGroup.ScoreGroupState.Fail:
				groups_to_clear[group_id] = true
	for group_id in groups_to_clear:
		_score_groups.erase(group_id)

func get_combo_timeout() -> float:
		return COMBO_TIMEOUT[get_current_combo_count() - 1];

func get_text_for_score(val:int) -> String:
	return "%07d" % val

func gain_score(info:ScoreInfo, giver:ScoreGiver):
	if get_is_in_overtime() && !_in_shop_mode:
		return

	var n_in_combo:int = 0

	if !info:
		push_error("[SCORE MANAGER] NULL Info given by Giver '%s (%s)'!" % [giver, giver.owner])
		return

	if _in_shop_mode && !info.works_in_shop_mode:
		return

	var change:int = info.score_value * (get_current_boost_multiplier() if !info.ignore_boost_multiplier else 1)

	#Combo
	if info.adds_to_combo && change > 0:
		_current_combo_count += 1
		_current_combo_bucket += change

		#_current_combo_bucket = _current_combo_count*_current_combo_count if _current_combo_count > 1 else 0
		_current_combo_time_ratio = 0.25+1.0/_current_combo_count
		if is_in_combo():
			if _current_combo_count < MAX_COMBO_COUNT:
				combo_updated.emit(_current_combo_bucket, _current_combo_count, info, giver)
			if _current_combo_count == MAX_COMBO_COUNT:
				finish_combo(giver, ComboFinishMode.Max)
		else:
			_current_combo_info = info
			combo_started.emit(_current_combo_bucket, _current_combo_count, info, giver)

	#Score Value
	if change != 0:
		#if not adds to combo, adds directly!
		if !info.adds_to_combo:
			_current_score += change
		score_gained.emit(change, info, giver)
		score_updated.emit(change, _current_score)

func gain_boost(gain_val:float):
	if _current_boost_punishment > 0:
		return
	_current_boost_freeze = 2
	if _current_boost >= 3:
		return
	_current_boost += gain_val
	if _current_boost > 3:
		_current_boost = 3
	if _current_boost < 0:
		_current_boost = 0
	boost_updated.emit()

func _on_boost_updated():
	#Set RTPC value so that Audio can sync
	AudioManager.set_global_rtpc_value(AK.GAME_PARAMETERS.GAME_SCOREBOOST, _current_boost)

	var new_boost:int = get_current_boost()
	if new_boost > _previous_boost:
		AudioManager.post_one_shot_event(AK.EVENTS.PLAY_UI_SCORE_BOOST_INCREASE)
	elif new_boost < _previous_boost:
		AudioManager.post_one_shot_event(AK.EVENTS.PLAY_UI_SCORE_BOOST_DECREASE)
	_previous_boost = new_boost

func finish_combo(giver:ScoreGiver = null, mode:ComboFinishMode = ComboFinishMode.Other):
	if is_in_combo():
		_current_combo_bucket = _current_combo_count * _current_combo_bucket
		_current_score += _current_combo_bucket
		score_updated.emit(_current_combo_bucket, _current_score)
		combo_finished.emit(_current_combo_bucket, _current_combo_count, _current_combo_info, giver, mode)

	_current_combo_count = 0
	_current_combo_bucket = 0
	_current_combo_time_ratio = 0
	_current_combo_info = null

func miss_score(info:ScoreInfo, giver:ScoreGiver):
	pass

func get_score_group(group_id:StringName, score_info:ScoreInfo) -> ScoreGroup:
	if !score_info:
		push_error("[SCORE MANAGER] No score info in creating score group!!")
		return null
	if _score_groups.has(group_id):
		return _score_groups[group_id] as ScoreGroup
	else:
		var group:ScoreGroup = ScoreGroup.new(score_info)
		print("[SCORE GROUP] [SCORE MANAGER] Created score group '%s' of type '%s' [%s]" % [
			group_id,
			score_info.resource_path,
			Engine.get_physics_frames()
		]);
		_score_groups[group_id] = group
		return group

func set_in_shop_mode(val:bool):
	_in_shop_mode = val

func _on_player_did_damage(dam:Health.DamageData):
	if dam.scores:
		gain_boost(dam.amount/10)

func _on_player_finger_took_damage(token:PlayerToken):
	_current_boost = 0
	_current_boost_freeze = 0
	_current_boost_punishment = 3
	boost_updated.emit()
