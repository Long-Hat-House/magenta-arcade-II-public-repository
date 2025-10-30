@tool
class_name ExposableNode3DChildScene extends ExposableNode3D

@export var scene:PackedScene:
	set (value):
		scene = value
		resource_changed()

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
		name = node_id + "*scene",
		type = TYPE_OBJECT, 
		hint = PROPERTY_HINT_RESOURCE_TYPE,
		hint_string = "PackedScene"
	})
	
	# Return the property array
	return propertyArray

func get_slot_property(property:String):
	if property == "scene": return scene

func set_slot_property(property:String, value):
	if property == "scene": scene = value
	resource_changed()

func resource_changed():
	var obj
	for child in get_children():
		if scene && child.scene_file_path == scene.resource_path:
			return
		child.queue_free()
		remove_child(child)
	
	#creates new object
	if scene:
		obj = scene.instantiate()
		add_child(obj)
		if Engine.is_editor_hint():
			obj.owner = self
