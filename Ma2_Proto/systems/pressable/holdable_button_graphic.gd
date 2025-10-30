class_name HoldableButtonGraphic extends LHH3D

@export_group("Config")
@export var _button_parent:Node3D
@export var _mesh_container:Node3D
@export var _icon_sprite:Sprite3D
@export var _icon_mesh:MeshInstance3D

@export_group("optional")
@export var _material_to_set_colors:StandardMaterial3D

var current_tween:Tween;

func set_icon(icon_texture:Texture2D, icon_color:Color = Color.WHITE):
	if _icon_sprite:
		_icon_sprite.texture = icon_texture
		_icon_sprite.modulate = MA2Colors.BUTTON_ICON #icon_color
	if _icon_mesh:
		var mat = _icon_mesh.material_override
		if mat is StandardMaterial3D:
			mat.albedo_texture = icon_texture
			mat.albedo_color = icon_color

func set_colors(base_color:Color, highlihgt_color:Color):
	if _mesh_container:
		var mat:StandardMaterial3D = _get_button_material(_mesh_container)

		if mat:
			if mat.emission_enabled:
				mat.emission = highlihgt_color
			mat.albedo_color = base_color

			var img = Image.create(1,1,false,Image.FORMAT_RGBA8)
			img.set_pixel(0,0,highlihgt_color)
			mat.detail_albedo = ImageTexture.create_from_image(img)

func _get_button_material(node:Node3D) -> StandardMaterial3D:
	if _material_to_set_colors:
		return _material_to_set_colors

	for child in node.get_children():
		if child is MeshInstance3D:
			if child.material_override:
				return child.material_override
			elif child.get_surface_override_material(0):
				return child.get_surface_override_material(0)
		else:
			for in_child in child.get_children():
				if in_child is MeshInstance3D:
					if in_child.material_override:
						return in_child.material_override
					elif in_child.get_surface_override_material(0):
						return in_child.get_surface_override_material(0)

	return null

func btn_graphic_add_remote_transform(remote_node:Node3D):
	var remote = RemoteTransform3D.new()
	_button_parent.add_child(remote)
	remote.remote_path = remote.get_path_to(remote_node)

func btn_graphic_press():
	_scale_tween(Vector3(1.1, 0.1, 1.1), Vector3(1.25, 0.1, 1.25), 0.15);

func btn_graphic_unpress():
	_scale_tween(Vector3(1.05, 2, 1.05), Vector3(1, 1, 1), 0.45);

func _scale_tween(begin:Vector3, end:Vector3, duration:float):
	if _button_parent and self.get_parent():
		if current_tween and current_tween.is_running():
			current_tween.kill();
			current_tween = null;
		_button_parent.scale = begin;
		current_tween = create_tween();
		if current_tween:
			current_tween.tween_property(_button_parent, "scale", end, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC);
		else:
			_button_parent.scale = end;
