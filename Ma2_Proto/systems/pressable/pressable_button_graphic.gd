class_name PressableButtonGraphic extends LHH3D

signal graphic_turned_on
signal graphic_turned_off

var icon:Texture2D: set = set_icon, get = get_icon
var icon_color:Color: set = set_icon_color, get = get_icon_color
var button_color:Color: set = set_button_color, get = get_button_color
var button_highlight_color:Color: set = set_button_highlight_color, get = get_button_highlight_color

@export_group("Config")
@export var _icon_mesh:MeshInstance3D
@export var _button_mesh:MeshInstance3D;
@export var _area_3d:Area3D
@export var _on_off_animation_player:Switch_Oning_Offing_AnimationPlayer

func get_area_3d() -> Area3D:
	return _area_3d

func set_icon(icon_texture:Texture2D):
	if _icon_mesh == null:
		return;
		
	if icon_texture:
		_icon_mesh.visible = true
	else:
		_icon_mesh.visible = false

	var mat:StandardMaterial3D = _get_material(_icon_mesh)
	if mat:
		mat.albedo_texture = icon_texture

func get_icon() -> Texture2D:
	var mat:StandardMaterial3D = _get_material(_icon_mesh)
	if mat:
		return mat.albedo_texture
	return null

func set_icon_color(icon_color:Color = Color.WHITE):
	var mat:StandardMaterial3D = _get_material(_icon_mesh)
	if mat:
		mat.albedo_color = icon_color

func get_icon_color() -> Color:
	var mat:StandardMaterial3D = _get_material(_icon_mesh)
	if mat:
		return mat.albedo_color
	return Color.BLACK

func set_button_color(color:Color):
	var mat:StandardMaterial3D = _get_material(_button_mesh)
	if mat:
		mat.albedo_color = color

func get_button_color() -> Color:
	var mat:StandardMaterial3D = _get_material(_button_mesh)
	if mat:
		return mat.albedo_color
	return Color.BLACK


func set_button_highlight_color(color:Color):
	var mat:StandardMaterial3D = _get_material(_button_mesh)
	if mat:
		var img = Image.create(1,1,false,Image.FORMAT_RGBA8)
		img.set_pixel(0,0,color)
		mat.detail_albedo = ImageTexture.create_from_image(img)

func get_button_highlight_color() -> Color:
	var mat:StandardMaterial3D = _get_material(_button_mesh)
	if mat:
		var detail = mat.detail_albedo
		if detail:
			var img = detail.get_image()
			if img:
				return img.get_pixel(0,0)
	return Color.BLACK

func _get_material(mesh:MeshInstance3D) -> StandardMaterial3D:
	return mesh.material_override if mesh else null

func set_graphic_pressed(pressed:bool):
	_on_off_animation_player.set_switch(pressed)

func _ready() -> void:
	_on_off_animation_player.turned_on.connect(graphic_turned_on.emit)
	_on_off_animation_player.turned_off.connect(graphic_turned_off.emit)
