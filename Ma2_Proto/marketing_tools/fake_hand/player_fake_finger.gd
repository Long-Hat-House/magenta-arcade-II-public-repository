class_name PlayerFakeFinger extends Node2D

@onready var anim:AnimatedSprite2D = %AnimatedSprite3D
@export var time_to_release:float = 0.25;

var time_pressed:int;

func _ready() -> void:
	if anim.sprite_frames == null:
		visible = false;
	else:
		anim.play("floating");

func set_pressed(pressed:bool):
	if not visible:
		return;
		
	if pressed:
		play_animations_in_order(["pressing", "pressed"])
		time_pressed = time_now();
	else:
		if get_time_between(time_pressed) < time_to_release:
			play_animations_in_order(["releasing_tap", "floating"])
		else:
			play_animations_in_order(["releasing", "floating"])
			
func time_now()->int:
	return Time.get_ticks_msec();
	
func get_time_between(time:int)->float:
	var time_now:int = time_now();
	print("cursor time compare %s" % [absf(time_now - time) / 1000.0]);
	return absf(time_now - time) / 1000.0; 

func play_animations_in_order(animations:Array[StringName]):
	print("cursor play in order %s!" % [animations]);
	for animation in animations:
		anim.play(animation);
		print("cursor play %s!" % [animation]);
		await anim.animation_finished;
		if anim.animation != animation:
			break;
