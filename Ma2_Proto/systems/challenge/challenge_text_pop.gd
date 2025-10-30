class_name ChallengeTextPop  extends Control

enum Style{
	Default,
	Fail
}

@export var text_label:Label
@export var animation:AnimationPlayer
@export var _sfx_pop:WwiseEvent
var tween:Tween

func _ready():
	hide()
	pass

func set_text(text:String, style:Style = Style.Default):
	if tween && tween.is_valid():
		tween.kill()

	animation.stop()
	text_label.text = text
	match style:
		Style.Fail:
			animation.play("fail")
		_:
			animation.play("show")
			if _sfx_pop: _sfx_pop.post(self)
