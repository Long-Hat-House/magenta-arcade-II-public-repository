class_name Level_Snippet_Goto_Specific_Measure extends Level_Snippet_Node

@export var get_measure_from_index:int = -1;
@export var measure:StageMeasure;
@export var wait_multiplier:float = 1.0;
@export var fixed_duration:float = -1;
@export var set_pivot:bool = true;

var _used_measure:StageMeasure;

func cmd(level:Level)->Level.CMD:
	return Level.CMD_Sequence.new([
		go(level),
		super.cmd(level)
	])
	
func go(level:Level)->Level.CMD:
	return Level.CMD_Await_AsyncCallable.new(func():
		if measure != null:
			self._used_measure = measure;
		if get_measure_from_index >= 0:
			self._used_measure = level.get_stage_measure(get_measure_from_index);
		await self._used_measure.do_camera_tween(level, wait_multiplier, fixed_duration, set_pivot);
		, self)
