extends Control

@export var text_label:Label

func _enter_tree() -> void:
	visible = Ma2MetaManager.get_unused_stars_count() && Ma2MetaManager.get_allocated_total_stars() == 0
