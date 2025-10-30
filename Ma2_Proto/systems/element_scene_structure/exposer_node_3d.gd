@tool
class_name ExposerNode3D extends Node3D

func _child_slots():
	return find_children("", "ExposableNode3D", true, false)

func _get_property_list() -> Array[Dictionary]:
	var arr:Array[Dictionary] = []
	for slot in _child_slots():
		arr.append_array(slot.get_slot_properties(self))

	return arr

func _set(property: StringName, value: Variant) -> bool:
	var split = property.split("*",false)
	if split.size() > 1:
		var obj_id:String = split[0]
		var prop:String = split[1]
		if get_child_count() > 0:
			var obj:ExposableNode3D = get_node(obj_id) as ExposableNode3D
			if obj:
				obj.set_slot_property(prop, value)
			notify_property_list_changed()
		return true
	return false

func _get(property: StringName) -> Variant:
	var split = property.split("*",false)
	if split.size() > 1:
		var obj_id:String = split[0]
		var prop:String = split[1]
		var obj:ExposableNode3D = get_node(obj_id) as ExposableNode3D
		if obj:
			return obj.get_slot_property(prop)
	return null
