class_name StarInfoDisplay extends Control

const ICON_STAR = preload("res://elements/icons/icon_star.png")
const ICON_STAR_EMPTY = preload("res://elements/icons/icon_star_empty.png")

@export var label_text:Label
@export var label_text_type_variation_normal:String
@export var label_text_type_variation_unlocked:String

@export var texture_rect_star_icon:TextureRect

func set_star(info:StarInfo, lvl_context:LevelInfo = null, text:String = ""):
	if info == null:
		visible = false
		return

	visible = true
	if label_text:
		if info.is_unlocked():
			label_text.theme_type_variation = label_text_type_variation_unlocked
		else:
			label_text.theme_type_variation = label_text_type_variation_normal

	label_text.text = info.get_instruction(lvl_context)

	if texture_rect_star_icon:
		if info.is_unlocked():
			texture_rect_star_icon.texture = ICON_STAR
		else:
			texture_rect_star_icon.texture = ICON_STAR_EMPTY
