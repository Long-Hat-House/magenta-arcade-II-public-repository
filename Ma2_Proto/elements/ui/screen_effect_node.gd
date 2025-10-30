extends Node

signal screen_effect_done;

@export var effect:HUD.ScreenEffect;

func do_screen_effect():
	if is_instance_valid(HUD.instance):
		await HUD.instance.make_screen_effect(effect);
	screen_effect_done.emit();
