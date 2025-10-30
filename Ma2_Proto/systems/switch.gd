class_name Switch extends Node

signal change(change:bool);

enum State
{
	UNDEFINED,
	ON,
	OFF,
}

var currentState:State = State.UNDEFINED;

func get_corresponding_state(set:bool) -> State:
	return State.ON if set else State.OFF;


func set_switch(set:bool) -> void:
	print("switch abstract set %s as %s" % [self, set]);
	var inputState:State = get_corresponding_state(set);
	if currentState != inputState:
		_set_switch(set);
		currentState = inputState;
		change.emit(set);


func _set_switch(set:bool) -> void:
	pass
