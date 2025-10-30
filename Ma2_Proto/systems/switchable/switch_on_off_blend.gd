class_name Switch_On_Off_Blend extends AnimationTree

@export var blendTime:float = 0;
@export var transType:Tween.TransitionType = Tween.TRANS_CUBIC;
@export var easeType:Tween.EaseType = Tween.EASE_IN_OUT;
var _sv:float;
var switch_value:float:
	get:
		return _sv;
	set(value):
		_sv = value;
		set("parameters/OnOffBlend/blend_amount", _sv);

func set_switch(is_on:bool):
	var finalValue = 1 if is_on else 0;
	if blendTime > 0:
		var t := create_tween();
		t.tween_property(self, "switch_value", finalValue, blendTime).set_trans(transType).set_ease(easeType);
		await t;
	else:
		switch_value = finalValue;
