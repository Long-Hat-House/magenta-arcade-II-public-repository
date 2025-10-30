class_name Powerup_Sign extends LHH3D

@export var powerup_graphic_info:Powerup_Graphic_Info;
@export var powerup_on_ready:PlayerWeapon;
@export var powerup_scene:PackedScene;

@export var unpower_up_icon:Texture;
@export var highlight_color:Color;
@export var normal_color:Color;

@onready var icon = $Icon
@onready var bg = $BG

func _ready() -> void:
	
	if powerup_graphic_info:
		setup_graphic_info(powerup_graphic_info);
	else:
		if powerup_scene:
			powerup_on_ready = powerup_scene.instantiate();
			add_child(powerup_on_ready);
		
		if powerup_on_ready:
			setup_powerup(powerup_on_ready);

func setup_powerup(weapon:PlayerWeapon):
	setup(weapon.icon, weapon.color_highlight, weapon.color);
	
func setup_graphic_info(ginfo:Powerup_Graphic_Info):
	setup(ginfo.get_icon(), ginfo.get_icon_color(), ginfo.get_normal_color());
	

func setup(texture:Texture, highlight:Color, main:Color):
	icon.texture = texture;
	icon.modulate = highlight;
	bg.modulate = main;
	
