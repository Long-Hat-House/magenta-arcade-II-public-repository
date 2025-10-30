class_name ChallengeController extends Control

static var instance:ChallengeController

@export var _panel_begin:ChallengePanelBegin
@export var _panel_victory:ChallengePanelVictory
@export var _panel_metrics:ChallengePanelMetrics
@export var _text_pop:ChallengeTextPop

@export var _sfx_begin:WwiseEvent
@export var _sfx_fail:WwiseEvent
@export var _sfx_victory:WwiseEvent

func _ready() -> void:
	instance = self

func cmd_end_shortcut(condition_branch:Callable, challenge_info:ChallengeInfo, wait_for_show_victory:float = 0, grid_positions:Array[Vector2i] = [])-> Level.CMD:
	return Level.CMD_Branch.new(condition_branch,
			cmd_victory(challenge_info, wait_for_show_victory, grid_positions),
			cmd_fail(challenge_info)
	)

func cmd_just_make_altars(challenge_info:ChallengeInfo, grid_positions:Array[Vector2i] = []):
	return Level.CMD_Callable.new(_panel_victory.make_altars.bind(challenge_info, grid_positions));

func cmd_victory(challenge_info:ChallengeInfo, wait_for_show:float = 0, grid_positions:Array[Vector2i] = [], custom_show:Level.CMD = null) -> Level.CMD:
	var array:Array[Level.CMD] = []

	array.push_back(Level.CMD_Callable.new(
		func():
			if Game.instance:
				Game.instance.kill_all_projectiles()
				Game.instance.kill_all_enemies()
	))
	array.push_back(Level.CMD_Callable.new(_panel_metrics.hide_and_clear))
	if custom_show:
		array.push_back(Level.CMD_Callable.new(_panel_victory.set_info.bind(challenge_info, grid_positions, false)))
		if wait_for_show > 0:
			array.push_back(Level.CMD_Wait_Seconds.new(wait_for_show))
		array.push_back(Level.CMD_Callable.new(_panel_victory.panel_show))
		array.push_back(Level.CMD_Callable.new(_play_sfx.bind(_sfx_victory)))
		array.push_back(custom_show);
		array.push_back(Level.CMD_Callable.new(_panel_victory.panel_hide))
		array.push_back(Level.CMD_Wait_Signal.new(_panel_victory.hide_completed))
	else:
		array.push_back(Level.CMD_Callable.new(_panel_victory.set_info.bind(challenge_info, grid_positions)))
		if wait_for_show > 0:
			array.push_back(Level.CMD_Wait_Seconds.new(wait_for_show))
		array.push_back(Level.CMD_Callable.new(_play_sfx.bind(_sfx_victory)))
		array.push_back(Level.CMD_Callable.new(_panel_victory.panel_show))
		array.push_back(Level.CMD_Wait_Signal.new(_panel_victory.hide_completed))

	return Level.CMD_Sequence.new(array)

func cmd_begin(challenge_info:ChallengeInfo, waits:bool = true) -> Level.CMD:
	var array:Array[Level.CMD] = []

	array.push_back(Level.CMD_Callable.new(_panel_begin.set_info.bind(challenge_info)))
	array.push_back(Level.CMD_Callable.new(_play_sfx.bind(_sfx_begin)))
	array.push_back(Level.CMD_Callable.new(_panel_begin.panel_show))

	if waits:
		array.push_back(Level.CMD_Wait_Signal.new(_panel_begin.hide_completed))

	array.push_back(Level.CMD_Callable.new(_panel_metrics.panel_show))

	return Level.CMD_Sequence.new(array)

func cmd_fail(challenge_info:ChallengeInfo) -> Level.CMD:
	var array:Array[Level.CMD] = []

	array.push_back(Level.CMD_Callable.new(_panel_metrics.hide_and_clear))
	array.push_back(Level.CMD_Callable.new(_play_sfx.bind(_sfx_fail)))
	array.push_back(Level.CMD_Callable.new(_text_pop.set_text.bind(challenge_info.challenge_fail_title, ChallengeTextPop.Style.Fail)))

	return Level.CMD_Sequence.new(array)

func set_text_pop(text:String):
	_text_pop.set_text(text)

func add_metric_display(instance:Control):
	_panel_metrics.add_metric_display(instance)

func _play_sfx(sfx_event:WwiseEvent):
	if sfx_event: sfx_event.post(self)
