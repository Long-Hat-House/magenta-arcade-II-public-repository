class_name AnimationPlayerProxy extends Node

var _anim:AnimationPlayer;
var animationPlayer:AnimationPlayer:
	get:
		if not _anim:
			_anim = $AnimationPlayer;
		return _anim;

var current_animation:StringName:
	get:
		return animationPlayer.current_animation;
	set(value):
		animationPlayer.current_animation = value;

signal animation_finished(anim:StringName);
signal animation_changed(old:StringName, new:StringName);

func _ready() -> void:
	animationPlayer.animation_finished.connect(animation_finished.emit);
	animationPlayer.animation_changed.connect(animation_changed.emit);


func play(anim:StringName, custom_blend:float = -1, custom_speed:float = 1.0, from_end:bool = false)->void:
	animationPlayer.play(anim, custom_blend, custom_speed, from_end);

func play_one_shot(anim:StringName, custom_blend:float = -1, custom_speed:float = 1.0, from_end:bool = false)->void:
	var currentAnim = animationPlayer.current_animation;
	animationPlayer.play(anim, custom_blend, custom_speed, from_end);
	await animationPlayer.animation_finished;
	animationPlayer.play(currentAnim);
