class_name LevelSelectionMenu extends Control

signal lvl_selected
@export var levels:Array[LevelInfo]

@export var viewers_top_parent:Control

func _enter_tree():
	for child in viewers_top_parent.get_children():
		child.queue_free()

	for entry in levels:
		var lvl_set
		var lvl_res = load(entry.lvl_resource_path)

		if lvl_res is LevelSet:
			lvl_set = lvl_res
		elif lvl_res is PackedScene:
			lvl_set = LevelSet.new()
			lvl_set.parent_level = lvl_res

		var panel:PanelContainer = PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.theme_type_variation = "panelcontainer_sub1"

		_add_level_set(panel, lvl_set, entry)

		viewers_top_parent.add_child(panel)

func _add_level_set(parent:Control, current_set:LevelSet, level_info:LevelInfo):
	var vbox:VBoxContainer = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(vbox)

	var header:HBoxContainer = HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(header)


	var parent_button:Button = Button.new()
	parent_button.mouse_filter = Control.MOUSE_FILTER_PASS
	parent_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(parent_button)
	if !current_set:
		parent_button.text = "Problem in " + _get_resource_name(level_info)
		parent_button.disabled = true
	elif current_set.parent_level:
		parent_button.text = _get_resource_name(current_set.parent_level)
		parent_button.pressed.connect(
			func():
				lvl_selected.emit()
				LevelManager.change_level_by_info(level_info, current_set.parent_level)
				)
	else:
		parent_button.text = _get_resource_name(current_set)
		parent_button.disabled = true

	if current_set && current_set.sub_levels.size() > 0:
		var toggle:CheckButton = CheckButton.new()
		toggle.mouse_filter = Control.MOUSE_FILTER_PASS
		header.add_child(toggle)

		var content:HBoxContainer = HBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(content)
		content.hide()

		toggle.toggled.connect(func(val): content.visible = val)

		var child_items:VBoxContainer = VBoxContainer.new()
		child_items.mouse_filter = Control.MOUSE_FILTER_IGNORE
		child_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(child_items)

		var sep = ColorRect.new()
		sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sep.color = MA2Colors.GREENISH_BLUE
		sep.custom_minimum_size = Vector2(20,0)
		content.add_child(sep)

		for item in current_set.sub_levels:
			if item is LevelSet:
				_add_level_set(child_items, item, level_info)
			elif item is PackedScene:
				var button:Button = Button.new()
				button.mouse_filter = Control.MOUSE_FILTER_PASS
				button.pressed.connect(
					func():
						lvl_selected.emit()
						LevelManager.change_level_by_info(level_info, item)
						)
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				button.text = _get_resource_name(item)
				child_items.add_child(button)

func _get_resource_name(src:Resource) -> String:
	var split = src.resource_path.rsplit("/",false,1)
	if split.size() > 1:
		return split[1]
	if split.size() == 1:
		return split[0]
	return src.resource_path
