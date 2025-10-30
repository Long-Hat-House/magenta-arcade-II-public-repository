class_name HoldableChargingFeedback extends Node3D

@onready var anim:AnimationPlayer = $"anim";
@export var initial_speed:float = 1.55;
@export var added_speed:float = 0.15;
@export_category("Charging Audio")
@export var _sfx_start:WwiseEvent
@export var _sfx_stop:WwiseEvent
var tween:Tween;
var i:int = 0;
var _playing:bool = false
var _pressing:bool;

const min_velocity_pressed:float = 0.8;

signal looped;

func _ready() -> void:
	i = 0;
	anim.animation_finished.connect(_animation_finished);

func _exit_tree() -> void:
	if _playing:
		_playing = false
		_sfx_stop.post(self)
		
func _process(delta: float) -> void:
	if _playing: 
		#print("[HOLDABLE CHARGING FEEDBACK] PROCESSING [speed:%s, position:%s] [%s]" % [anim.speed_scale, anim.current_animation_position, Engine.get_physics_frames()]);
		visible = (not is_nan(anim.speed_scale)) and get_parent().can_process();
		if anim.speed_scale < min_velocity_pressed and anim.current_animation_position <= 0.025:
			_animation_finished(anim.assigned_animation);
		
func set_pressed(pressed:bool):
	_pressing = pressed;
	if pressed:
		#print("[HOLDABLE CHARGING FEEDBACK] Animation started %s" % [visible]);	
		visible = true;
		_playing = true
		i = 0;
		anim.speed_scale = maxf(anim.speed_scale, min_velocity_pressed);
		tween_velocity(1, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE);
		if is_nan(anim.current_animation_position): anim.seek(0.1);
		anim.play(&"button_pressed_feedback");
		_sfx_start.post(self)
	elif _playing:
		if not anim.is_playing():
			anim.play(&"button_pressed_feedback");
		_sfx_stop.post(self)
		var advanced_percentage:float = anim.current_animation_position / anim.current_animation_length;
		var min_velocity:float = lerpf(2, -min_velocity_pressed, advanced_percentage);
		anim.speed_scale = minf(anim.speed_scale, min_velocity);
		tween_velocity(-1.5, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD);;
		
		
var _tween:Tween;
func tween_velocity(to:float, time:float)->Tween:
	if _tween and _tween.is_running():
		_tween.kill();
	_tween = create_tween();
	_tween.tween_property(anim, "speed_scale", to, time)
	return _tween;

func _animation_finished(anim_name:StringName):
	#print("[HOLDABLE CHARGING FEEDBACK] Animation finished %s %s %s" % [anim_name, anim.speed_scale, visible]);
	if anim.speed_scale > 0 && _pressing:
		if _pressing:
			i += 1;
			anim.play(&"RESET");
			anim.play(&"button_pressed_feedback", -1.0);
			tween_velocity(initial_speed + i * added_speed, 0.05)\
					.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE);
			looped.emit();
	else:
		finish_playing();
		
func set_neutral_speed_scale():
	anim.speed_scale = 0.1
		
func finish_playing():
	#print("[HOLDABLE CHARGING FEEDBACK] FINISHED [%s]" % [Engine.get_physics_frames()]);
	anim.play(&"RESET");
	_playing = false;
	visible = false;
