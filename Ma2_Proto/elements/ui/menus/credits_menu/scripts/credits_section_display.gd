class_name CreditsSectionDisplay extends Control

@export var section_title:Label
@export var section_information:Label
@export var section_image:TextureRect
@export var section_entry_container:Control

@export var scene_section_entry:PackedScene

@export var to_set_color_highlight:Array[Control]
@export var to_set_color_bg:Array[Control]

var _entry_displays:Array[CreditsEntryDisplay]

func set_section_info(info:CreditsSectionInfo):
	for c in to_set_color_bg:
		c.self_modulate = info.section_color_bg
	for c in to_set_color_highlight:
		c.self_modulate = info.section_color_highlight

	_set_label(section_title, info.section_title)
	_set_label(section_information, info.section_info)

	if section_image:
		section_image.texture = info.section_image
		section_image.visible = true if section_image.texture else false

	_entry_displays.clear()
	for child in section_entry_container.get_children():
		if child is CreditsEntryDisplay:
			_entry_displays.append(child)

	while _entry_displays.size() > info.entries_list.size():
		var disp:CreditsEntryDisplay = _entry_displays.pop_back()
		disp.queue_free()

	while _entry_displays.size() < info.entries_list.size():
		var disp:CreditsEntryDisplay = scene_section_entry.instantiate()
		_entry_displays.append(disp)
		section_entry_container.add_child(disp)

	for i in range(0, info.entries_list.size()):
		_entry_displays[i].set_entry_info(info.entries_list[i], info)

func _set_label(label:Label, text:StringName):
	if label:
		label.text = text
		label.visible = !label.text.is_empty()
