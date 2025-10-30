class_name TextFlowPlayerZap
extends TextFlowPlayer

const SAVE_ZAP_POST_DIAL_PREVIOUS:StringName = &"ZAP.POST_DIAL.PREVIOUS"

signal close_pressed()
signal new_zap_finished(speaker:TextFlowZapSpeaker, message:String)

@export var _animation_app:Switch_Oning_Offing_AnimationPlayer
@export var _animation_zap:Switch_Oning_Offing_AnimationPlayer
@export var _animation_intercepting:Switch_Oning_Offing_AnimationPlayer

@export var _lvl_unlocked_tab_container:TabContainer

@export var zappers:Array[TextFlowZapSpeaker]
@export var basic_zap_scene:PackedScene
@export var system_zap_scene:PackedScene

@export var _zap_container:Control
@export var _scroll_container:ScrollContainer

@export var _group_description:RichTextLabel

@export var _speaker_info_panel:TextFlowZapSpeakerInfoPanel
@export var _group_info_panel:TextFlowZapGroupInfoPanel
@export var _group_info_button:Button

@export var _lvl_info_display:LevelInfoDisplay

var _post_dials:Dictionary[int, StringName] = {
	0 :  "zap_post_first",
	4 :  "zap_post_1",
	6 :  "zap_post_2",
	9 :  "zap_post_3",
	12 : "zap_post_final",
}

var _current_zap:TextFlowZap

var _previous_speaker:TextFlowZapSpeaker

var _unread_message_counter:int
var _unread_message_counting:bool

var _unread_message_zap:TextFlowZap

var _unlocked_messages:Array[StringName]
var _to_unlock_message:StringName

func start_flow(text_flow_id:StringName, loop:bool = false, start_skipping:bool = false, emit_started:bool = true, tags:String = ""):
	super.start_flow(text_flow_id, loop, start_skipping, emit_started, tags)
	_current_duration_max = 0
	_current_duration_min = 0
	_previous_speaker = null
	if start_skipping:
		_unread_message_counting = false
	else:
		_unread_message_counting = true
		_unread_message_counter = 0
		if is_instance_valid(_unread_message_zap):
			_unread_message_zap.queue_free()
		_unread_message_zap = system_zap_scene.instantiate() as TextFlowZap
		_zap_container.add_child(_unread_message_zap)

func _cmd_start() -> bool:
	var ret = super._cmd_start()
	if _current_cmd == FlowCMD.Delay && _unread_message_counting && is_instance_valid(_unread_message_zap):
		_unread_message_counting = false
		if _unread_message_counter == 0:
			_unread_message_zap.queue_free()
		elif _unread_message_counter == 1:
			_unread_message_zap.set_line("[b]"+tr("zap_system_message_singular"))
		else:
			_unread_message_zap.set_line("[b]"+tr("zap_system_messages_plural").format({"msg_count": _unread_message_counter}))
	return ret

func show_group_info():
	_group_info_panel.open()

func _ready():
	super._ready()
	for zapper in zappers:
		set_speaker(zapper, zapper.id)
		_group_info_panel.add_speaker(zapper)
	for child in _zap_container.get_children(): child.queue_free()
	_group_info_panel.speaker_clicked.connect(_speaker_info_panel.show_speaker)
	_group_info_button.pressed.connect(show_group_info)

func _line_start() -> bool:
	if _current_cmd_param.is_empty(): return false

	var speaker_id:StringName = get_current_speaker_id()
	var zap_speaker:TextFlowZapSpeaker

	if _speakers.has(speaker_id):
		zap_speaker = get_current_speaker() as TextFlowZapSpeaker
	elif !speaker_id || speaker_id == "system":
		var sys = system_zap_scene.instantiate() as TextFlowZap
		sys.set_line(_current_cmd_param)
		_zap_container.add_child(sys)
		_previous_speaker = null
		return false

	var ret = super._line_start()

	_current_zap = basic_zap_scene.instantiate()
	_zap_container.add_child(_current_zap)

	_current_zap.portrait_clicked.connect(_speaker_info_panel.show_speaker)

	if _previous_speaker != null && _previous_speaker == zap_speaker:
		_current_zap.set_speaker(null)
	elif zap_speaker:
		_current_zap.set_speaker(zap_speaker)
	else:
		_current_zap.set_speaker_name(speaker_id)

	_previous_speaker = zap_speaker

	if _current_duration_max <= 0:
		_current_zap.set_line(_current_cmd_param)
	else:
		_current_zap.hide()

		if zap_speaker:
			var speaker_text:String = "[b][color={speaker_color}]{speaker_name}[/color][/b]".format({
				"speaker_name": tr(zap_speaker.name),
				"speaker_color" : zap_speaker.color.to_html()
				})
			var description_text:String = tr("zap_ui_group_details_typing").format({
				"speaker": speaker_text
			})
			_group_description.text = "[pulse freq=1 ease=10.0]" + description_text

	go_to_end(true)

	if _unread_message_counting:
		_unread_message_counter += 1

	return ret

func _line_finish():
	if is_instance_valid(_current_zap):
		if _current_duration_max > 0:
			_current_zap.show()
			_current_zap.set_line(_current_cmd_param)
			_current_zap.animate(TextFlowZap.AnimationStyle.Basic)
			new_zap_finished.emit(_previous_speaker as TextFlowZapSpeaker, _current_cmd_param)

			_group_description.text = "zap_ui_group_details_callout"

	super._line_finish()

	go_to_end(true)

func is_at_end() -> bool:
	var v_scroll = _scroll_container.get_v_scroll_bar()
	return v_scroll && v_scroll.visible && (v_scroll.value > v_scroll.max_value - v_scroll.page*1.5)

func go_to_end(delayed:bool = false):
	if delayed:
		await get_tree().process_frame

	if is_instance_valid(_scroll_container):
		_scroll_container.scroll_vertical = 1000000

func _on_back_button_pressed() -> void:
	close_pressed.emit()

func has_incoming_message() -> bool:
	return !_to_unlock_message.is_empty()

func zap_set_levels(sequence_levels:Array[LevelInfo], current_lvl:LevelInfo):
	for lvl in sequence_levels:
		if lvl != current_lvl:
			_unlocked_messages.append(lvl.dial_zap)
		else:
			if lvl.is_unlocked():
				_unlocked_messages.append(lvl.dial_zap)
			else:
				_to_unlock_message = lvl.dial_zap
			break

	if current_lvl.is_arcade_mode: # finished all levels, ready for post zap messages!
		var post_dial_previous:int = Ma2MetaManager.get_quick_int(SAVE_ZAP_POST_DIAL_PREVIOUS, -1)
		var star_options = _post_dials.keys()
		star_options.sort()
		for needed_stars in star_options:
			var message = _post_dials[needed_stars]
			if post_dial_previous < needed_stars:
				if Ma2MetaManager.get_unlocked_stars_count() >= needed_stars:
					_to_unlock_message = message
					Ma2MetaManager.set_quick_int(SAVE_ZAP_POST_DIAL_PREVIOUS, needed_stars)
					post_dial_previous = needed_stars
				break
			else:
				_unlocked_messages.append(message)

	_lvl_info_display.set_level(current_lvl)

func zap_show():
	show()
	set_process(true)

	_animation_app.set_switch(true)
	await _animation_app.turned_on

	for message in _unlocked_messages:
		queue_flow(message, false, true)

	_lvl_unlocked_tab_container.use_hidden_tabs_for_min_size = false

	if _to_unlock_message:
		_lvl_unlocked_tab_container.current_tab = 1
	else:
		_lvl_unlocked_tab_container.current_tab = 0

	_animation_zap.set_switch(true)
	await _animation_zap.turned_on

	if _to_unlock_message:
		queue_flow(_to_unlock_message, false, false)
		_unlocked_messages.append(_to_unlock_message)
		_to_unlock_message = ""
		_lvl_unlocked_tab_container.current_tab = 1
		_animation_intercepting.set_switch(true)
		await flow_finished
		_animation_intercepting.set_switch(false)

	_lvl_unlocked_tab_container.current_tab = 0

	await close_pressed

	_animation_zap.set_switch(false)
	await _animation_zap.turned_off

	_animation_app.set_switch(false)
	await _animation_app.turned_off

	hide()

	for child in _zap_container.get_children():
		child.queue_free()
