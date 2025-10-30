@tool
class_name ExposableNode3D extends Node3D

func get_slot_properties(exposer:Node) -> Array[Dictionary]:
	# The final array of the property list
	var propertyArray:Array[Dictionary]
	
	# Return the property array
	return propertyArray

func get_slot_property(property:String):
	pass

func set_slot_property(property:String, value):
	pass

func _get_configuration_warnings() -> PackedStringArray:
	if self.get_script() == preload("res://systems/element_scene_structure/exposable_node_3d.gd"):
		return ["Exposable Node 3D class is meant to be overriden and not directly used!"]
	return []
