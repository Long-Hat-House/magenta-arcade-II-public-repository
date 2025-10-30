class_name Task_PlayerEffect extends Task

enum EffectType{
	DowngradeTap,
	DowngradeHold,
	AddFireRateLvl,
	AddWarmUpLvl,
	AddExtraShot,
	AddHoldLevel,
	RemoveAllHoldBuffs,
}


@export var _effect_type:EffectType
@export var effect_val:int = 1

func _start_task() -> void:
	var player = Player.instance
	if !is_instance_valid(player): return

	match _effect_type:
		EffectType.DowngradeTap:
			player.downgrade_weapon_tap()
		EffectType.DowngradeHold:
			player.downgrade_weapon_hold()
		EffectType.AddHoldLevel:
			player.add_hold_level(effect_val)
		EffectType.AddFireRateLvl:
			move_value(effect_val, player.upgrade_hold_firerate_level, player.downgrade_hold_firerate_level);
		EffectType.AddWarmUpLvl:
			move_value(effect_val, player.upgrade_hold_warmup_level, player.downgrade_hold_warmup_level);

		EffectType.AddExtraShot:
			player.add_extra_shot_level(effect_val)
			
		EffectType.RemoveAllHoldBuffs:
			move_value(-player.currentState.hold_fire_rate_level, player.downgrade_hold_firerate_level, player.downgrade_hold_firerate_level);
			move_value(-player.currentState.hold_warm_up_level, player.downgrade_hold_warmup_level, player.downgrade_hold_warmup_level);

func move_value(amount:int, callable_more:Callable, callable_less:Callable):
	var val:int = effect_val
	if val > 0:
		while val > 0:
			val -= 1
			callable_more.call()
	elif val < 0:
		while val > 0:
			val -= 1
			callable_less.call();
