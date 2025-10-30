class_name PlayerWeaponHold extends PlayerWeapon

const UPGRADE_HOLD_SPEED = preload("res://systems/ma2_meta/upgrades/upgrade_hold_speed.tres")

@export var hold_interval_multiplier_per_fire_rate_level:Curve;

func _get_max_level() -> int:
	var lvl:int = 0
	for child in get_children():
		if child is PlayerWeaponLevel:
			lvl += 1

	return lvl

func find_level(currentLevel:int)->PlayerWeaponLevel:
	var lastLevel:PlayerWeaponLevel;
	for child in get_children():
		if child is PlayerWeaponLevel:
			currentLevel -= 1;
			if currentLevel < 0:
				return child as PlayerWeaponLevel;
			lastLevel = child as PlayerWeaponLevel;
	return lastLevel;

func start_hold(touch:Player.TouchData) -> void:
	var level := find_level(0);
	if level:
		touch.instance.holdValue = maxf(level.holdInterval - 0.10, 0.0);
	else:
		touch.instance.holdValue = 0;

func hold(touch:Player.TouchData, token:PlayerToken, state:Player.PlayerState, delta:float) -> void:
	var currentLevel:PlayerWeaponLevel = find_level(state.hold_potencial);
	if !currentLevel:
		return

	token.holdValue += delta * get_amount_touches_multiplier(state.amountTouches);
	var multiplier:float = hold_interval_multiplier_per_fire_rate_level.sample_baked(state.hold_fire_rate_level);
	var interval:float = currentLevel.holdInterval * multiplier
	while token.holdValue > interval:
		token.holdValue -= interval;
		currentLevel.shoot(touch, clampf(-fmod(token.holdValue, interval), 0.0, interval));

func get_amount_touches_multiplier(touches:int) -> float:
	return 1.0 / touches + clampf(touches - 1, 0.0, 100.0) / 25.0;
