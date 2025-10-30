class_name Enemy_Statue_Ivo_Eva_Sidekick extends Node3D

signal state_finished()

class AnimationLocale:
	var name:StringName;
	var sprite_index:int;

	func _init(n:StringName, index:int):
		self.name = n;
		self.sprite_index = index;

	func _to_string() -> String:
		return name;

var STATE_HIDDEN	:AnimationLocale = AnimationLocale.new(&"hidden", 0)
var STATE_APPEAR1	:AnimationLocale = AnimationLocale.new(&"appear1", 0)
var STATE_APPEAR2	:AnimationLocale = AnimationLocale.new(&"appear2", 0)
var STATE_PUMP		:AnimationLocale = AnimationLocale.new(&"pump", 0)
var STATE_SPEECH	:AnimationLocale = AnimationLocale.new(&"speech", 0)
var STATE_SPEECH2	:AnimationLocale = AnimationLocale.new(&"speech", 1)
var STATE_EXIT		:AnimationLocale = AnimationLocale.new(&"exit", 0)
var STATE_RISE		:AnimationLocale = AnimationLocale.new(&"rise", 1)
var STATE_POSE		:AnimationLocale = AnimationLocale.new(&"pose", 1)
var STATE_LAUGH		:AnimationLocale = AnimationLocale.new(&"laugh", 1)
var STATE_SHOCK		:AnimationLocale = AnimationLocale.new(&"shock", 1)
var STATE_RETURN_CABLE	:AnimationLocale = AnimationLocale.new(&"return_cable", 1)
var STATE_LAUGH_BUT_WORRIED	:AnimationLocale = AnimationLocale.new(&"laugh_but_worried", 1)

const DIAL_HIDDEN 	:StringName = &"dial_lvl1_challenge_statue_hidden"
const DIAL_APPEAR1 	:StringName = &"dial_lvl1_challenge_statue_appear"
const DIAL_INTRO 	:StringName = &"dial_lvl1_challenge_statue_intro"
const DIAL_DURING	:StringName = &"dial_lvl1_challenge_statue_idle"
const DIAL_LOST 	:StringName = &"dial_lvl1_challenge_statue_playerlose"
const DIAL_WIN 		:StringName = &"dial_lvl1_challenge_statue_playerwin"
const DIAL_2TRANS	:StringName = &"dial_lvl1_challenge_statue_phasetransition";
const DIAL_2_IDLE	:StringName = &"dial_lvl1_challenge_statue_idle_phase2";
const DIAL_2_END	:StringName = &"dial_lvl1_challenge_statue_end";

@export var sprite0:AnimatedSprite3D
@export var sprite1:AnimatedSprite3D
@onready var sprites:Array[AnimatedSprite3D] = [sprite0, sprite1];
@export var flow_player:TextFlowPlayerBubbles

@export var bubble_position_default:Node3D
@export var bubble_position_appear1:Node3D
@export var bubble_position_hidden:Node3D

class State:
	var main_animation:AnimationLocale
	var parry_animations:Array[AnimationLocale]
	var talk_animations:Array[AnimationLocale]
	var bubble_position:Node3D

	func _init(
		main_animation:AnimationLocale,
		parry_animations:Array[StringName],
		talk_animations:Array[StringName],
		bubble_position:Node3D = null,
		parry_animations_index:int = 0,
		talk_animations_index:int = 0) -> void:

		self.main_animation 	= main_animation
		self.parry_animations 	= [];
		for a in parry_animations:
			self.parry_animations.push_back(AnimationLocale.new(a, parry_animations_index));
		self.talk_animations 	= [];
		for a in talk_animations:
			self.talk_animations.push_back(AnimationLocale.new(a, talk_animations_index));

		self.bubble_position 	= bubble_position

var states:Dictionary

var _current_state:State
var _is_parrying:bool
var _is_talking:bool
var _is_pumping:bool;


signal pumped(canceled:bool);

var _bubble_speaker:TextFlowBubbleSpeaker

func _ready() -> void:
	states = {
		STATE_HIDDEN 	: State.new(STATE_HIDDEN	,[],[], bubble_position_hidden),
		STATE_APPEAR1 	: State.new(STATE_APPEAR1	,[],[], bubble_position_appear1),
		STATE_APPEAR2 	: State.new(STATE_APPEAR2	,[&"parry1", &"parry2", &"parry3"], []),
		STATE_PUMP 		: State.new(STATE_PUMP		,[&"parry1", &"parry2", &"parry3"],[&"speech_talk"]),
		STATE_SPEECH 	: State.new(STATE_SPEECH 	,[&"parry1", &"parry2", &"parry3"],[&"speech_talk"]),
		STATE_SPEECH2 	: State.new(STATE_SPEECH2 	,[&"parry1", &"parry2", &"parry3"], []),
		STATE_EXIT 		: State.new(STATE_EXIT 		,[], []),
		STATE_RISE 		: State.new(STATE_RISE 		,[], []),
		STATE_POSE 		: State.new(STATE_POSE 		,[], []),
		STATE_LAUGH 	: State.new(STATE_LAUGH 	,[], []),
		STATE_SHOCK 	: State.new(STATE_SHOCK 	,[], []),
		STATE_LAUGH_BUT_WORRIED 	: State.new(STATE_LAUGH_BUT_WORRIED 	,[], []),
		STATE_RETURN_CABLE 	: State.new(STATE_RETURN_CABLE 	,[], []),
	}

	#put bubble hidden in statue
	var parentPos:Vector3 = get_parent_node_3d().global_position;
	bubble_position_hidden.global_position.x = parentPos.x;
	bubble_position_hidden.global_position.z = parentPos.z;

	for sprite in sprites:
		sprite.animation_finished.connect(_on_animation_finished)

	_bubble_speaker = TextFlowBubbleSpeaker.new(bubble_position_default)
	_bubble_speaker.bubble_finished.connect(_on_bubble_finished)
	_bubble_speaker.bubble_started.connect(_on_bubble_started)
	_bubble_speaker.voice = TextFlowBubbleSpeaker.SpeakerVoice.Eva

	flow_player.set_speaker(_bubble_speaker, "eva")
	flow_player.flow_finished.connect(_on_flow_finished)

	_change_state(STATE_HIDDEN);

func play_sprite(name:StringName, index:int):
	var chosen:AnimatedSprite3D = sprites[index];
	for sprite in sprites:
		if sprite == chosen:
			sprite.show();
		else:
			sprite.hide();
	chosen.play(name);

func _play_local(animation_locale:AnimationLocale):
	play_sprite(animation_locale.name, animation_locale.sprite_index);

func _on_bubble_finished():
	_is_talking = false

	if _is_parrying or _is_pumping: return #will change animation when parry finishes

	_play_local(_current_state.main_animation);


func _on_bubble_started():
	_is_talking = true

	if _is_parrying or _is_pumping: return #will change animation when parry finishes

	if _current_state.talk_animations.size() > 0:
		_play_local(_current_state.talk_animations.pick_random());


func _set_pumping():
	_is_pumping = true;

func _stop_pumping(by_canceling:bool):
	if _is_pumping:
		_is_pumping = false;
		pumped.emit(by_canceling);

func _on_animation_finished():
	# was pumping
	if _is_pumping:
		_stop_pumping(false);
		_solve_one_shot_animation();

	# was parrying
	if _is_parrying:
		_is_parrying = false
		_solve_one_shot_animation();

	# was not parrying, finished the main animation
	state_finished.emit()

func _solve_one_shot_animation():
	# should go back to talking
	if _is_talking && _current_state.talk_animations.size() > 0:
		_play_local(_current_state.talk_animations.pick_random());
		return

	# back to main animation
	else:
		_play_local(_current_state.main_animation);
		return

func _on_flow_finished():
	state_finished.emit()

func cmd_play_state(state:AnimationLocale, dialogue:StringName, loop:bool = false):
	var cmd_array:Array[Level.CMD] = []

	cmd_array.push_back(Level.CMD_Callable.new(
		func ():
			_change_state(state)
			play_dialogue(dialogue, loop);
	))

	if !loop:
		cmd_array.push_back(Level.CMD_Wait_Signal.new(state_finished))

	return Level.CMD_Sequence.new(cmd_array)

func play_dialogue(dialogue:StringName, loop:bool = false):
	if !dialogue.is_empty():
		flow_player.start_flow(dialogue, loop)
	else:
		flow_player.kill_flow(true)

func stop_dialogue():
	flow_player.kill_flow(true)

func _change_state(state:AnimationLocale, force:bool = false):
	var new_state:State = states[state]

	if not force and _current_state == new_state: return
	_current_state = new_state

	if _current_state.bubble_position:
		_bubble_speaker.followee = _current_state.bubble_position
	else:
		_bubble_speaker.followee = bubble_position_default

	_stop_pumping(true);
	if _is_parrying: return
	if _is_talking && _current_state.talk_animations.size() > 0:
		_play_local(_current_state.talk_animations.pick_random());
	else:
		_play_local(_current_state.main_animation);

func _on_area_3d_body_entered(_body):
	parry();

func _on_area_3d_area_entered(_area):
	parry();

func set_flip(flip:bool):
	for sprite in sprites:
		sprite.flip_h = flip;

func parry():
	if _current_state.parry_animations.size() > 0:
		_stop_pumping(true);
		_is_parrying = true
		_play_local(_current_state.parry_animations.pick_random());

func pump_once():
	_set_pumping();
	_play_local(STATE_PUMP);

func pose():
	_change_state(STATE_POSE);

func return_cable():
	_change_state(STATE_RETURN_CABLE);

func rise():
	_change_state(STATE_RISE);

func first_shock():
	_change_state(STATE_SPEECH2);

func laugh():
	_change_state(STATE_LAUGH);

func laugh_but_worried():
	_change_state(STATE_LAUGH_BUT_WORRIED);

func shock():
	_change_state(STATE_SHOCK);
