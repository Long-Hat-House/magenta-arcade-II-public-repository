@icon("res://addons/Wwise/editor/images/wwise_audio_speaker.svg")
class_name AkEvent3DLoop extends Node3D

enum GameEvent
{
	None,
	Ready,
	EnterTree,
	ExitTree,
}

@export var _start_loop_on:GameEvent;
@export var _stop_loop_on:GameEvent;
@export var fade_out_time:float = 0.2;
@export var custom_object:Node;

@export var loop_begin_event:AkEvent3D:
	get:
		return loop_begin_event;
	set(value):
		loop_begin_event = value;
		if value:
			loop_begin_event_id = _find_event_id(value);
		else:
			loop_begin_event_id = 0;
		update_configuration_warnings();
var loop_begin_event_id:int = 0;
@export var loop_finish_event:AkEvent3D:
	get:
		return loop_finish_event;
	set(value):
		loop_finish_event = value;
		if value:
			loop_finish_event_id = _find_event_id(value);
		else:
			loop_finish_event_id = 0;
		update_configuration_warnings();
var loop_finish_event_id:int = 0;

@export var loop_rtpc:WwiseRTPC;

@export var _debug:bool;

var _playing_id:int

func _get_fade_out_time()->int:
	return floori(fade_out_time * 1000);

func _ready():
	if Engine.is_editor_hint():
		if get_children().size() == 0:
			_make_ak_event_child("Begin");
			_make_ak_event_child("End");
		return;
	if loop_begin_event == null || loop_finish_event == null:
		_find_events_in_children();
	loop_begin_event_id = _find_event_id(loop_begin_event);
	loop_finish_event_id = _find_event_id(loop_finish_event);
	_try_event(GameEvent.Ready);

func _process(delta:float):
	Wwise.set_3d_position(self, global_transform);

func _find_events_in_children():
	for child in get_children():
		var evt := child as AkEvent3D;
		if evt:
			if loop_begin_event == null and evt != loop_finish_event:
				loop_begin_event = evt;
			elif loop_finish_event == null and evt != loop_begin_event:
				loop_finish_event = evt;
			if loop_begin_event != null and loop_finish_event != null:
				break;

func _make_ak_event_child(name:String):
	var event:AkEvent3D = AkEvent3D.new();
	event.name = name;
	add_child(event);

func _enter_tree() -> void:
	Wwise.register_game_obj(self, self.name);

	_try_event(GameEvent.EnterTree);

	if Engine.is_editor_hint():
		if get_children().size() == 0:
			_make_ak_event_child("Begin");
			_make_ak_event_child("End");
		return;

func _exit_tree() -> void:
	_try_event(GameEvent.ExitTree);
	if _playing_id > 0:
		Wwise.stop_event(_playing_id, _get_fade_out_time(), AkUtils.AK_CURVE_LOG3)
	Wwise.unregister_game_obj(self);

func _try_event(event:GameEvent):
	if _start_loop_on == event:
		start_loop();
	if _stop_loop_on == event:
		stop_loop();

func start_loop():
	if _debug: _print_evt("begin loop", loop_begin_event, loop_begin_event_id);

	if _playing_id > 0:
		Wwise.stop_event(_playing_id,  _get_fade_out_time(), AkUtils.AK_CURVE_LOG3)

	_playing_id = _post_event(loop_begin_event_id);

func stop_loop():
	if _playing_id == 0: return
	if _debug: _print_evt("end loop", loop_finish_event, loop_finish_event_id);
	_post_event(loop_finish_event_id);
	_playing_id = 0;
	
	
## This is here because I implemented with this name and don't know who used it. Sorry.
func set_looping(is_playing:bool):
	set_playing(is_playing);	
	
## Start or Stop with a boolean.	
func set_playing(is_playing:bool):
	if is_playing:
		start_loop();
	else:
		stop_loop();	
		
func set_rtpc_value(value:float):
	if loop_rtpc:
		loop_rtpc.set_value(self, value);

func _print_evt(s:String, akEvent:AkEvent3D, id:int):
	print("%s did '%s' with event %s (id:%s) with id %s" % [name, s, akEvent.event["name"], akEvent.event["id"], id]);

func _get_post_object()->Node:
	if custom_object != null:
		return custom_object;
	else:
		return self;

func _post_event(id:int) -> int:
	var p_id = Wwise.post_event_id(id, _get_post_object());
	if _debug:
		print("%s -> posting event loop %s" % [_get_post_object(), id]);

	return p_id

func post_one_shot_event(id:int):
	Wwise.post_event_id(id, _get_post_object());
	if _debug:
		print("%s -> posting one shot event %s" % [_get_post_object(), id]);

func _find_event()->AkEvent3D:
	for child in get_children():
		if child is AkEvent3D:
			return child as AkEvent3D;
	return null;

func _find_event_id(e:AkEvent3D)->int:
	if !is_instance_valid(e) or !e.event:
		push_error("[AK EVENT] Event not FOUND, probably need to re-assign in inspector. Path: " + get_parent().name + "/" + name if get_parent() else name)
		return 0
	return e.event["id"];

func _get_configuration_warnings() -> PackedStringArray:
	var errors:Array[String] = [];
	if loop_begin_event == null:
		errors.push_back("No loop begin event!");
	if loop_finish_event == null:
		errors.push_back("No loop end event!");
	return errors;

func set_parameter(id:int, value:float)->void:
	Wwise.set_rtpc_value_id(id, value, _get_post_object());

func get_parameter(id:int)->float:
	return Wwise.get_rtpc_value_id(id, _get_post_object());
