@tool
class_name ExposableNode3DTexture extends ExposableNode3D

@export_group("Config")
@export var _mesh_instance_3D:MeshInstance3D
@export var _uv_index:int = 0

@export var texture:Texture:
	set (value) : 
		texture = value
		set_texture(texture)

func get_slot_properties(exposer:Node) -> Array[Dictionary]:
	# The final array of the property list
	var propertyArray:Array[Dictionary]
	# Append the group which will contain the generated properties
	
	var node_id = exposer.get_path_to(self).get_concatenated_names()
	
	propertyArray.append({
			name = name,
			type = TYPE_NIL,
			hint_string = node_id + "*",
			usage = PROPERTY_USAGE_GROUP
		})

	propertyArray.append({
		name = node_id + "*texture",
		type = TYPE_OBJECT, 
		hint = PROPERTY_HINT_RESOURCE_TYPE,
		hint_string = "Texture"
	})
	# Return the property array
	return propertyArray


func get_slot_property(property:String):
	if property == "texture": return texture

func set_slot_property(property:String, value):
	if property == "texture": texture = value
	set_texture(texture)

func set_texture(texture:Texture):
#	assert(_mesh_instance_3D, "Mesh instance is required so we can get the Material!")
	if _mesh_instance_3D && _mesh_instance_3D.get_surface_override_material_count() > _uv_index:
		var mat:StandardMaterial3D = _mesh_instance_3D.get_surface_override_material(_uv_index) as StandardMaterial3D
		assert(mat, "Material is required!")		
		if mat:
			mat.albedo_texture = texture
	else:
		printerr("No way to get the material!")
