class_name Graphic_Powerup_Button extends HoldableButtonGraphic

enum Style{
	RoundCornersOut,
	RoundcornersIn,
	Octagon,
}

@export var _task_add_weapon:Task_AddWeapon

@export_category("Default Powerup Style")
@export var default_style:Style = Style.Octagon
@export var default_icon:Texture2D
@export var default_color:Color = MA2Colors.BLACK
@export var default_color_highlight:Color = MA2Colors.BUTTON_ICON
@export var powerup_style:Powerup_Graphic_Info;

@export_group("Config")
@export var _hold_mesh_container:Node3D
@export var _tap_mesh_container:Node3D
@export var _other_mesh_container:Node3D

@export var _label:MeshInstance3D;

func set_style(type:Style):
	match type:
		Style.RoundCornersOut:
			_mesh_container = _hold_mesh_container
		Style.RoundcornersIn:
			_mesh_container = _tap_mesh_container
		Style.Octagon:
			_mesh_container = _other_mesh_container

	_hold_mesh_container.visible = _hold_mesh_container == _mesh_container
	_tap_mesh_container.visible = _tap_mesh_container == _mesh_container
	_other_mesh_container.visible = _other_mesh_container == _mesh_container

func _ready():
	var wpn:PlayerWeapon

	if _task_add_weapon:
		wpn = _task_add_weapon.get_weapon()

	if wpn != null:
		set_icon(wpn.icon, wpn.color_highlight)

		if wpn.type == PlayerWeapon.WeaponType.HOLD:
			set_style(Style.RoundCornersOut)

		elif wpn.type == PlayerWeapon.WeaponType.TAP:
			set_style(Style.RoundcornersIn)

		set_colors(wpn.color, wpn.color_highlight)

	elif powerup_style != null:

		set_style(powerup_style.get_button_style());
		set_icon(powerup_style.get_icon(), powerup_style.get_icon_color())
		set_colors(powerup_style.get_normal_color(), powerup_style.get_highlight_color())

	else:
		set_style(default_style)
		set_icon(default_icon, default_color_highlight)
		set_colors(default_color, default_color_highlight)

func set_full_graphic(is_full:bool):
	_label.visible = is_full;
