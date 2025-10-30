class_name HUBNpc extends Pressable

const DIALOGUE_BACK_TO_MAIN:String = "dial_hub_back_to_speech"
const DIALOGUE_PRESSING_IS_MAIN:String = "dial_hub_pressing_has_speech"
const DIALOGUE_PRESSING_NOT_MAIN:String = "dial_hub_pressing_not_speech"

@export_category("Dialogue")
@export var _flow_offset: Marker3D

@export var _main_flow_player: TextFlowPlayerBubbles
@export var _extra_flow_player: TextFlowPlayerBubbles

@export_category("Graphic")
@export var _graphic: Node3D
@export var _sprites_animation:AnimatedSprite3D
@export var _normal_frames:SpriteFrames
@export var _fanatic_frames:SpriteFrames

var _speaker:TextFlowBubbleSpeaker

var _current_main_talk:String
var _currennt_basic_talk:String = ""
var _is_backing_to_main_talking:bool = false

var _is_talk_disabled:bool = false

func get_is_main_talking() -> bool:
	return !_current_main_talk.is_empty()

func disable_talk():
	_is_talk_disabled = true
	_main_flow_player.kill_flow()
	_extra_flow_player.kill_flow()

func enable_talk():
	_is_talk_disabled = false
	_reset_to_desired_state()

func set_basic_talk(dialogue:String):
	_currennt_basic_talk = dialogue

	if get_is_main_talking(): return
	if is_pressed: return
	if _is_backing_to_main_talking: return
	if _is_talk_disabled: return

	if _currennt_basic_talk.is_empty():
		_main_flow_player.kill_flow()
	else:
		_main_flow_player.start_flow(_currennt_basic_talk, true)

func do_main_talk(dialogue:String):
	if dialogue.is_empty():
		push_warning("Main Talking nothing!")
		return

	if get_is_main_talking():
		_main_flow_player.kill_flow(true)

	_current_main_talk = dialogue

	if _is_talk_disabled: return

	_extra_flow_player.kill_flow()
	_main_flow_player.start_flow(_current_main_talk)

	await _main_flow_player.flow_finished
	if !is_instance_valid(self): return

	_current_main_talk = ""

	_reset_to_desired_state()

func set_fanatic() -> void:
	_sprites_animation.sprite_frames = _fanatic_frames
	get_speaker().voice = TextFlowBubbleSpeaker.SpeakerVoice.FanaticPriest

func _ready() -> void:
	super._ready()

	if is_queued_for_deletion(): return
	_main_flow_player.set_speaker(get_speaker())
	_extra_flow_player.set_speaker(get_speaker())

func get_speaker() -> TextFlowBubbleSpeaker:
	if _speaker:
		return _speaker

	_speaker = TextFlowBubbleSpeaker.new(_flow_offset, Vector3.ZERO, TextFlowBubbleSpeaker.SpeakerVoice.Priest)
	_speaker.bubble_finished.connect(_on_bubble_finished)
	_speaker.bubble_started.connect(_on_bubble_started)

	return _speaker

func _talk_back_to_main_talk():
	if _is_talk_disabled: return
	if _is_backing_to_main_talking: return

	if !get_is_main_talking():
		push_error("Why getting back to main talk, if it wasn't main talking?")
		return

	_is_backing_to_main_talking = true
	_main_flow_player.kill_flow()
	_extra_flow_player.set_current_speaker(_main_flow_player.get_current_speaker_id())
	_extra_flow_player.start_flow(DIALOGUE_BACK_TO_MAIN)

	await _extra_flow_player.flow_finished
	if !is_instance_valid(self): return

	_is_backing_to_main_talking = false
	_reset_to_desired_state()

func _reset_to_desired_state():
	_extra_flow_player.set_current_speaker(_main_flow_player.get_current_speaker_id())
	if _is_talk_disabled:
		_main_flow_player.kill_flow()
		_extra_flow_player.kill_flow()
	elif is_pressed:
		_start_pressing_dialogue()
	elif _is_backing_to_main_talking:
		_extra_flow_player.start_flow(DIALOGUE_BACK_TO_MAIN)
	elif get_is_main_talking():
		_main_flow_player.start_flow(_current_main_talk)
	elif !_currennt_basic_talk.is_empty():
		_main_flow_player.start_flow(_currennt_basic_talk, true)

func _start_pressing_dialogue():
	_main_flow_player.kill_flow()
	_extra_flow_player.set_current_speaker(_main_flow_player.get_current_speaker_id())
	if get_is_main_talking():
		_extra_flow_player.start_flow(DIALOGUE_PRESSING_IS_MAIN, true)
	else:
		_extra_flow_player.start_flow(DIALOGUE_PRESSING_NOT_MAIN, true)

func _start_pressing(touchData):
	if is_queued_for_deletion(): return

	_sprites_animation.play("press_idle")

	if _is_backing_to_main_talking: return
	if _is_talk_disabled: return
	if _main_flow_player.get_current_speaker() != get_speaker(): return

	_start_pressing_dialogue()

func _end_pressing(touchData):
	if is_queued_for_deletion(): return

	_sprites_animation.play("idle")
	var tween = create_tween()
	_graphic.scale.y = 0.8
	tween.tween_property(_graphic,"scale:y",1,0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	if _main_flow_player.get_current_speaker() != get_speaker(): return
	if get_is_main_talking():
		_talk_back_to_main_talk()
	else:
		_reset_to_desired_state()

func _on_bubble_finished():
	if !is_pressed:
		_sprites_animation.play("idle")

func _on_bubble_started():
	if !is_pressed:
		_sprites_animation.play("talk")
