class_name PlayerWeapon  extends Node

enum WeaponType
{
	HOLD,
	TAP,
}

enum WeaponID
{
	BLUE,
	YELLOW,
	RED,
	GREEN,
	PURPLE,
	PINK,
	BLACK,
	WHITE,
	TOUCH_ONLY,
};

@export var icon:Texture;
@export var title:String;
@export var id:WeaponID;
@export var type:WeaponType;
@export var color:Color;
@export var color_highlight:Color;

func _get_max_level() -> int:
	return 1
