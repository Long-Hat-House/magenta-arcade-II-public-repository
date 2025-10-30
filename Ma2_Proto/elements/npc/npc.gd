class_name NPC extends Pressable

const LVL_INFO_2 = preload("res://elements/levels/lvl_info_2.tres")
const LVL_INFO_3 = preload("res://elements/levels/lvl_info_3.tres")
const LVL_INFO_4 = preload("res://elements/levels/lvl_info_4.tres")

static func GetNPCTypeOnPlayerHP()->Kind:
	if Player.instance != null:
		print("CHECKING NPC TYPE %s <= %s" % ["random", float(Player.instance.hp)/Player.instance.maxHP]);
		if randf() >= float(Player.instance.hp)/Player.instance.maxHP:
			return Kind.Follower;
		else:
			return GetNPCTypeOfBeliever();
	else:
		return GetNPCTypeOfBeliever();

static func GetNPCTypeOfBeliever()->Kind:
	var fanatic:bool;
	if LVL_INFO_4.is_complete(): fanatic = true
	elif LVL_INFO_3.is_complete(): fanatic = randf() < 0.7
	elif LVL_INFO_2.is_complete(): fanatic = randf() < 0.2
	if fanatic:
		return Kind.BelieverFanatic;
	else:
		return Kind.Believer;

@onready var flow_player: TextFlowPlayerBubbles = $TextFlowPlayerBubbles
@onready var flow_offset: Marker3D = $HitArea/TextFlowOffset

@export var may_talk_when_idle:bool = true
@export var talks_when_pressed:bool = true
@export var may_walk_when_idle:bool = true
@export var back_to_idle_after_pressed:bool = false

@export var global_speaker_id:StringName = ""

var distance_threshold:float = 3.0
var velocity:Vector3 = Vector3.ZERO
var state_timer:Timer

enum NPCState {
	UNDEFINED,
	IDLE,
	WALK,
	PRESSING,
	PRESSED_WALK,
	DEAD
}

enum Kind{
	Follower,
	Believer,
	BelieverFanatic
}

enum GraphicMode{
	RandomOnHP,
	RandomFollower,
	RandomBeliever,
	Custom
}
@export_category("Graphic Settings")
@export var graphic_mode:GraphicMode = GraphicMode.RandomOnHP
@export var custom_spriteframes:SpriteFrames
@export var custom_kind:Kind
@export var force_custom_voice:bool = false
@export var custom_voice:TextFlowBubbleSpeaker.SpeakerVoice = TextFlowBubbleSpeaker.SpeakerVoice.Follower
@export var custom_voice_id:int = -1
@export var force_depth_draw_always:bool;

var kind:Kind;

@onready var graphic:Graphic_NPC = $NPC_Graphic_Regular
@onready var randomize_sprite_frames:GraphicNPC_RegularRandomizer = $NPC_Graphic_Regular/RandomizeSpriteFrames

@onready var sfx_die: AkEvent3D = $"SFX Die"

var _current_state: NPCState = NPCState.UNDEFINED

var _speaker: TextFlowBubbleSpeaker
var _is_talking : bool

var _started:bool = false

func _ready() -> void:
	super._ready();
	
	if force_depth_draw_always:
		graphic.no_depth_test = true;

func randomize_on_player_hp():
	apply_kind(GetNPCTypeOnPlayerHP());

func apply_kind(new_kind:Kind):
	self.kind = new_kind;
	match new_kind:
		Kind.BelieverFanatic:
			randomize_sprite_frames.make_fanatic();
		Kind.Believer:
			randomize_sprite_frames.make_believer();
		Kind.Follower:
			randomize_sprite_frames.make_follower();

func make_random_believer():
	apply_kind(Kind.Believer);

func make_random_follower():
	apply_kind(GetNPCTypeOfBeliever());

func get_speaker() -> TextFlowBubbleSpeaker:
	if _speaker:
		return _speaker

	_speaker = TextFlowBubbleSpeaker.new(flow_offset)
	_speaker.bubble_finished.connect(_on_bubble_finished)
	_speaker.bubble_started.connect(_on_bubble_started)

	if force_custom_voice:
		_speaker.voice = custom_voice
		_speaker.voice_type_id = custom_voice_id
	else:
		_speaker.voice_based_on_graphic = randomize_sprite_frames

	if !global_speaker_id.is_empty():
		TextFlowPlayerBubbles.SET_GLOBAL_SPEAKER(_speaker, global_speaker_id)

	return _speaker

func reset_graphics() -> void:
	match graphic_mode:
		GraphicMode.RandomOnHP:
			randomize_on_player_hp()
		GraphicMode.RandomBeliever:
			make_random_believer()
		GraphicMode.RandomFollower:
			make_random_follower()
		GraphicMode.Custom:
			var type:GraphicNPC_RegularRandomizer.Type
			match custom_kind:
				Kind.Follower:
					type = GraphicNPC_RegularRandomizer.Type.Magenta
				Kind.Believer:
					type = GraphicNPC_RegularRandomizer.Type.Believer
				Kind.BelieverFanatic:
					type = GraphicNPC_RegularRandomizer.Type.BelieverFanatic
			randomize_sprite_frames.make_custom(type, custom_spriteframes)
			kind = custom_kind;

func on_enter_screen():
	if !flow_player || state_timer: return
	if is_queued_for_deletion(): return
	_started = true
	reset_graphics()
	set_process(true)
	state_timer = Timer.new()
	state_timer.one_shot = true;
	state_timer.autostart = false;
	add_child(state_timer)
	state_timer.timeout.connect(_on_state_timer_timeout)
	flow_player.flow_finished.connect(_on_state_timer_timeout)
	flow_player.set_speaker(get_speaker())
	_on_state_timer_timeout()

func _on_bubble_finished():
	_is_talking = false

	if _current_state in [NPCState.IDLE]:
		graphic.play_animation("idle")

func _on_bubble_started():
	_is_talking = true

	if _current_state in [NPCState.IDLE]:
		graphic.play_animation("talk")


func talk(dialogue:String, loop:bool = false):
	if _current_state in [NPCState.DEAD]: return
	state_timer.stop()
	flow_player.start_flow(dialogue, loop)

func _exit_tree() -> void:
	if !_started: return
	if is_queued_for_deletion(): return
	flow_player.kill_flow(true)
	state_timer.stop()

func _process(delta):
	match _current_state:
		NPCState.IDLE:
			_do_idle(delta)
		NPCState.WALK:
			_do_walk(delta)
		NPCState.PRESSED_WALK:
			_do_pressed_walk(delta)
		NPCState.DEAD:
			_do_dead(delta)
		NPCState.UNDEFINED:
			# Do nothing in the undefined state
			pass

func _do_walk(delta):
	if velocity == Vector3.ZERO:
		velocity = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * 2

	translate(velocity * delta)

var time = 0;
var angle;
func _do_pressed_walk(delta):
	if velocity == Vector3.ZERO:
		velocity = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * 4

	time += delta*200
	angle = sin(deg_to_rad(time + deg_to_rad(time)*50))*10
	velocity = velocity.rotated(Vector3.UP, deg_to_rad(angle))

	translate(velocity * delta)

func _do_talk(delta):
	return  # Wait for the timer to finish

func _do_idle(delta):
	return  # Wait for the timer to finish

func _do_dead(delta):
	return  # Waits for animation to finish

func _transition_to_idle():
	state_timer.stop()
	if _is_talking:
		graphic.play_animation("talk")
	else:
		graphic.play_animation("idle")
	_current_state = NPCState.IDLE

	if may_talk_when_idle && !_is_talking && randi() % 5 == 0:
		_default_talk()

	state_timer.wait_time = randf_range(.5, 3)
	state_timer.start()

func _default_talk():
	match kind:
		Kind.Believer:
			talk("dial_npc_believer_talk")
		Kind.BelieverFanatic:
			talk("dial_npc_fanatic_talk")
		Kind.Follower:
			talk("dial_npc_follower_talk")

func _transition_to_walk():
	state_timer.stop()
	graphic.play_animation("walk")
	_current_state = NPCState.WALK
	velocity = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * 2

	state_timer.wait_time = randf_range(1, 3)
	state_timer.start()

func _transition_to_pressed_walk():
	if _current_state != NPCState.PRESSED_WALK:
		state_timer.stop()

		match kind:
			Kind.Believer:
				talk("dial_npc_believer_touched")
			Kind.BelieverFanatic:
				talk("dial_npc_fanatic_touched")
			Kind.Follower:
				talk("dial_npc_follower_touched")

		graphic.play_animation("press_walk")
		_current_state = NPCState.PRESSED_WALK
		angle = randf_range(-360,360)
		velocity = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * 4
		#dies out of screen or start pressing again

func _transition_to_pressing():
	if _current_state != NPCState.PRESSING && _current_state != NPCState.DEAD && state_timer != null:
		state_timer.stop()

		if talks_when_pressed:
			match kind:
				Kind.Believer:
					talk("dial_npc_believer_pressing")
				Kind.BelieverFanatic:
					talk("dial_npc_fanatic_pressing")
				Kind.Follower:
					talk("dial_npc_follower_pressing")

		graphic.play_animation("press_idle")
		_current_state = NPCState.PRESSING
		#waits for finished pressing

func _transition_to_dead():
	if is_queued_for_deletion(): return
	if !_started:
		_current_state = NPCState.DEAD
		queue_free()
		return

	if _current_state != NPCState.DEAD:
		sfx_die.post_event();

		flow_player.kill_flow()
		_is_talking = false
		state_timer.stop()
		graphic.play_animation("hit")
		_current_state = NPCState.DEAD


		#disable physics
		$PressArea.queue_free()
		$HitArea.queue_free()

		#waits for animation end
		graphic.animation_finished.connect(queue_free)

func _on_state_timer_timeout():
	if is_queued_for_deletion(): return
	if _current_state in [NPCState.PRESSING, NPCState.PRESSED_WALK, NPCState.DEAD]:
		return

	state_timer.stop()
	if may_walk_when_idle && randi() % 3 == 0:
		_transition_to_walk()
	else:
		_transition_to_idle()

func _start_pressing(touchData):
	if is_queued_for_deletion(): return

	if _current_state != NPCState.DEAD:
		_transition_to_pressing()

func _end_pressing(touchData):
	if is_queued_for_deletion(): return

	if _current_state == NPCState.PRESSING:
		var tween = get_tree().create_tween()
		graphic.scale.y = 0.8
		tween.tween_property(graphic,"scale:y",1,0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		if back_to_idle_after_pressed:
			_transition_to_idle()
		else:
			_transition_to_pressed_walk()

func _on_health_dead(health:Health):
	if is_queued_for_deletion(): return
	_transition_to_dead()
