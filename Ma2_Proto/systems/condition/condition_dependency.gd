class_name ConditionDependency extends Node

@export var _condition:Condition

@export var _node3d_to_set_visibility_and_process:Array[Node3D]
@export var _node_to_set_process:Array[Node]
@export var _to_set_animation:Array[Switch_Oning_Offing_AnimationPlayer]

func _enter_tree() -> void:
	_condition.condition_changed_set.connect(_on_condition_changed)
	_on_condition_changed(_condition.is_condition(), true)

func _on_condition_changed(val:bool, init:bool = false):
	for n in _node3d_to_set_visibility_and_process:
		n.visible = val
		n.process_mode = Node.PROCESS_MODE_INHERIT if val else Node.PROCESS_MODE_DISABLED
	for n in _node_to_set_process:
		n.process_mode = Node.PROCESS_MODE_INHERIT if val else Node.PROCESS_MODE_DISABLED
	for n in _to_set_animation:
		if init:
			n.set_switch_immediate(val)
		else:
			n.set_switch(val)
