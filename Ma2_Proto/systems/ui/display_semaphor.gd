class_name DisplaySemaphor extends Control

static var SCENE = preload("res://elements/challenge/challenge_display_semaphor.tscn")

static func cmd_semaphor(level:Level, text:String,
	condition_on:Callable,
	if_ends_then_semaphor_success:Level.CMD, success_cmd:Level.CMD, fail_cmd:Level.CMD,
	onDurationNeeded:float = 1)->Level.CMD:
	return Level_Cmd_Utils.cmd_show_semaphor(SCENE, level, text, condition_on, if_ends_then_semaphor_success, success_cmd, fail_cmd, onDurationNeeded);

@export var label_id:Label
@export var shaked:Control
@export var shake_force:float = 2.25;
@export var progress_bar:ProgressBar
@export var switch:Switch_Oning_Offing_AnimationPlayer

var _progress:float
var _inside_semaphor:bool;
var _condition:bool;

func _process(delta:float):
	_shake_process(delta, _inside_semaphor);

func _shake_process(delta:float, shake:bool):
	if shake:
		shaked.set_position(Vector2(randf_range(-shake_force, shake_force), randf_range(-shake_force, shake_force)) * 0.5, true);
	else:
		shaked.set_position(Vector2.ZERO, true);

func set_display_id(id:String):
	if label_id: label_id.text = id

func set_diplay_color(color:Color):
	if label_id: label_id.label_settings.font_color = color;

func set_display_progress(value01:float):
	_progress = value01
	if progress_bar:
		progress_bar.min_value = 0
		progress_bar.max_value = 1
		progress_bar.value = _progress

func set_inside_semaphor(inside:bool):
	_inside_semaphor = inside;

func set_condition(condition_met:bool):
	_condition = condition_met;
	switch.set_switch(_condition);
