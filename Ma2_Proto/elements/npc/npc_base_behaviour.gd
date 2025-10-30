class_name NPC_Basic extends LHH3D

@export var graphic:Graphic_NPC;
@onready var flow_player: TextFlowPlayerBubbles = $TextFlowPlayerBubbles
@export var flow_offset:Node3D;


var target_pos:Vector3;
var has_target:bool = false;
var velocity:Vector3;
@export var max_velocity:float = 5;
@export var control_animation:bool = true;

var _old_pos:Vector3;

var cheering_time:float;
var pressed_count:int;
var dead:bool;

signal start_walk;
signal end_walk;
signal start_talk;
signal end_talk;
signal begin_dialogue;
signal pressed;
signal unpressed;

var is_walking:bool:
	get:
		return velocity.length_squared() > 0.0001;

var is_cheering:bool:
	get:
		return cheering_time > 0;


var is_pressed:bool:
	get:
		return pressed_count > 0;


var is_talking:bool:
	get:
		return is_talking;
	set(value):
		is_talking = value;

func _process(delta: float) -> void:
	## Check walking state
	var was_walking:bool = is_walking;
	var pos_now:Vector3 = global_position;
	velocity = pos_now - _old_pos;
	_old_pos = pos_now;
	if was_walking != is_walking:
		if is_talking:
			start_walk.emit();
		else:
			end_talk.emit();

	## Walk to target
	if has_target:
		var pos_then:Vector3 = pos_now.move_toward(target_pos, delta * max_velocity);
		velocity += (pos_then - pos_now);
		global_position = pos_then;
		_old_pos = pos_then;

	_solve_animation(delta);

	cheering_time -= delta;

func _solve_animation(delta:float):
	if not control_animation or dead:
		return;

	if is_walking:
		_anim_walk();
	else:
		if is_talking:
			_anim_talk();
		elif is_cheering:
			_anim_talk();
		else:
			_anim_idle();

func _anim_walk():
	if is_pressed:
		graphic.set_animation_npc(Graphic_NPC.NPCAnimation.Press_Walk);
	else:
		graphic.set_animation_npc(Graphic_NPC.NPCAnimation.Walk);

func _anim_idle():
	if is_pressed:
		graphic.set_animation_npc(Graphic_NPC.NPCAnimation.Press_Idle);
	else:
		graphic.set_animation_npc(Graphic_NPC.NPCAnimation.Idle);

func _anim_talk():
	if is_pressed:
		graphic.set_animation_npc(Graphic_NPC.NPCAnimation.Press_Idle);
	else:
		graphic.set_animation_npc(Graphic_NPC.NPCAnimation.Talk);

func walk_to(pos:Vector3):
	target_pos = pos;
	has_target = true;

func teleport_to(pos:Vector3):
	target_pos = pos;
	_old_pos = pos;
	global_position = pos;
	has_target = false;

func talk(dialogue:String, loop:bool = false):
	flow_player.start_flow(dialogue, loop);
	begin_dialogue.emit();

var _speaker:TextFlowBubbleSpeaker;
func get_speaker() -> TextFlowBubbleSpeaker:
	if _speaker:
		return _speaker

	_speaker = TextFlowBubbleSpeaker.new(flow_offset)
	_speaker.bubble_started.connect(_on_bubble_started)
	_speaker.bubble_finished.connect(_on_bubble_finished)
	_speaker.voice_based_on_graphic = graphic.randomize_sprite_frames

	return _speaker


func _on_bubble_finished():
	is_talking = false
	end_talk.emit();

func _on_bubble_started():
	is_talking = true
	start_talk.emit()


func cheer(time:float):
	cheering_time = time;

func change_press(add:int):
	if add > 0:
		if not is_pressed and (pressed_count + add) > 0:
			pressed.emit();
	elif add < 0:
		if is_pressed and (pressed_count + add) <= 0:
			unpressed.emit();
	pressed_count += add;

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	queue_free();

func _on_health_dead(health: Health) -> void:
	dead = true;
	graphic.set_animation_npc(Graphic_NPC.NPCAnimation.Hit)
	graphic.animation_finished.connect(queue_free, CONNECT_ONE_SHOT);


func _on_press_area_body_entered(body: Node3D) -> void:
	change_press(1);

func _on_press_area_body_exited(body: Node3D) -> void:
	change_press(-1);
