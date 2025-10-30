class_name Switch_Oning_Offing_AnimationPlayer extends AnimationPlayer

enum State{
	Undefined,
	On,
	Off,
	Oning,
	Offing
}

@export var on_animation:String = "on";
@export var off_animation:String = "off";
@export var oning_animation:String = "oning";
@export var offing_animation:String = "offing";
@export var switch_starts:bool;

signal turned_off()
signal turned_on()

var _state:State = State.Undefined

func _ready():
	_switch_start()

func _switch_start():
	if _state == State.Undefined:
		if switch_starts:
			if has_animation(oning_animation):
				play(oning_animation)
				var anim = get_animation(oning_animation)
				seek(anim.length,true)
			if !has_animation(on_animation):
				push_warning("Animation not found -" + on_animation + "- in " + get_path().get_concatenated_names())
			play(on_animation)
			_state = State.On
		else:
			if has_animation(offing_animation):
				play(offing_animation)
				var anim = get_animation(offing_animation)
				seek(anim.length,true)
			if !has_animation(off_animation):
				push_warning("Animation not found -" + off_animation + "- in " + get_path().get_concatenated_names())
			play(off_animation)
			_state = State.Off
		animation_finished.connect(on_animation_finished)

func is_set_to_on() -> bool:
	return _state == State.On || _state == State.Oning

func is_set_to_off() -> bool:
	return _state == State.Off || _state == State.Offing

func is_not_set_yet() -> bool:
	return _state == State.Undefined

func set_switch(is_on:bool, force:bool = false):
	if _state == State.Undefined:
		_switch_start()

	if !force:
		if is_on && is_set_to_on(): return
		if !is_on && is_set_to_off(): return

	if is_on:
		_state = State.Oning
		if !has_animation(oning_animation):
			push_warning("Animation not found -" + oning_animation + "- in " + get_path().get_concatenated_names())
		play(oning_animation);
	else:
		_state = State.Offing
		if !has_animation(offing_animation):
			push_warning("Animation not found -" + offing_animation + "- in " + get_path().get_concatenated_names())
		play(offing_animation);

func set_switch_immediate(is_on:bool, force:bool = false):
	if _state == State.Undefined:
		_switch_start()

	if !force:
		if is_on && is_set_to_on(): return
		if !is_on && is_set_to_off(): return

	if is_on:
		_state = State.Oning
		on_animation_finished(oning_animation)
	else:
		_state = State.Offing
		on_animation_finished(offing_animation)

func on_animation_finished(anim_name:StringName):
	match _state:
		State.Oning:
			_state = State.On
			if !has_animation(on_animation):
				push_warning("Animation not found -" + on_animation + "- in " + get_path().get_concatenated_names())
			play(on_animation)
			turned_on.emit()
		State.Offing:
			_state = State.Off
			if !has_animation(off_animation):
				push_warning("Animation not found -" + off_animation + "- in " + get_path().get_concatenated_names())
			play(off_animation)
			turned_off.emit()

func await_turned_off():
	while is_instance_valid(self) and (_state != State.Off):
		await get_tree().process_frame
