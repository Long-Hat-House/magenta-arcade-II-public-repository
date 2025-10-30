extends Node3D

var current_tween:Tween;
var should_complete_tween:bool;
@export var distance_by_damage:float = 2;
@onready var anim: AnimatedSprite3D = $Boss_Nando_Defeat_Graphic
var hit_direction_normalized:Vector3;
var did_normalize:bool;
@export var hit_direction:Vector3 = Vector3(-0.4, 0.0, -1.0):
	get:
		if not did_normalize:
			hit_direction_normalized = hit_direction.normalized();
		return hit_direction_normalized;
@onready var score_giver: ScoreGiver = $ScoreGiver

var is_hurt:bool;
var is_jumping:bool;
var is_in_another_animation:bool;
var jump_target:Vector3;
var finished:bool;

const diag_start:StringName = &"dial_lvl1_boss_nando_start";
const diag_crawl:StringName = &"dial_lvl1_boss_nando_after_crawl";
const diag_end:StringName = &"dial_lvl1_boss_nando_end";

@export var flow:TextFlowPlayerBubbles;
var bubble_speaker:TextFlowBubbleSpeaker;
@onready var bubble_origin: Node3D = $"Pivot/Bubble Origin"

var curr_animation_index:int = 0;
var hurt_anims:Array[StringName] = [&"pirulito_nando_hurt1", &"pirulito_nando_hurt2"]

enum State{
	Idle,
	Hurt,
	Moving,
	Jumping,
	Finished,
	Another,
}
func get_state()->State:
	if is_in_another_animation:
		return State.Another;
	if is_hurt:
		return State.Hurt;
	elif is_jumping:
		return State.Jumping;
	elif global_position.z < jump_target.z:
		return State.Moving;
	elif finished:
		return State.Finished;
	else:
		return State.Idle;
var old_state;

func _ready() -> void:
	bubble_speaker = TextFlowBubbleSpeaker.new();
	flow.set_speaker(bubble_speaker);
	bubble_speaker.bubble_started.connect(_diag_start);
	bubble_speaker.bubble_started.connect(_diag_end);
	bubble_speaker.followee = bubble_origin;
	bubble_speaker.voice = TextFlowBubbleSpeaker.SpeakerVoice.Nando

func _process(delta: float) -> void:
	var now_state := get_state();
	match now_state:
		State.Moving:
			global_position -= hit_direction * 1.85 * delta;
	if now_state != old_state:
		_change_animation(now_state);

		if now_state == State.Idle and old_state == State.Moving:
			talk_crawl_end();
			score_giver.give_score();
		old_state = now_state;

func _change_animation(now_state:State):
	match now_state:
		State.Idle:
			anim.play(&"pirulito_nando_cry");
		State.Finished:
			anim.play(&"nando_losing_idle")
		State.Hurt:
			pass;
		State.Moving:
			anim.play(&"pirulito_nando_back");


func cancel_current_tween():
	if current_tween and current_tween.is_running():
		if should_complete_tween:
			await current_tween.finished;
			return;
		else:
			current_tween.kill();
	current_tween = null;
	should_complete_tween = false;


func jump(from:Vector3, to:Vector3):
	talk_intro();
	global_position = from;
	jump_target = to;
	cancel_current_tween();
	current_tween = create_tween();
	should_complete_tween = true;
	is_jumping = true;
	anim.play(&"pirulito_nando_fly");
	TransformUtils.tween_jump_global(self, current_tween, to, Vector3.UP * 5, 0.65).set_ease(Tween.EASE_OUT_IN).set_trans(Tween.TRANS_SINE);
	await current_tween.finished;
	anim.play(&"pirulito_nando_fly2");
	should_complete_tween = false;
	current_tween = create_tween();
	TransformUtils.tween_jump_global(self, current_tween, to, Vector3.UP * 0.5, 0.35).set_ease(Tween.EASE_OUT_IN).set_trans(Tween.TRANS_QUAD);
	is_jumping = false;

var current_arreda_id:int = 0;

func arreda(damage:float = 1):
	curr_animation_index += 1;
	anim.play(hurt_anims[curr_animation_index % hurt_anims.size()]);

	cancel_current_tween();
	current_arreda_id += 1;
	var this_call_id = current_arreda_id;
	is_hurt = true;
	current_tween = create_tween();
	TransformUtils.tween_jump_global(self, current_tween, self.global_position + hit_direction * 0.5 * damage, Vector3.UP * 0.15, 0.15 * damage).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE);
	#current_tween.tween_property(self, "position", Vector3.FORWARD * 0.5 * damage, 0.25 * damage).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE);
	await current_tween.finished;
	if this_call_id != current_arreda_id: return;
	await get_tree().create_timer(1.25).timeout;
	if this_call_id != current_arreda_id: return;
	is_hurt = false;

func pre_lose():
	finished = true;

func delete():
	queue_free();

func talk_intro():
	flow.start_flow(diag_start, false);

func talk_crawl_end():
	flow.start_flow(diag_crawl, false);

func talk_end():
	flow.start_flow(diag_end, false);

func _diag_start():
	pass;

func _diag_end():
	pass;

func _on_health_try_damage(_health:Health) -> void:
	pass;

func _on_health_hit(damage: RefCounted, _health: Health) -> void:
	if not is_jumping:
		arreda(damage.amount / 3);
