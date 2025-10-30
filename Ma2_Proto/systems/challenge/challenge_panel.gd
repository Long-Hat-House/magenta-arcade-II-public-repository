class_name ChallengePanel extends CanvasItem

enum State {
	Undefined,
	Hidden,
	Showing,
	Shown,
	Hiding
}

signal show_completed
signal hide_completed
@export var animation:AnimationPlayer

var _animation_switchable:Switch_Oning_Offing_AnimationPlayer;

var state : State = State.Undefined :
	set(value):
		if state == value:
			return
		state = value
		match state:
			State.Hidden:
				hide()
				hide_completed.emit()
			State.Shown:
				show_completed.emit()
	get:
		return state

func _ready():
	if animation:
		_animation_switchable = animation as Switch_Oning_Offing_AnimationPlayer

	if _animation_switchable:
		_animation_switchable.turned_on.connect(func(): state = State.Shown)
		_animation_switchable.turned_off.connect(func():
			state = State.Hidden
			hide()
			)
	elif animation:
		animation.animation_finished.connect(func(anim_name):
			state = State.Shown
			state = State.Hidden
			hide()
			)
	hide()

func panel_show():
	if state == State.Showing || state == State.Shown:
		return
	state = State.Showing
	if _animation_switchable:
		_animation_switchable.set_switch(true)
	elif animation:
		animation.play("one_shot")
	else:
		show()

func panel_hide():
	if state == State.Hiding || state == State.Hidden:
		return
	state = State.Hiding
	if _animation_switchable:
		_animation_switchable.set_switch(false)
	elif animation:
		print_debug("Hiding a panel that is hidden automatically. Will force hide it")
		state = State.Hidden
		hide()
	else:
		state = State.Hidden
		hide()
