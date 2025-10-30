class_name Feedback_Squish extends Node

@export var squished_begin:Vector3 = Vector3(1.5,0.3,1.5);
@export var squished_end:Vector3 = Vector3(1.2,0.25,1.2);
@export var unsquished_begin:Vector3 = Vector3(1.15, 1.8, 1.15);
@export var duration_in:float = 0.08;
@export var duration_out:float = 0.115;
@export var duration_out_y_multiplier:float = 4;
@export var trans:Tween.TransitionType = Tween.TRANS_QUAD;
@export var scaler:Node3D

var tween:Tween;

var should_unsquish:bool;

signal squished;
signal unsquished;
signal animated;

var original_scale:Vector3;

func _ready() -> void:
	original_scale = scaler.scale;
	squished.connect(emit_animated);
	unsquished.connect(emit_animated);
	
func emit_animated()->void:
	animated.emit();

func squish():
	scaler.scale = squished_begin;
	await _quick_tween_model(squished_end, trans, duration_in, duration_in * 0.75);
	squished.emit();

func unsquish():
	scaler.scale = unsquished_begin;
	should_unsquish = true;
	await _quick_tween_model(original_scale, Tween.TRANS_ELASTIC, duration_out, duration_out * duration_out_y_multiplier, duration_out * 0.25);
	if should_unsquish:
		should_unsquish = false;
		unsquished.emit();
	
func enter_body(b:Node3D):
	squish();
	
func leave_body(b:Node3D):
	unsquish();

func _quick_tween_model(to:Vector3, trans_y:Tween.TransitionType, duration:float, y_duration:float, y_delay:float = 0):
	if tween and tween.is_valid():
		tween.kill();
		
	if should_unsquish:
		should_unsquish = false;
		unsquished.emit();
		
	tween = self.create_tween();
	tween.set_parallel();
	tween.tween_property(scaler, "scale:x", to.x, duration).set_ease(Tween.EASE_OUT).set_trans(trans);
	tween.tween_property(scaler, "scale:z", to.z, duration).set_ease(Tween.EASE_OUT).set_trans(trans);
	tween.tween_property(scaler, "scale:y", to.y, y_duration).set_delay(y_delay).set_ease(Tween.EASE_OUT).set_trans(trans_y);
	await tween.finished;
