class_name CreditsMenu extends Control

@export var _credits_info:CreditsInfo
@export var _sections_container:Control

@export_category("Visual Settings")
@export var _scene_credits_section:PackedScene

var _section_displays:Array[CreditsSectionDisplay]

func _ready() -> void:
	_section_displays.clear()
	for child in _sections_container.get_children():
		if child is CreditsSectionDisplay:
			_section_displays.append(child)

	if _credits_info != null:

		while _section_displays.size() > _credits_info.sections_list.size():
			var disp:CreditsSectionDisplay = _section_displays.pop_back()
			disp.queue_free()

		while _section_displays.size() < _credits_info.sections_list.size():
			var disp:CreditsSectionDisplay = _scene_credits_section.instantiate()
			_section_displays.append(disp)
			_sections_container.add_child(disp)

		for i in range(0, _credits_info.sections_list.size()):
			_section_displays[i].set_section_info(_credits_info.sections_list[i])
