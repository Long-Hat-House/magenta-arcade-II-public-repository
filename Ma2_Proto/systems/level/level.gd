class_name Level extends Node3D

#region CMDs
class CMD:
	func _ident(ident_level) -> String:
		var ident:String = ""
		while ident_level:
			ident += " "
			ident_level -= 1
		return ident

	func _get_text(_ident_level:int) -> String:
		return "-- empty cmd nop --"

	## Prepares for execution, can be important for reusing/repeating CMDs
	func _prepare():
		pass

	## Returns true if finished! False if it's still running
	func _cmd_process(_delta:float) -> bool:
		return true

	func _to_string():
		return _get_text(0);

	static func Nop()->CMD:
		return CMD.new();

	static func NopEternally()->CMD:
		return CMD_Wait_Callable.new(func(): return false);

class CMD_Nop extends CMD:
	func _get_text(ident_level:int) -> String:
		return "<<NOP>>";

	func _cmd_process(delta:float) -> bool:
		return true;

class CMD_Wait_Forever extends CMD:
	func _get_text(ident_level:int) -> String:
		return "<<FOREVER>>";

	func _cmd_process(delta:float) -> bool:
		return false;

class CMD_Branch extends CMD:
	var _cmd_true:CMD
	var _cmd_false:CMD
	var _condition:Callable
	var _condition_tested:bool
	var _condition_result:bool

	func _get_text(ident_level:int) -> String:
		var text:String = "CMD_Branch:"
		text += "\n" + _ident(ident_level) + "IF: " + _condition.get_method() + ("," + str(_condition_result) if _condition_tested else "")
		text += "\n" + _ident(ident_level) + ("-> TRUE: " if _condition_tested && _condition_result else "TRUE: ") + _cmd_true._get_text(ident_level+3)
		text += "\n" + _ident(ident_level) + ("-> FALSE: " if _condition_tested && !_condition_result else "FALSE: ") + _cmd_false._get_text(ident_level+3)
		return text

	func _prepare():
		_cmd_true._prepare()
		_cmd_false._prepare()
		_condition_tested = false

	func _init(condition:Callable, cmd_true:CMD, cmd_false:CMD):
		_cmd_true = cmd_true
		_cmd_false = cmd_false
		_condition = condition

	func _cmd_process(delta:float) -> bool:
		if not _condition_tested:
			_condition_result = _condition.call()
			_condition_tested = true

		if _condition_result:
			return _cmd_true._cmd_process(delta)
		else:
			return _cmd_false._cmd_process(delta)

class CMD_Process extends CMD:
	var _funcWithDelta:Callable;

	func _init(func_with_delta_returns_if_finished:Callable):
		_funcWithDelta = func_with_delta_returns_if_finished;

	func _get_text(_ident_level:int) -> String:
		return "CMD_Process '%s'..." % [_funcWithDelta];

	## Returns true if finished! False if it's still running
	func _cmd_process(delta:float) -> bool:
		var return_value = _funcWithDelta.call(delta);
		if return_value == null:
			return false;
		else:
			return return_value;

class CMD_Parallel extends CMD:
	var _cmds:Array[CMD]
	var _finish_count:int

	var _finished:Array[CMD];

	func _get_text(ident_level:int) -> String:
		var text:String = "CMD_Parallel: (%s of %s complete)" % [_finished.size(), self._finish_count];
		for cmd in _cmds:
			var is_executing:bool = !_finished_condition() and _finished.has(cmd);
			text += "\n" + _ident(ident_level) + ("-> " if is_executing else "   ") + cmd._get_text(ident_level+3)
		return text

	func _prepare():
		for cmd in _cmds:
			cmd._prepare()
		_finished.clear();

	## _finish_count higher than cmds.size() will make it run forever (or until something else stops it)
	## _finish_count of 0 or less will make it stop on first execution even if no child has finished
	func _init(cmds:Array[CMD], finish_count:int = 1):
		_cmds = cmds
		_finish_count = finish_count

	func _cmd_process(delta:float) -> bool:

		for cmd in _cmds:
			if _finished.has(cmd):
				continue;
			if cmd._cmd_process(delta):
				_finished.push_back(cmd);

		return _finished_condition();

	func _finished_condition()->bool:
		return _finished.size() >= _finish_count

class CMD_Parallel_Complete extends CMD_Parallel:
	func _init(cmds:Array[CMD]):
		super._init(cmds, cmds.size());

	func _get_text(ident_level:int) -> String:
		var text:String = "CMD_Parallel_Complete: (%s of %s complete)" % [_finished.size(), self._finish_count];
		for cmd in _cmds:
			var is_executing:bool = !_finished_condition() and _finished.has(cmd);
			text += "\n" + _ident(ident_level) + ("-> " if is_executing else "   ") + cmd._get_text(ident_level+3)
		return text

class CMD_Sequence extends CMD:
	var _extra_repeats:int
	var _cmds_original:Array[CMD]

	var _cmds_copy:Array[CMD]
	var _current_repeat:int
	var _current_cmd:CMD

	func _get_name() -> String:
		return "CMD_Sequence";

	func _get_text(ident_level:int) -> String:
		var text:String =  _get_name() + " (Repeats: " + str(_current_repeat) + " of " + (str(_extra_repeats+1) if _extra_repeats >= 0 else "inf") + "):"

		for cmd in _cmds_original:
			text += "\n" + _ident(ident_level) + ("-> " if cmd == _current_cmd else "   ") + cmd._get_text(ident_level+3)
		return text

	func _prepare():
		_current_repeat = 0
		_current_cmd = null;
		_cmds_copy = _cmds_original.duplicate()

	## Executes the arrya of command in order, the extra_repeats are the amount of repeats. If less than 0, then repeats this sequence infinitely until something else stops it.
	func _init(cmds:Array[CMD], extra_repeats:int = 0):
		_cmds_original = cmds
		_extra_repeats = extra_repeats

	func _cmd_process(delta:float) -> bool:
		if  _extra_repeats >= 0 and _current_repeat > _extra_repeats:
			return true # If already done my work

		while _current_cmd == null or _current_cmd._cmd_process(delta):
			delta = 0 #new commands will be processed for the first time with delta time 0

			#gets next cmd
			_current_cmd = _cmds_copy.pop_front()
			if _current_cmd != null:
				_current_cmd._prepare()
			elif _cmds_copy.size() <= 0: #if there's nothing more in the array, finish a repeat
				_current_repeat += 1
				_cmds_copy = _cmds_original.duplicate()
				break


		if _extra_repeats < 0: #repeats forever (until something else stops this cmd)
			return false
		elif  _current_repeat > _extra_repeats:
			return true

		return false

## Executes all of the cmds, in a random order. Extra_repeats works the same as sequence
class CMD_Sequence_Random extends CMD_Sequence:
	func _prepare():
		super._prepare();
		_cmds_copy.shuffle();

	func _get_name()->String:
		return "CMD_Sequence RANDOM"

	func _cmd_process(delta:float) -> bool:
		if  _extra_repeats >= 0 and _current_repeat > _extra_repeats:
			return true # If already done my work

		while _current_cmd == null or _current_cmd._cmd_process(delta):
			delta = 0 #new commands will be processed for the first time with delta time 0

			#gets next cmd
			_current_cmd = _cmds_copy.pop_front()
			if _current_cmd != null:
				_current_cmd._prepare()
			elif _cmds_copy.size() <= 0: #if there's nothing more in the array, finish a repeat
				_current_repeat += 1
				_cmds_copy = _cmds_original.duplicate()
				_cmds_copy.shuffle();
				break


		if _extra_repeats < 0: #repeats forever (until something else stops this cmd)
			return false
		elif  _current_repeat > _extra_repeats:
			return true

		return false

## Executes one of the array of commands, chosen randomly.
class CMD_Selector_Random extends CMD:
	var _cmds_original:Array[CMD]

	var _current_cmd:CMD

	func _prepare():
		_current_cmd = null;
		_current_cmd = _cmds_original.pick_random();
		_current_cmd.prepare();

	## Executes one of the array of commands, chosen randomly.
	func _init(cmds:Array[CMD]):
		_cmds_original = cmds

	func _cmd_process(delta:float) -> bool:
		if _current_cmd != null:
			return _current_cmd._cmd_process(delta);

		return true;

class CMD_Repeat_While extends CMD:
	var _condition:Callable;
	var _break_in_between_cmds:bool = false;
	var _cmds_original:Array[CMD]

	var _cmds_copy:Array[CMD]
	var _current_cmd:CMD

	func _get_text(ident_level:int) -> String:
		var text:String = "CMD_While (While " + str(_condition)  + "):"

		for cmd in _cmds_original:
			text += "\n" + _ident(ident_level) + ("-> " if cmd == _current_cmd else "   ") + cmd._get_text(ident_level+3)
		return text

	func _prepare():
		_cmds_copy = _cmds_original.duplicate()
		_current_cmd = null;

	## Executes the arrya of command in order, the extra_repeats are the amount of repeats. If less than 0, then repeats this sequence infinitely until something else stops it.
	func _init(condition:Callable, cmds:Array[CMD], break_in_between_cmds:bool = false):
		_cmds_original = cmds
		_condition = condition
		_break_in_between_cmds = break_in_between_cmds;

	func _cmd_process(delta:float) -> bool:
		if not _condition.call():
			return true # If already done my work

		while _current_cmd == null or _current_cmd._cmd_process(delta):
			if _break_in_between_cmds:
				if not _condition.call():
					return true;

			delta = 0 #new commands will be processed for the first time with delta time 0

			#gets next cmd
			_current_cmd = _cmds_copy.pop_front()
			if _current_cmd != null:
				_current_cmd._prepare()
			elif _cmds_copy.size() <= 0: #if there's nothing more in the array, finish a repeat
				_cmds_copy = _cmds_original.duplicate()
				break

		return false

class CMD_Callable extends CMD:
	var _callable:Callable
	var _called:bool = false

	func _get_text(_ident_level:int) -> String:
		return "CMD_Callable (" + _callable.get_method() + ")"

	func _prepare():
		_called = false

	func _init(callable:Callable):
		_callable = callable

	func _cmd_process(_delta:float) -> bool:
		if !_called && _callable.is_valid():
			_callable.call()
			_called = true
		return _called

class CMD_Show_Level_Info extends CMD:
	var _level_info:LevelInfo
	var _showed:bool = false

	func _get_text(_ident_level:int) -> String:
		return "CMD_Show_Level_Name (" + str(_level_info) + ")"

	func _prepare():
		_showed = false

	func _init(level_info:LevelInfo):
		_level_info = level_info

	func _cmd_process(_delta:float) -> bool:
		if !_showed:
			HUD.instance.show_level_info(_level_info)
			_showed = true
		return _showed


class CMD_Music_Event extends CMD:
	var _event_id:int
	var _called:bool = false

	func _get_text(_ident_level:int) -> String:
		return "CMD_Music_Event (" + str(_event_id) + ")"

	func _prepare():
		_called = false

	func _init(event_id:int):
		_event_id = event_id

	func _cmd_process(_delta:float) -> bool:
		if !_called:
			AudioManager.post_music_event(_event_id)
			_called = true
		return _called

class CMD_Level_Environment extends CMD:
	var _state_id:StringName
	var _called:bool = false

	func _get_text(_ident_level:int) -> String:
		return "CMD_Level_Environment (" + str(_state_id) + ")"

	func _prepare():
		_called = false

	func _init(state_id:StringName):
		_state_id = state_id

	func _cmd_process(_delta:float) -> bool:
		if !_called:
			LevelEnvironment.set_state(_state_id)
			_called = true
		return _called

class CMD_Wait_Int extends CMD:
	var value:int = 0
	var _threshold:int = 1

	func _init(threshold:int = 1):
		_threshold = threshold

	func _get_text(_ident_level:int) -> String:
		return "CMD_Wait_Int (" + str(_threshold) + "): " + str(value)

	func _prepare():
		value = 0

	func _cmd_process(delta:float) -> bool:
		return value >= _threshold

class CMD_Wait_Seconds extends CMD:
	var _duration:float
	var _elapsed_time:float
	var _elapsed_callable:Callable

	func _get_text(_ident_level:int) -> String:
		return "CMD_Wait_Seconds (" + str(_duration) + "): " + str(_elapsed_time)

	func _prepare():
		_elapsed_time = 0

	func _init(duration:float, elapsed_callable:Callable = Callable()):
		_duration = duration
		_elapsed_callable = elapsed_callable

	func _cmd_process(delta:float) -> bool:
		_elapsed_time += delta

		if _elapsed_callable.is_valid():
			_elapsed_callable.call(_elapsed_time)

		return _elapsed_time >= _duration

class CMD_Wait_Seconds_Dynamic extends CMD:
	var _duration_callable:Callable
	var _duration:float
	var _elapsed_time:float
	var _elapsed_callable:Callable

	func _get_text(_ident_level:int) -> String:
		return "CMD_Wait_Seconds_Dynamic (%s() -> %s): %s" % [_duration_callable, _duration, _elapsed_time]

	func _prepare():
		_duration = _duration_callable.call()
		_elapsed_time = 0

	func _init(duration:Callable, elapsed_callable:Callable = Callable()):
		_duration_callable = duration;
		_elapsed_callable = elapsed_callable

	func _cmd_process(delta:float) -> bool:
		_elapsed_time += delta

		if _elapsed_callable.is_valid():
			_elapsed_callable.call(_elapsed_time)

		return _elapsed_time >= _duration

class CMD_Print_Log extends CMD:
	var _string:String;
	var _color:String;

	func _init(what:String, color_rich_print:String = "white"):
		_string = what;
		_color = color_rich_print;

	func _get_text(_ident_level:int) -> String:
		return "# " + _string

	func _cmd_process(delta:float) -> bool:
		print_rich("[color=%s]%s[/color] [%s]" % [_color, _string, Engine.get_physics_frames()]);
		return true;

class CMD_Wait_Signal extends CMD:
	var _signal:Signal
	var _emitted:bool = false

	func _get_text(_ident_level:int) -> String:
		return "CMD_Wait_Signal (" + _signal.get_name() + ", emitted: " + str(_emitted) + ")"

	func _prepare():
		_emitted = false

	func _init(signal_to_wait:Signal):
		_signal = signal_to_wait
		_signal.connect(_signal_emitted)

	func _cmd_process(_delta:float) -> bool:
		return _emitted

	func _signal_emitted(_a=null,_b=null,_c=null,_d=null,_e=null,_f=null,_g=null):
		if !_emitted:
			_emitted = true

	func free() -> void:
		if is_instance_valid(_signal):
			_signal.disconnect(_signal_emitted);

class CMD_Wait_Callable extends CMD:
	enum Operator {
		EQUAL,
		NOT_EQUAL,
		LESS_THAN,
		GREATER_THAN,
		LESS_THAN_OR_EQUAL,
		GREATER_THAN_OR_EQUAL,
	}

	var _callable:Callable
	var _operator:Operator
	var _waited_value

	func _get_text(_ident_level:int) -> String:
		return "CMD_Wait_Callable (" + _callable.get_method() + " - " + str(_operator) + " - " + str(_waited_value) + ")"

	func _init(callable:Callable, waited_value = true, operator:Operator = Operator.EQUAL):
		_callable = callable
		_waited_value = waited_value
		_operator = operator

	func _cmd_process(delta) -> bool:
		match _operator:
			Operator.EQUAL:
				return _callable.call() == _waited_value
			Operator.NOT_EQUAL:
				return _callable.call() != _waited_value
			Operator.LESS_THAN:
				return _callable.call() < _waited_value
			Operator.GREATER_THAN:
				return _callable.call() > _waited_value
			Operator.LESS_THAN_OR_EQUAL:
				return _callable.call() <= _waited_value
			Operator.GREATER_THAN_OR_EQUAL:
				return _callable.call() >= _waited_value
			_:
				return _callable.call() == _waited_value


class CMD_Wait_ObjsGroup extends CMD:
	var _group:String
	var _objs:LevelObjectsController
	var _max_amount:int

	func _get_text(ident_level:int) -> String:
		var c = _objs.get_group_elements_count(_group)
		return "CMD_Wait_ObjsGroup (" + _group + ": "+ str(c) + " <= " + str(_max_amount) + ")"

	func _init(objs:LevelObjectsController, group_id:String, max_amount:int = 0):
		_group = group_id
		_objs = objs
		_max_amount = max_amount

	func _cmd_process(delta) -> bool:
		return _objs.get_group_elements_count(_group) <= _max_amount


class CMD_Await_AsyncCallable extends CMD:
	var _callable:Callable
	var _waiting:bool
	var _called:bool
	var _proof:Object;
	var _has_proof:bool;

	func _get_text(ident_level:int) -> String:
		return "CMD_Await_AsyncCallable (%s)" % _callable.get_method()

	func _prepare():
		_waiting = false
		_called = false

	func _init(callable:Callable, proof:Object):
		_callable = callable
		_proof = proof;
		_has_proof = proof != null;

	func _call():
		_called = true
		_waiting = true
		if _callable.is_valid():
			await _callable.call()
		else:
			LogUtils.log_error("Callable %s is not valid!" % _callable);
		_waiting = false;
		if not is_instance_valid(self) or (_has_proof and (not _proof or not is_instance_valid(_proof))): return
		_called = true;
		_proof = null;
		_has_proof = false;

	func _cmd_process(delta:float) -> bool:
		if !_called:
			_call()
		return !_waiting
#endregion

signal level_finished;

@export var _game_pack_scene:PackedScene
static var _game_pack_node:Node

var cam:LevelCameraController:
	get: return LevelCameraController.instance
var objs:LevelObjectsController:
	get: return LevelObjectsController.instance
var stage:LevelStageController:
	get: return LevelStageController.instance

var _level_ready:bool = false
var _level_finished:bool = false

var _parent_level:Level

var _cmds:Array[CMD] = []
var _current_cmd:CMD

var _current_sub_level_id:int = -1
var _current_sub_level:Level = null
var _sub_levels:Array[PackedScene]

func _enter_tree():
	if _game_pack_scene && !is_instance_valid(_game_pack_node):
		_game_pack_node = _game_pack_scene.instantiate()
		add_child(_game_pack_node)

	DevManager.add_debug_callback(_level_cmd_CURRENT_TEXT, "CMD/" + name + str(get_instance_id()) + "/Current")
	DevManager.add_debug_callback(_level_cmd_NEXT_TEXT, "CMD/" + name + str(get_instance_id()) + "/Next")

func _exit_tree():
	DevManager.remove_debug_callback("CMD/" + name + str(get_instance_id()) + "/Current")
	DevManager.remove_debug_callback("CMD/" + name + str(get_instance_id()) + "/Next")

func play_level():
	_level_ready = true
	print("-- playing level %s" % [self]);

func play_sublevel(parent_level:Level):
	_parent_level = parent_level
	play_level()

func timer(seconds:float):
	await get_tree().create_timer(seconds).timeout

func await_for_level_ready():
	while not _level_ready:
		await get_tree().process_frame

func set_level_finished()->void:
	if _level_finished: return
	print("[LEVEL] Level finished! [%s]" % [Engine.get_physics_frames()]);
	_level_finished = true
	level_finished.emit();

func add_sub_set(level_set:LevelSet, starting_scene:PackedScene):
	var main_scene = level_set.parent_level
	if main_scene == starting_scene: #already found!
		starting_scene = null
	_add_sub_set_recursive(level_set, starting_scene, main_scene, [])

#returns the starting_scene so parent calls know that the starting scene was not yet found. (Or null if it was found)
func _add_sub_set_recursive(level_set:LevelSet, starting_scene:PackedScene, main_scene:PackedScene, unplayed_parent_scenes:Array[PackedScene]) -> PackedScene:
	var parent_scene = level_set.parent_level
	if parent_scene && parent_scene != main_scene: #first scene is already playing (it is actually "self") and don't need to be treated
		if starting_scene && parent_scene == starting_scene: #we clicked a parent_level
			starting_scene = null
			_sub_levels = unplayed_parent_scenes
			_sub_levels.push_back(parent_scene)
		else: #we haven't clicked the parent
			if starting_scene: #still looking for it! (might have clicked for a child)
				unplayed_parent_scenes.push_back(level_set.parent_level)
			else: #already found so we just play it normally
				_sub_levels.push_back(level_set.parent_level)

	for sub in level_set.sub_levels:
		if sub is PackedScene:
			if starting_scene: #still looking for it!
				if sub == starting_scene: #found!
					starting_scene = null
					_sub_levels = unplayed_parent_scenes
					_sub_levels.push_back(sub)
				else: #keep looking
					continue
			else:
				_sub_levels.push_back(sub)
		elif sub is LevelSet:
			starting_scene = _add_sub_set_recursive(sub, starting_scene, main_scene, unplayed_parent_scenes)

	if parent_scene && starting_scene: #added parent scene as unplayed_parent... but then we didn't find a child as starting_scene, so we remove the parent.
		if starting_scene: #still looking for it!
			unplayed_parent_scenes.pop_back()

	return starting_scene

### Forms a grid using stage grid positions
### map value of 0 means no object at that position
### Callback(map_value:int, instantiated_object:Node3D)
func formation_stage_grid(map:Array[Array], scenes:Array[PackedScene], grid_x:float = 0, grid_z:float = 0, level_group:String = "", callback:Callable = Callable()):
	for z in range(map.size()):
		for x in range(map[z].size()):
			var grid_value:int = map[z][x];
			if grid_value != 0:
				var pos:Vector3 = stage.get_grid(grid_x + x, grid_z + z);
				var inst:Node3D = objs.create_object(scenes[grid_value - 1], level_group) as Node3D;
				inst.position = pos;
				if(callback.is_valid()):
					callback.call(grid_value, inst)

### Forms a grid with specific cell sizes centered in 'center'
### rows may differ in size, but will be all centered in the same center.x
### map value of 0 means no object at that position
### Callback(map_value:int, instantiated_object:Node3D)
func formation_grid(map:Array[Array], scenes:Array[PackedScene], center:Vector3, cell_size_x:float, cell_size_z:float, level_group:String = "", callback:Callable = Callable()):
	var row_count = map.size()
	var row_multiplier:float = -((row_count/2.0)-0.5)
	for row_map in map:
		var col_count = row_map.size()
		var col_multiplier:float = -((col_count/2.0)-0.5)
		for map_value in row_map:
			if map_value != 0:
				var pos:Vector3 = center + Vector3(col_multiplier * cell_size_x, 0, row_multiplier * cell_size_z)
				var inst:Node3D = objs.create_object(scenes[map_value - 1], level_group) as Node3D;
				inst.position = pos;
				if(callback.is_valid()):
					callback.call(map_value, inst)
			col_multiplier += 1
		row_multiplier += 1

### Forms an arc or a complete circle of objs at 'radius' distance from 'center'
### map value of 0 means no object at that position
### Callback(map_value:int, instantiated_object:Node3D)
### angle format:
###			270
###	180		c		0 / 360
###			90
func formation_circle(map:Array[int], scenes:Array[PackedScene], center:Vector3, radius:float, arc_start:float=0, arc_end:float=360, level_group:String = "", callback:Callable = Callable()):
	var obj_count = map.size()
	var arc_total = arc_end - arc_start
	var arc_dist = 0.0 if obj_count == 1 else (arc_total / (obj_count if arc_total >= 360 else obj_count-1))
	var arc_val = arc_start
	for map_value in map:
		if map_value != 0:
			var angle = deg_to_rad(arc_val)  # Convert angle to radians
			var pos = center + Vector3(radius * cos(angle), 0, radius * sin(angle))
			var inst:Node3D = objs.create_object(scenes[map_value - 1], level_group) as Node3D;
			inst.position = pos;
			if(callback.is_valid()):
				callback.call(map_value, inst)
		arc_val += arc_dist

func cmd(c:CMD, front:bool = true):
	if front:
		_cmds.push_front(c)
	else:
		_cmds.push_back(c)

func cmd_func(callable:Callable, front:bool = true):
	# Dont do this delay thing here because it makes writing it more confusing. Wait better to just manually make cmd(CMD_Seconds.new(delay)) before
	#if delay > 0:
		#cmd(CMD_Wait_Seconds.new(delay), front);
	cmd(CMD_Callable.new(callable), front)

func cmd_array(cmds:Array[CMD], front:bool = true):
	if cmds == null or cmds.size() <= 0: return

	if front:
		_cmds = cmds + _cmds
	else:
		_cmds = _cmds + cmds

func _level_cmd_CURRENT_TEXT() -> String:
	var text:String = "LEVEL ("+name+"): "
	text += "\n== Current =="
	text += "\n-> " + _current_cmd._get_text(3) if _current_cmd else "null"
	return text

func _level_cmd_NEXT_TEXT() -> String:
	var text:String = "LEVEL ("+name+"): "
	text += "\n== Next ====="
	for c in _cmds:
		text += "\n"
		text += c._get_text(0)
	return text

func _process(delta):
	if !_level_ready: return
	if is_instance_valid(Game.instance) && Game.instance._game_finished: return

	if DevManager.get_shortcut_just_pressed(DevManager.ShortcutCommand.FinishLevel):
		set_level_finished()
		return

	#_current is null if it's the first time running
	while _current_cmd == null or _current_cmd._cmd_process(delta):
		delta = 0 #new commands will be processed for the first time with delta time 0

		#gets next cmd
		_current_cmd = _cmds.pop_front()
		if _current_cmd != null:
			_current_cmd._prepare()
		elif _cmds.size() <= 0: #if there's nothing more in the array, play sub levels
			if _current_sub_level: # playing a sub level
				if _current_sub_level._level_finished: # sub level finished
					_current_sub_level.queue_free()
					_current_sub_level = null
				else:
					return #let it play

			while _current_sub_level == null: # search for the next sub level
				_current_sub_level_id += 1
				if _current_sub_level_id >= _sub_levels.size():
					break # no more sub levels!
				var level_scene:PackedScene = _sub_levels[_current_sub_level_id]
				if level_scene == null:
					continue # no valid level, continue!
				var level_obj = level_scene.instantiate()
				if level_obj is Level:
					_current_sub_level = level_obj
					add_child(level_obj)
					_current_sub_level.play_sublevel(self)
					break # valid level found!
				else:
					level_obj.queue_free()
					continue # no valid level, continue!

			if _current_sub_level == null: # no new sub level, level finished!
				set_level_finished()
			return

#region Utils
func cmd_camera_go_to_pivot0(duration:float = 2, wait:bool = false, grid_offset:Vector2 = Vector2.ZERO,
		trans:Tween.TransitionType = Tween.TRANS_SINE, ease_type:Tween.EaseType = Tween.EASE_IN_OUT)->CMD:
	var arr:Array[CMD] = [];
	arr.push_back(CMD_Callable.new(func():
		var pos:Vector3 = stage.get_grid(grid_offset.x, grid_offset.y);
		cam.tween_position_vector(pos, duration, trans, ease_type);
		));
	if wait:
		arr.push_back(CMD_Wait_Seconds.new(duration));
	return CMD_Sequence.new(arr);

static var copter_groups:int = 0
func make_copters(copter_scene:PackedScene, amount:int, line:ChildLine3D, group:String = "", as_value:bool = true, distance_between:float = 1.5, callable:Callable = Callable(), score_group_id:StringName = ""):
	var copter:Node3D;
	var origin:float = 0;

	copter_groups += 1
	score_group_id = "coptrs_lvl_"+str(copter_groups)
	var score_group:ScoreManager.ScoreGroup
	if !score_group_id.is_empty():
		score_group = ScoreManager.instance.get_score_group(score_group_id, ScoreManager.SCORE_INFO_GROUP_COPTER)

	while(amount > 0):
		copter = objs.create_object(copter_scene, group, line.position);
		copter.position = line.get_position_in_line(0);
		copter.set_line(line, as_value);
		copter.offsetLinePosition = origin;
		if callable:
			callable.call(copter);
		origin -= distance_between;
		amount -= 1;
		if score_group:
			score_group.add_obj_with_giver_inside(copter)
	if score_group:
		score_group.set_group_ready()


func make_instant_enemy_line(scn:Array[PackedScene], enemies, x:float, z:float, distance_between:Vector2 = Vector2.UP, group:String = "", funcEach:Callable = Callable()):
	var offset:Vector3 = Vector3();
	var walk:Vector3 = Vector3(distance_between.x, 0, distance_between.y);
	for enemy in enemies:
		if enemy >= 0:
			var enemyBot := objs.create_object(scn[enemy], group, stage.get_grid(x,z) + offset);
			if funcEach:
				funcEach.call(enemyBot);
		offset += walk;

func make_enemy_line_in_cmd(scn:Array[PackedScene], enemies:Array[int], time_between:float, x:int = 0, z:int = 0, distance_between:Vector2 = Vector2(), group:String = "", funcEach:Callable = Callable(), funcAfter:Callable = Callable()):
	var offset:Vector3 = Vector3();
	var walk:Vector3 = Vector3(distance_between.x, 0, distance_between.y);
	for enemy in enemies:
		if enemy >= 0:
			cmd(CMD_Callable.new(func():
					var enemyBot := objs.create_object(scn[enemy], group, stage.get_grid(x,z) + offset);
					if funcEach:
						funcEach.call(enemyBot);
					)
				);
		if time_between > 0:
			cmd(CMD_Wait_Seconds.new(time_between))
		offset += walk;
	if funcAfter:
		cmd_func(funcAfter);

func cmd_enemy_line_dynamic_enemies(scn:Array[PackedScene], enemies_int_array_func:Callable, time_between:float, x:float = 0, z:float = 0, distance_between:Vector2 = Vector2(), group:String = "", funcEach:Callable = Callable(), funcAfter:Callable = Callable())->CMD:
	var offset:Vector3 = Vector3();
	var walk:Vector3 = Vector3(distance_between.x, 0, distance_between.y);
	var cmd_arr:Array[CMD] = [];
	for enemy:int in enemies_int_array_func.call():
		if enemy >= 0:
			cmd_arr.push_back(CMD_Callable.new(func():
				var enemyBot := objs.create_object(scn[enemy], group, stage.get_grid(x,z) + offset);
				if funcEach:
					funcEach.call(enemyBot);
				));
		if time_between > 0:
			cmd_arr.push_back(CMD_Wait_Seconds.new(time_between))
		offset += walk;
	if funcAfter:
		cmd_arr.push_back(CMD_Callable.new(funcAfter));
	return Level.CMD_Sequence.new(cmd_arr);


func cmd_enemy_line(scn:Array[PackedScene], enemies:Array[int], time_between:float, x:float = 0, z:float = 0, distance_between:Vector2 = Vector2(), group:String = "", funcEach:Callable = Callable(), funcAfter:Callable = Callable())->CMD:
	return cmd_enemy_line_dynamic_enemies(scn, func(): return enemies, time_between, x, z, distance_between, group, funcEach, funcAfter);

func cmd_enemy_segment_ab(enemies:Array[PackedScene], a_grid:Vector2, b_grid:Vector2, group:String = "", callable:Callable = Callable())->CMD:
	return CMD_Callable.new(func():
		var a:Vector3 = stage.get_grid(a_grid.x, a_grid.y);
		var b:Vector3 = stage.get_grid(b_grid.x, b_grid.y);
		var segment := b - a;
		var n:int = enemies.size();
		if n > 1:
			var now:Vector3 = a;
			var semi_segment:Vector3 = segment / (n - 1);
			for enemy in enemies:
				var instance = objs.create_object(enemy, group, now);
				if callable and callable.is_valid():
					callable.call(instance);
				now += semi_segment;
		else:
			var instance = objs.create_object(enemies[0], group, (a + b) * 0.5);
			if callable and callable.is_valid():
				callable.call(instance);
		)


func sequence_make_enemy_line(scn:Array[PackedScene], enemies:Array[int], time_between:float, x:int = 0, z:int = 0, distance_between:Vector2 = Vector2(), group:String = "", funcEach:Callable = Callable(), funcAfter:Callable = Callable())->Array[CMD]:
	var arr:Array[CMD];
	var offset:Vector3 = Vector3();
	for enemy in enemies:
		if enemy >= 0:
			arr.push_back(CMD_Callable.new(func():
				var enemyBot := objs.create_object(scn[enemy], group);
				enemyBot.position = stage.get_grid(x,z) + offset;
				if funcEach:
					funcEach.call(enemyBot);
				));
		if time_between > 0:
			arr.push_back(CMD_Wait_Seconds.new(time_between));
		offset += Vector3(distance_between.x, 0, distance_between.y);
	if funcAfter:
		arr.push_back(CMD_Callable.new(funcAfter.bind()));
	return arr;
#endregion

#region Measures
const measure_group:StringName = &"measure";
var current_measure_index:int = 0;

func get_measures()->Array[Node]:
	return get_tree().get_nodes_in_group(measure_group);

func get_stage_measure(index:int)->StageMeasure:
	return get_measures()[index] as StageMeasure;

func get_current_measure(offset_measure:int = 0)->Node3D:
	var n:int = get_amount_of_measures();
	if n > 0:
		return get_stage_measure((current_measure_index + offset_measure) % n);
	else:
		push_error("No measures in %s but trying to get one anyway." % self);
		return stage._reference_piece;

func get_current_stage_measure(offset_measure:int = 0)->StageMeasure:
	return get_current_measure(offset_measure) as StageMeasure;

func set_current_measure(index:int)->void:
	current_measure_index = index;

func get_amount_of_measures()->int:
	return get_tree().get_node_count_in_group(measure_group);

func get_rest_of_measures()->int:
	return get_amount_of_measures() - 1 - (mini(current_measure_index, 0) % get_amount_of_measures());

func walk_measure(walk:int = 1)->void:
	set_current_measure(current_measure_index + walk);

func get_next_measure(walk:int = 1)->Node3D:
	walk_measure(walk);
	return get_current_measure();

func clear_measures(also_reset_index:bool = true)->void:
	for measure in get_measures():
		measure.queue_free();
	if also_reset_index:
		current_measure_index = 0;

func cmd_clear_measures(also_reset_index:bool = true)->CMD:
	return CMD_Sequence.new([
		CMD_Print_Log.new("level: clearing measures! **"),
		CMD_Callable.new(clear_measures.bind(also_reset_index)),
	])

func cmd_set_pivot_to_next_measure(walk:int = 1)->CMD:
	return CMD_Sequence.new([
		CMD_Callable.new(func():
			var measure := get_next_measure(walk);
			print("[LEVEL] next measure is %s -> %s and position is %s" % [current_measure_index, measure, measure.global_position]);
			stage.set_pivot_offset_to_exactly_node(measure)
			)
	]);

func cmd_set_pivot_to_offset_measure(offset:int = 1)->CMD:
	return CMD_Sequence.new([
		CMD_Callable.new(func():
			var measure := get_current_measure(offset);
			print("[LEVEL] next measure is %s -> %s and position is %s" % [current_measure_index, measure, measure.global_position]);
			stage.set_pivot_offset_to_exactly_node(measure)
			)
	]);

func cmd_go_to_current_measure_using_its_data(offset:int = 0, wait_multiplier:float = 0.0, fixed_duration:float = -1, set_pivot:bool = true):
	return get_stage_measure(offset).cmd_default_camera_tween(self, wait_multiplier, fixed_duration, set_pivot);
#endregion
