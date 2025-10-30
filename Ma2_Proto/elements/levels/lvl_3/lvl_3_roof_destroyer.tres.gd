extends VisibleOnScreenNotifier3D

func _ready() -> void:
	await screen_entered;
	$"..".explode();
	await $"..".exploded;
	HUD.instance.make_screen_effect(HUD.ScreenEffect.ShortFlash);
