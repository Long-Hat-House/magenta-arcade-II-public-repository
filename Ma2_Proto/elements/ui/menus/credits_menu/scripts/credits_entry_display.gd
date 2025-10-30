class_name CreditsEntryDisplay extends Control

@export var entry_name:Label
@export var entry_role:Label
@export var entry_information:Label
@export var entry_texture:TextureRect
@export var entry_texture_2:TextureRect
@export var to_set_color_highlight:Array[Control]
@export var to_set_color_bg:Array[Control]

func set_entry_info(info:CreditsEntryInfo, section:CreditsSectionInfo):
	_set_label(entry_name, info.entry_name)
	_set_label(entry_role, info.entry_role)
	_set_label(entry_information, info.entry_information)
	if(entry_texture):
		entry_texture.texture = info.entry_texture
		entry_texture.visible = true if info.entry_texture else false
	if(entry_texture_2):
		entry_texture_2.texture = info.entry_texture_2 if info.entry_texture_2 else section.default_entry_texture_2
		entry_texture_2.visible = true if entry_texture_2.texture else false

	for c in to_set_color_bg:
		c.self_modulate = info.entry_color_bg
	for c in to_set_color_highlight:
		c.self_modulate = info.entry_color_highlight

func _set_label(label:Label, text:StringName):
	if label:
		label.text = text
		label.visible = !label.text.is_empty()
