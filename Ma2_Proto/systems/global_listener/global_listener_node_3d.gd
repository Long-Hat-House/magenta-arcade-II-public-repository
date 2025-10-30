class_name GlobalListenerNode3D extends Node3D

signal var_changed_bool(value:bool)
signal var_changed_variant(value:Variant)

@export var var_id:StringName

func _enter_tree() -> void:
	GlobalListener.add_callable(var_id, _var_changed)
	
	if GlobalListener.has_var(var_id):
		_var_changed(GlobalListener.get_var(var_id))

func _exit_tree() -> void:
	GlobalListener.remove_callable(var_id, _var_changed)

func _var_changed(value:Variant) -> void:
	var_changed_bool.emit(value)
	var_changed_variant.emit(value)

func set_var(value:Variant) -> void:
	GlobalListener.set_var(var_id, value)
