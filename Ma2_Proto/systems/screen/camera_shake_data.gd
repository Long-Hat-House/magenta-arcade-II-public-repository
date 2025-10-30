class_name CameraShakeData extends Resource

@export var absolute_strength:Vector3;
@export var rotated_strength:Vector3;
@export var durationIn:float;
@export var easeIn:Tween.EaseType = Tween.EASE_OUT;
@export var transIn:Tween.TransitionType = Tween.TRANS_SINE;
@export var durationOut:float;
@export var easeOut:Tween.EaseType = Tween.EASE_IN;
@export var transOut:Tween.TransitionType = Tween.TRANS_SINE;

func screen_shake():
	CameraShaker.screen_shake(self);
