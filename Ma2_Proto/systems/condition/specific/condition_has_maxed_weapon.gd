class_name Condition_HasMaxedWeapon extends Condition

@export var specific_weapon:PlayerWeapon;
@export var weapon_type:PlayerWeapon.WeaponType;

func _enter_tree() -> void:
	Player.instance.weapon_any_change.connect(_weapon_change);

func _exit_tree() -> void:
	Player.instance.weapon_any_change.disconnect(_weapon_change);

func _weapon_change():
	_call_condition_changed(is_condition());

func is_condition()-> bool:
	if specific_weapon:
		match specific_weapon.type:
			PlayerWeapon.WeaponType.HOLD:
				if Player.instance.is_it_same_weapon(Player.instance.equippedHold, specific_weapon):
					return is_maxed_out(PlayerWeapon.WeaponType.HOLD);
				else:
					return false;
			PlayerWeapon.WeaponType.TAP:
				if Player.instance.is_it_same_weapon(Player.instance.equippedTap, specific_weapon):
					return is_maxed_out(PlayerWeapon.WeaponType.TAP);
				else:
					return false;
	return is_maxed_out(weapon_type);


func is_maxed_out(type:PlayerWeapon.WeaponType)->bool:
	return false
	match type:
		PlayerWeapon.WeaponType.HOLD:
			return Player.instance.currentState.hold_level >= Player.instance.get_max_hold_level();
		PlayerWeapon.WeaponType.TAP:
			return Player.instance.currentState.tap_level >= Player.instance.get_max_tap_level();
	return false;
