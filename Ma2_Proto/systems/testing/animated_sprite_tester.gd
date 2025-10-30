extends AnimatedSprite3D

var cur_anim:int;
@export var key_code:Key = KEY_A;
var was_pressing:bool;

func _process(delta: float) -> void:
	var is_pressed:bool = Input.is_key_pressed(key_code);
	if is_pressed and not was_pressing:
		change_animation();
	was_pressing = is_pressed;

func change_animation():
	if sprite_frames == null:
		LogUtils.log_warning("No sprite_frames for %s in %s!" % [name, owner.name]);
		return;
	cur_anim += 1;
	var anims:PackedStringArray = sprite_frames.get_animation_names();
	var next_anim:String = anims[cur_anim % anims.size()];
	print("[ANIMSPRITE3D TESTER] Pressed %s so now playing '%s' in [%s]" % [key_code, next_anim, name]);
	play(next_anim);
