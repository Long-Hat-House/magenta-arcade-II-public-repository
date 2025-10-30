class_name PlayerWeaponTap extends PlayerWeapon

@export var _tap_cost:float = 20

func get_tap_cost() -> float:
	return _tap_cost

func get_weapon_level()->PlayerWeaponLevel:
	for child in get_children():
		if child is PlayerWeaponLevel:
			return child as PlayerWeaponLevel;
	return null;

func tap(touch:Player.TouchData, token:PlayerToken, amountTouches:int) -> void:
	var pLevel = get_weapon_level();
	if pLevel:
		pLevel.shoot(touch, 0.0);
