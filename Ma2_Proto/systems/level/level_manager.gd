extends Control

const LEVEL_TRANSITION = preload("res://systems/level/level_transition.tscn")

signal transition_started
signal transition_ended
signal removing_current_level
signal level_started
@export  var _level_viewport:SubViewport

var is_transitioning:bool
var current_level_info:LevelInfo
var current_level:Level

var loading_progress:Array = [0]

#when changing level directly, we pretend that we're transitioning in Level Manager itself
var _self_transitioning:bool

var elements_node:Node3D;

func _ready() -> void:
	visible = false

func get_topmost_node():
	#return current_level;
	if elements_node && !elements_node.is_inside_tree():
		elements_node.queue_free()

	if elements_node == null or not is_instance_valid(elements_node):
		elements_node = Node3D.new();
		elements_node.name = "elements";
		current_level.add_child(elements_node);
	return elements_node;

func change_with_transition(transition_scene:PackedScene, lvl_info:LevelInfo):
	AudioManager.music_stop_all()
	TimeManager.remove_all_time_changes()
	if transition_scene:
		var t = transition_scene.instantiate()
		get_tree().root.add_child(t)
		t.transition_in(lvl_info)
		while is_transitioning:
			await get_tree().process_frame
	else:
		change_level_by_info(lvl_info)

func inform_transition_started():
	if is_transitioning:
		push_error("[LEVEL MANAGER] Already transitioning, will ignore!")
		return
	loading_progress[0] = 0
	visible = true
	is_transitioning = true
	transition_started.emit()

func inform_transition_ended():
	if !is_transitioning:
		push_error("[LEVEL MANAGER] Wasn't transitioning, will ignore!")
		return
	is_transitioning = false
	transition_ended.emit()

func change_level_by_info(level_info:LevelInfo, initial_subscene:PackedScene = null):
	if !is_transitioning:
		_self_transitioning = true
		inform_transition_started()

	loading_progress[0] = 0
	ResourceLoader.load_threaded_request(level_info.lvl_resource_path)
	while loading_progress[0] < 1:
		ResourceLoader.load_threaded_get_status(level_info.lvl_resource_path, loading_progress)
		await get_tree().process_frame
	var lvl_res = ResourceLoader.load_threaded_get(level_info.lvl_resource_path) as Resource

	if lvl_res is LevelSet:
		change_level_by_set(lvl_res, initial_subscene, level_info)
	elif lvl_res is PackedScene:
		change_level_by_scene(lvl_res, level_info)
	else:
		push_error("[LEVEL MANAGER] Level resource type not supported for LevelInfo: " + level_info.resource_name)

func change_level_by_set(base_set:LevelSet, initial_subscene:PackedScene = null, level_info:LevelInfo = null):
	if !is_transitioning:
		_self_transitioning = true
		inform_transition_started()

	if initial_subscene == null:
		initial_subscene = base_set.parent_level

	if !base_set.parent_level:
		change_level_by_scene(initial_subscene, level_info)
		return

	change_level_by_scene(base_set.parent_level, level_info, base_set, initial_subscene)

func change_level_by_scene(level_scene:PackedScene, level_info:LevelInfo = null, base_set:LevelSet = null, initial_subscene:PackedScene = null):
	if !is_transitioning:
		_self_transitioning = true
		inform_transition_started()

	loading_progress[0] = 1

	print("[LEVEL MANAGER] Will save and wait for it")
	removing_current_level.emit()
	await SaveManager.save()
	print("[LEVEL MANAGER] Will remove current level!")
	if current_level:
		current_level.queue_free()

	await get_tree().process_frame
	Wwise.set_state_id(AK.STATES.GAMEPLAY.GROUP, AK.STATES.GAMEPLAY.STATE.NONE)
	current_level_info = level_info

	print("[LEVEL MANAGER] Will instantiate new level!")
	var lvl = level_scene.instantiate() as Level
	current_level = lvl

	if base_set && initial_subscene:
		current_level.add_sub_set(base_set, initial_subscene)

	_level_viewport.add_child(lvl)

	await get_tree().process_frame

	print("[LEVEL MANAGER] Will play new level!")
	lvl.play_level()
	get_tree().paused = false
	level_started.emit();

	if _self_transitioning:
		inform_transition_ended()
		_self_transitioning = false
