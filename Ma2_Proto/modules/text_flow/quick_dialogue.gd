class_name QuickDialogue extends Node3D

var flow_player:TextFlowPlayer;

static func find_anim(diag:QuickDialogue)->AnimatedSprite3D:
	var par = diag.get_parent();
	while par != null:
		if par is AnimatedSprite3D:
			break;
		else:
			par = par.get_parent();
	return par;

static func assign_animation_parent(diag:QuickDialogue, idle:StringName, speech:StringName):
	assign_animation(diag, find_anim(diag), idle, speech);

static func assign_animation(diag:QuickDialogue, anim:AnimatedSprite3D, idle:StringName, speech:StringName):
	anim.play(idle);
	diag.speech_start.connect(func():
		anim.play(speech);
		);
	diag.speech_end.connect(func():
		if anim.animation == speech:
			anim.play(idle);
		);

@export var voice:TextFlowBubbleSpeaker.SpeakerVoice = TextFlowBubbleSpeaker.SpeakerVoice.Fanatic

## The speakers you want. If left empty, it will use only self
@export var speakers_followee:Array[Node3D] = [];

## The dialogue ID you want. If you leave it empty, it will use the node's name instead.
@export var dialogue_id:StringName;

## Extra dialogue IDs that will play one after another.
@export var dialogue_id_extra:Array[StringName];
var bubble_scene = load("res://modules/text_flow/scenes/text_flow_bubble.tscn");

## Attach a Notifier3D so it will only start talking when it is on screen.
@export var needs_in_screen:VisibleOnScreenNotifier3D;

## If needs_call, then it will not start automatically as soon as possible
@export var needs_call:bool;

## A delay before the conversation starts
@export var delay:float;

## Does the conversation loops? If many extra_ids are there, only the last one loops.
@export var loops:bool;

var called_for_stop:bool;

signal speech_start;
signal speech_end;
signal speech_start_speaker(node:Node3D);
signal speech_end_speaker(node:Node3D);
signal flow_started;
signal flow_finished;
signal flow_interrupted;
signal flow_stopped;

func _ready() -> void:
	flow_player = TextFlowPlayerBubbles.new();
	flow_player._basic_bubble_scene = bubble_scene;
	if speakers_followee.is_empty():
		speakers_followee.push_back(self);
	for speaker_node in speakers_followee:
		var speaker := TextFlowBubbleSpeaker.new();
		speaker.followee = speaker_node;
		speaker.bubble_started.connect(_speech_start.bind(speaker.followee));
		speaker.bubble_finished.connect(_speech_end.bind(speaker.followee));
		speaker.set_voice(voice)
		flow_player.set_speaker(speaker, speaker_node.name);
	flow_player.flow_started.connect(_on_flow_started);
	flow_player.flow_finished.connect(_on_flow_finished);
	flow_player.flow_killed.connect(_on_flow_killed);
	add_child(flow_player);

	if !needs_call:
		start_dialogue();

func cmd_dialogue(wait:bool = true)->Level.CMD:
	var arr:Array[Level.CMD] = [
		Level.CMD_Callable.new(start_dialogue),
	]

	if wait:
		arr.push_back(Level.CMD_Wait_Signal.new(flow_stopped));

	return Level.CMD_Sequence.new(arr);

func cmd_stop_dialogue()->Level.CMD:
	return Level.CMD_Callable.new(stop_dialogue);


func start_dialogue():
	called_for_stop = false;
	if needs_in_screen != null and not needs_in_screen.is_on_screen():
		await needs_in_screen.screen_entered;

	if delay > 0:
		await get_tree().process_frame;
		await get_tree().create_timer(delay).timeout;

	_talk();

func stop_dialogue():
	called_for_stop = true;
	_interrupt();

func is_talking()->bool:
	return flow_player.is_playing();

func _talk():
	var all_talks:Array[StringName] = dialogue_id_extra.duplicate();
	if dialogue_id.is_empty():
		all_talks.push_front(name.strip_edges());
	else:
		all_talks.push_front(dialogue_id);
	var len:int = all_talks.size();
	for i in range(len):
		if called_for_stop:
			return;
		if i < len - 1:
			flow_player.start_flow(all_talks[i], false);
			await flow_stopped;
		else:
			flow_player.start_flow(all_talks[i], loops)

func _interrupt():
	flow_player.kill_flow(true);

func _speech_start(speaker:Node3D):
	speech_start.emit();
	speech_start_speaker.emit(speaker);

func _speech_end(speaker:Node3D):
	speech_end.emit();
	speech_end_speaker.emit(speaker);

func _on_flow_started():
	flow_started.emit();

func _on_flow_finished():
	flow_finished.emit();
	flow_stopped.emit();

func _on_flow_killed():
	flow_interrupted.emit();
	flow_stopped.emit();

func _get_configuration_warnings() -> PackedStringArray:
	if speakers_followee.size() <= 0:
		return ["This has to have at least one followee! It will use its name as SPEAKER_ID!"];
	else:
		return [];
