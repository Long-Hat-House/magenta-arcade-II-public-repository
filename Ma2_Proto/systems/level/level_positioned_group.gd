class_name PositionedLevelGroup extends Node3D

@export var group:String = "main"

func _ready() -> void:
	var level:Level;
	var parent := self as Node;
	await get_tree().create_timer(0.1).timeout; #After pieces get positioned
	while level == null and parent != null:
		level = parent as Level;
		parent = parent.get_parent();
	for child in get_children():
		level.objs.add_to_group_node(child, group);
