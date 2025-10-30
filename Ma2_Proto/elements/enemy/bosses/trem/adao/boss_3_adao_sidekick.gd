extends Node3D

@onready var quick_dialogue_idle: QuickDialogue = $"QuickDialogue-Idle"
@onready var quick_dialogue_run: QuickDialogue = $"QuickDialogue-Run"

@onready var anim: AnimatedSprite3D = $AnimatedSprite3D_CorrectSize

@export var time_before_talk:float;
@export var time_before_animation:float;
@export var time_between_talks:float;
@export var time_after_talk:float;
@export var run_duration:float = 1.5;

@export var first_idle:StringName = "idle";
@export var first_speech:StringName = "speech_phone";
@export var first_to_second:StringName = "idle";
@export var second_idle:StringName = "idle";
@export var second_speech:StringName = "speech";

@export var sfx_phone:AkEvent3D;
@export var sfx_phone_animation:StringName = "idle_phone";
@export var sfx_phone_shutdown:AkEvent3D;

signal exited_screen;
signal talked_to_eva;
signal talked_to_god;
signal ran_away;

func _ready() -> void:
	anim.play(first_idle);
	anim.animation_changed.connect(func():
		if anim.animation == sfx_phone_animation:
			sfx_phone.post_event();
		)
	quick_dialogue_idle.speech_start.connect(_change_anim.bind(first_idle, first_speech));
	quick_dialogue_idle.speech_end.connect(_change_anim.bind(first_speech, first_idle));

	quick_dialogue_run.speech_start.connect(_change_anim.bind(second_idle, second_speech));
	quick_dialogue_run.speech_end.connect(_change_anim.bind(second_speech, second_idle));

func _change_anim(origin:StringName, animation:StringName):
	if anim.animation == origin:
		anim.play(animation);

func converse():
	await _timer(time_after_talk);
	quick_dialogue_idle.start_dialogue();
	await quick_dialogue_idle.flow_finished;
	talked_to_eva.emit();
	await _timer(time_before_animation);
	anim.play(first_to_second);
	sfx_phone_shutdown.post_event();
	await anim.animation_looped;
	anim.play(second_idle);
	await _timer(time_between_talks);
	quick_dialogue_run.start_dialogue();
	await quick_dialogue_run.flow_finished;
	talked_to_god.emit();
	await _timer(time_after_talk);
	run();


func _timer(duration:float):
	await get_tree().create_timer(duration).timeout;


func run():
	quick_dialogue_idle.stop_dialogue();
	quick_dialogue_run.stop_dialogue();

	exited_screen.connect(func():
		ran_away.emit();
		, CONNECT_ONE_SHOT);

	anim.play(&"pre_run");
	await anim.animation_looped;
	anim.play(&"run");
	var t:= create_tween()
	t.tween_property(self, "position", Vector3.RIGHT * 8, run_duration)\
			.as_relative().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD);
	t.tween_callback(queue_free);


func _on_out_notifier_screen_exited() -> void:
	exited_screen.emit();
