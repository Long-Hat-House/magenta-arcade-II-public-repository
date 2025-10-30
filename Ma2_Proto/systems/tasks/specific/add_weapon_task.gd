class_name Task_AddWeapon extends Task

@export var instruction = "Add an weapon as child of this node."

func get_weapon()->PlayerWeapon:
	for child in get_children():
		if child is PlayerWeapon:
			return child as PlayerWeapon;
	printerr("No weapon in %s" % [self]);
	return null;

func start_task()->void:
	Player.instance.add_weapon(get_weapon());
