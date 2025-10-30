extends Node

class TimeDeltaChange:
	var id:StringName;
	var time_multiplier:float;

	signal changed;

	func _init(id:StringName, time_mult:float) -> void:
		self.id = id;
		self.time_multiplier = time_mult;

	func change_time_delta(time_mult:float) -> void:
		self.time_multiplier = time_mult;
		changed.emit();

var changes:Dictionary[TimeDeltaChange, bool] = {}
var _control_requesters:Dictionary = {}

@export var _time_control_on_off_anim:Switch_Oning_Offing_AnimationPlayer

var _game_paused:bool = false

func set_game_paused():
	_game_paused = true
	calculate_time_delta()

func set_game_unpaused():
	_game_paused = false
	calculate_time_delta()

func calculate_time_delta():
	if _game_paused:
		Engine.time_scale = 1
		return

	var scale:float = 1.0;
	var min:float = 1.0;
	var max:float = 1.0;
	for change in changes:
		scale *= change.time_multiplier;
		min = minf(change.time_multiplier, min);
		max = maxf(change.time_multiplier, max);
	Engine.time_scale = clampf(scale, min, max);
	#print("[TIME MANAGER] Updated time scale: %s [%s %s]" % [str(Engine.time_scale), Engine.get_frames_drawn(), Engine.get_physics_frames()])

func _add_tc(tc:TimeDeltaChange):
	if changes.has(tc): return
	tc.changed.connect(calculate_time_delta)
	changes[tc] = true

func _erase_tc(tc:TimeDeltaChange):
	if !changes.has(tc): return
	tc.changed.disconnect(calculate_time_delta)
	changes.erase(tc)

func frame_freeze(duration:float, time_multiplier:float = 0.05, wait_frames_before:int = 0):
	var tree := get_tree();

	while wait_frames_before > 0:
		await tree.process_frame;
		if not is_instance_valid(self): return;
		wait_frames_before -= 1;

	var tchange:TimeDeltaChange = TimeDeltaChange.new(&"ff", time_multiplier);

	_add_tc(tchange);
	calculate_time_delta();
	await tree.create_timer(duration, false, false, true).timeout;
	if not is_instance_valid(self): return;
	_erase_tc(tchange);
	calculate_time_delta();

func add_time_change(id:StringName)->TimeDeltaChange:
	var tc:TimeDeltaChange = TimeDeltaChange.new(id, 1.0);
	_add_tc(tc);
	calculate_time_delta();
	return tc;

func readd_time_change(tc:TimeDeltaChange):
	_add_tc(tc)
	calculate_time_delta();

func remove_time_change(tc:TimeDeltaChange)->void:
	_erase_tc(tc);
	calculate_time_delta();

func add_control_requester(requester):
	_control_requesters[requester] = true;
	_time_control_on_off_anim.set_switch(_control_requesters.size() > 0)

func remove_control_requester(requester):
	_control_requesters.erase(requester)
	_time_control_on_off_anim.set_switch(_control_requesters.size() > 0)

func remove_all_time_changes():
	for change in changes:
		change.changed.disconnect(calculate_time_delta)
	changes.clear()
	calculate_time_delta()
