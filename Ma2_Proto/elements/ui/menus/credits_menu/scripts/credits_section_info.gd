@tool
class_name CreditsSectionInfo extends Resource

@export var section_title:StringName
@export var section_info:StringName
@export var section_image:Texture2D
@export var default_entry_texture_2:Texture2D

@export var section_color_highlight:Color = Color.WHITE
@export var section_color_bg:Color = MA2Colors.GREENISH_BLUE

@export var entries_list:Array[CreditsEntryInfo]
