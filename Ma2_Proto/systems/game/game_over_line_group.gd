class_name GameOverLineGroup extends VBoxContainer

var group_icon:Texture2D

func _enter_tree() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alignment = ALIGNMENT_CENTER
	modulate = Color.TRANSPARENT

func show_group():
	modulate = Color.WHITE

func hide_group():
	modulate = Color.TRANSPARENT
