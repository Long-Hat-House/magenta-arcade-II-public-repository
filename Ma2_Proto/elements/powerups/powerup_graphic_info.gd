class_name Powerup_Graphic_Info extends Resource

@export var icon:Texture;
@export var icon_color_custom:Color = MA2Colors.BUTTON_ICON;
@export var use_color_custom_for_icon:bool;

func get_icon_color()->Color:
	if use_color_custom_for_icon:
		return icon_color_custom;
	else:
		return highlight;

@export var highlight:Color = MA2Colors.GREENISH_BLUE_MEDIUM;
@export var normal:Color = MA2Colors.GREENISH_BLUE_DARK;
@export var button_style:Graphic_Powerup_Button.Style;

func get_icon()->Texture:
	return icon;
	
func get_highlight_color()->Color:
	return highlight;
	
func get_normal_color()->Color:
	return normal;
	
func get_button_style()->Graphic_Powerup_Button.Style:
	return button_style;
