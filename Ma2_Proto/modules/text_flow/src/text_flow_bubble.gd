class_name TextFlowBubble
extends Control

@export_group("Design")
@export var _prepend:String

@export_category("Setup")
@export var _label:RichTextLabel
@export var _panel:Control
@export var _anim:Switch_Oning_Offing_AnimationPlayer
@export var _sfx_bubble:AkEvent3D

var min_char:float = 5
var max_char:float = 100
var min_char_width:float = 250
var max_char_width:float = 500
var actual_max_width:float = 450
var long_word_width_per_char:float = 18
var long_word_extra_space:float = 30

var bubble_speaker:TextFlowBubbleSpeaker
var text:String

var _finishing:bool = false

func start():
	if !bubble_speaker:
		return

	var default_font_size:int = _label.get_theme_font_size("normal_font_size")
	text = Accessibility.parse_bbcode(text, default_font_size)

	_label.text = _prepend+text

	var parsed_text:String = _label.get_parsed_text()
	var char_count:int = parsed_text.length()
	var split = parsed_text.split(" ")
	var max_split_length:int
	for current_split in split:
		var current_split_length = current_split.length()
		if current_split.length() > max_split_length:
			max_split_length = current_split.length()

	var lerp_value = inverse_lerp(min_char, max_char, char_count)
	_panel.custom_minimum_size.x = min(max(
		lerpf(min_char_width, max_char_width, lerp_value),
		max_split_length * long_word_width_per_char + long_word_extra_space
	), actual_max_width)*Accessibility.get_font_size_ratio()

	_update_position()
	visible = true

	if !Accessibility.tts_dialogue_speak(
		parsed_text,
		false,
		1,
		bubble_speaker.get_wwise_voice_pitch(),
		bubble_speaker.get_wwise_voice_type()
		):
		_play_sfx(char_count)
	bubble_speaker.bubble_started.emit()
	_anim.set_switch(true)

func finish():
	if bubble_speaker:
		bubble_speaker.bubble_finished.emit()
	if _finishing: return
	_finishing = true
	_anim.set_switch(false)
	await _anim.turned_off
	if !is_instance_valid(self): return #if destroyed while awaiting
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !is_instance_valid(bubble_speaker.followee):
		finish()
		return

	_update_position()
var _smoothed_pos:Vector2 = Vector2.ZERO
@export var anti_shake_threshold:float = 20.0  # pixels, ignore smaller shakes
@export var anti_shake_lerp:float = 0.5       # 0 = instant, 1 = max smoothing (for tiny shakes)

func _update_position():
	var pos:Vector3 = bubble_speaker.followee.global_transform.origin + bubble_speaker.offset
	_sfx_bubble.position = pos

	var screen_pos:Vector2 = get_viewport().get_camera_3d().unproject_position(pos)
	var viewport_rect:Rect2 = get_viewport_rect()
	var margin:float = 140

	# Initialize
	if _smoothed_pos == Vector2.ZERO:
		_smoothed_pos = screen_pos

	# Distance from previous
	var delta:float = screen_pos.distance_to(_smoothed_pos)

	if delta < anti_shake_threshold:
		# Only a tiny shake → smooth it out
		_smoothed_pos = _smoothed_pos.lerp(screen_pos, anti_shake_lerp)
	else:
		# Real movement → snap directly
		_smoothed_pos = screen_pos

	# Bubble size (bottom-center anchor → grows upward)
	var bubble_size:Vector2 = _panel.size
	var half_width:float = bubble_size.x * 0.5
	var bubble_height:float = bubble_size.y + 50

	var clamped_pos:Vector2 = _smoothed_pos

	# Only clamp if anchor is inside safe zone
	var safe_rect:Rect2 = Rect2(
		Vector2(margin, margin),
		viewport_rect.size - Vector2(margin * 2, margin * 2)
	)

	if safe_rect.has_point(_smoothed_pos):
		# Horizontal clamp
		if _smoothed_pos.x - half_width < 0:
			clamped_pos.x = half_width
		elif _smoothed_pos.x + half_width > viewport_rect.size.x:
			clamped_pos.x = viewport_rect.size.x - half_width

		# Vertical clamp (grows upward)
		var top_y:float = _smoothed_pos.y - bubble_height
		if top_y < 0:
			clamped_pos.y += -top_y
		if clamped_pos.y > viewport_rect.size.y:
			clamped_pos.y = viewport_rect.size.y

	position = clamped_pos

func _play_sfx(char_count:int):
	Wwise.set_rtpc_value_id(AK.GAME_PARAMETERS.CHR_TEXTLENGHT, char_count, _sfx_bubble)
	Wwise.set_rtpc_value_id(AK.GAME_PARAMETERS.CHR_VOICEPITCH, bubble_speaker.get_wwise_voice_pitch(), _sfx_bubble)
	Wwise.set_switch_id(AK.SWITCHES.NPC_VOICE.GROUP, bubble_speaker.get_wwise_voice(), _sfx_bubble)
	Wwise.set_switch_id(AK.SWITCHES.NPC_VOICE_TYPE.GROUP, bubble_speaker.get_wwise_voice_type(), _sfx_bubble)

	_sfx_bubble.post_event()
