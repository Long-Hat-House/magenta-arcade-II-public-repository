class_name Condition_HasAnythingToSacrifice extends Condition

@export var effect_type:Task_PlayerEffect.EffectType

func is_condition()-> bool:
	var player := Player.instance;
	if player:
		match effect_type:
			Task_PlayerEffect.EffectType.DowngradeTap:
				return player.currentState.tap_level > 0;
			Task_PlayerEffect.EffectType.DowngradeHold:
				return player.currentState.hold_level > 1;
			Task_PlayerEffect.EffectType.AddFireRateLvl:
				return player.currentState.hold_fire_rate_level > 0;
			Task_PlayerEffect.EffectType.AddWarmUpLvl:
				return player.currentState.hold_warm_up_level > 0;
			Task_PlayerEffect.EffectType.AddExtraShot:
				return player.currentState.extra_shot_level > 0;
			Task_PlayerEffect.EffectType.AddHoldLevel:
				return player.currentState.hold_level > 0;
			Task_PlayerEffect.EffectType.RemoveAllHoldBuffs:
				return player.currentState.hold_fire_rate_level > 0 or player.currentState.hold_warm_up_level > 0;
	return false;
		
