class_name TextFlowZapSpeaker extends Resource

@export var id:String
@export var color:Color
@export var icon_1:Texture
@export var icon_2:Texture

var name:String:
	get:
		return "zap_char_"+id+"_name"

var description:String:
	get:
		return "zap_char_"+id+"_text"
