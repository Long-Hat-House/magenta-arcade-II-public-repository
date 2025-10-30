@tool
class_name UpgradeSet extends Resource

@export var set_id:StringName:
	set(val):
		if val.is_empty():
			val = resource_path.get_file().get_basename()
		set_id = val
	get:
		if set_id.is_empty():
			return resource_path.get_file().get_basename()
		return set_id

@export var set_description:StringName:
	set(val):
		if val.is_empty():
			val = set_id + "_description"
		set_description = val
	get:
		if set_id.is_empty():
			return set_id + "_description"
		return set_description

@export var icon:Texture2D
@export var color:Color
@export var color_highlight:Color

@export var upgrades_list:Array[UpgradeInfo]

func get_upgrade(index:int) -> UpgradeInfo:
	if index < 0 || index >= upgrades_list.size():
		return null
	return upgrades_list[index]

func get_upgrades_list() -> Array[UpgradeInfo]:
	return upgrades_list

func get_allocated_summed_stars() -> int:
	var count:int = 0

	for upgrade in upgrades_list:
		count += upgrade.get_allocated_stars()

	return count
