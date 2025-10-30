class_name Condition extends Node

signal condition_changed_set(to_what:bool);
signal condition_changed;

func is_condition()-> bool:
	return true;

func _call_condition_changed(new_condition:bool):
	condition_changed.emit();
	condition_changed_set.emit(new_condition);
