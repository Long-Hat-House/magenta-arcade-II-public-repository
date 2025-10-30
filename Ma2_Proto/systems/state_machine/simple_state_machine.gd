class_name SimpleStateMachine extends Node

@export var check_every_physics_frame:bool;
@export var leave_from_going:bool = true;
@export var debug:bool;

class State:
	var id:StringName
	var transition:Callable
	var leave_transition:Callable
	var priority:int;
	var condition:Callable;
	var state_process:Callable;
	var state_physics_process:Callable;
	
	func _to_string() -> String:
		return "<state:'%s'>" % [id]
	
var states:Array[State] = [];

var _state_now:State;
var _state_going:State;

var _call_id:int;

var _last_priority:int = 0;
var _forced_state:StringName;

signal state_changed;
signal state_change(id:StringName);

func add_transition_state(id:StringName, transition:Callable, leave:Callable = Callable()):
	var state = State.new();
	state.id = id;
	state.condition = func(): return false;
	state.priority = _last_priority;
	state.transition = transition;
	state.leave_transition = leave;
	_last_priority += 1;
	
	states.push_back(state);

func add_state(id:StringName, condition_bool:Callable, transition_await:Callable, transition_leave_await:Callable, process:Callable = Callable(), process_physics:Callable = Callable()):
	var state = State.new();
	state.id = id;
	state.condition = condition_bool;
	state.priority = _last_priority;
	state.transition = transition_await;
	state.leave_transition = transition_leave_await;
	state.state_process = process;
	state.state_physics_process = process_physics;
	_last_priority += 1;
	
	states.push_back(state);

func add_state_simplest(id:StringName, condition_bool:Callable, transition_await:Callable, transition_leave_await:Callable = Callable()):
	add_state(id, condition_bool, transition_await, transition_leave_await);

func add_state_physics(id:StringName, condition_bool:Callable, transition_await:Callable, transition_leave_await:Callable, process_physics:Callable = Callable()):
	add_state(id, condition_bool, transition_await, transition_leave_await, Callable(), process_physics);

func get_current_state()->State:
	var curr:State = null;
	for state in states:
		if state.condition and state.condition.is_valid() and state.condition.call():
			return state;
		curr = state;
	return curr;
	
func check_current_state()->void:
	var state_should := get_current_state();
	#if debug:
		#print("[SIMPLE STATE MACHINE] Checked state '%s'" % state_should);
	if _state_now != state_should:
		_set_state(state_should);

func do_state(id:StringName):
	var index:int = states.find_custom(func(x:State): return x.id == id);
	if index >= 0:
		if debug:
			print("[SIMPLE STATE MACHINE] Forcing state '%s' [%s]" % [states[index], Engine.get_physics_frames()]);
		_forced_state = id;
		_set_state(states[index]);
	else:
		if debug:
			print("[SIMPLE STATE MACHINE] Couldnt find state '%s' (%s)" % [id, states]);
	

func _set_state(state:State):
	if state == _state_going or state == _state_now:
		return;
	if !_forced_state.is_empty() and _forced_state != state.id:
		return;
	_call_id += 1;
	var id:int = _call_id;
	if debug:
		print("[SIMPLE STATE MACHINE] Changing state from %s (was going %s) to %s NEW CALL:%s [%s]" % [_state_now, _state_going, state, id, Engine.get_physics_frames()]);
	if _state_going and _state_going.leave_transition.is_valid():
		_state_going.leave_transition.call();
		if debug:
			print("[SIMPLE STATE MACHINE] Canceled state '%s' (%s)  call:%s [%s]" % [_state_going, id == _call_id, id, Engine.get_physics_frames()]);
	
	if state:
		_state_going = state;
		
		if _state_now != null and _state_now.leave_transition.is_valid():
			if debug:
				print("[SIMPLE STATE MACHINE] Leaving state '%s' call:%s [%s]" % [_state_now, id, Engine.get_physics_frames()]);
			await _state_now.leave_transition.call()
			if debug:
				print("[SIMPLE STATE MACHINE] Left state '%s' (%s)  call:%s [%s]" % [_state_now, id == _call_id, id, Engine.get_physics_frames()]);
			if id != _call_id:
				return;
				
		_state_now = null;
		
		if state.transition.is_valid():
			if debug:
				print("[SIMPLE STATE MACHINE] Entering '%s'  call:%s [%s]" % [state, id, Engine.get_physics_frames()]);
			await state.transition.call();
			if debug:
				print("[SIMPLE STATE MACHINE] Entered state '%s' (%s)  call:%s [%s]" % [state, id == _call_id, id, Engine.get_physics_frames()]);
			if id != _call_id:
				return;
				
		_state_going = null;
		_state_now = state;
		_forced_state = &"";
		state_change.emit(state);
				
	else:
		_state_going = null;
		_state_now = null;
	
	if debug:
		print("[SIMPLE STATE MACHINE] In state '%s'  call:%s [%s]" % [_state_now, id, Engine.get_physics_frames()]);
	
	state_changed.emit();
	
func _process(delta: float) -> void:
	if _state_now and _state_now.state_process.is_valid():
		_state_now.state_process.call(delta);
		
func _physics_process(delta: float) -> void:
	if check_every_physics_frame:
		check_current_state();
	
	if _state_now and _state_now.state_physics_process.is_valid():
		_state_now.state_physics_process.call(delta);
