class_name Graphic_Perseguidora extends LHH3D

@onready var animation_player:AnimationPlayer = $AnimationPlayer

var is_open:bool;
var is_warning: bool;
func set_open(open:bool):
	is_open = open;
	if is_warning: return
	if open:
		animation_player.play("open")
		await animation_player.animation_finished;
		if is_open: animation_player.play("idle_open");
	else:
		animation_player.play("close")
		await animation_player.animation_finished;
		animation_player.play("idle_close");

func warning():
	is_warning = true
	animation_player.play("pre_explosion")
