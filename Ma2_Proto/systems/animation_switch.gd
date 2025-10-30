class_name AnimationSwitch extends Switch

@export var animPlayer:AnimationPlayer
@export var onAnimation:String;
@export var oningAnimation:String;
@export var offAnimation:String;
@export var offingAnimation:String;

func _set_switch(set:bool) -> void:
	if set:
		_do_anims(oningAnimation, onAnimation);
	else:
		_do_anims(offingAnimation, offAnimation);
	
func _do_anims(before:String, after:String):
	if not before.is_empty():
		animPlayer.play(before);
		await animPlayer.animation_finished;
	animPlayer.play(after);
