class_name HUBLevel extends Level

const LVL_INFO_LOAD = preload("res://elements/levels/lvl_info_load.tres")

const WEAPON_HOLD_TOUCH_ONLY = preload("res://elements/player/weapons/weapon_hold_touch_only.tscn")

const ICON_PLAY = preload("res://elements/icons/icon_play.png")
const ICON_LOCKED = preload("res://elements/icons/icon_locked.png")

signal level_selected(selected:LevelInfo)
signal upgrade_set_selected(selected:UpgradeSet)
signal upgrade_index_selected(selected:int)
signal upgrade_set_button_connected()
signal upgrading_stats_updated(start:int, end:int, current:int)

static var instance:HUBLevel

@export var _tutorial:Tutorial

@export var _play_level_transition_scene:PackedScene
@export var _back_to_load_transition_scene:PackedScene

@export var _info_panel:HUBInfoPanel
@export var _lanes_system:HUBLanesSystem
@export var _first_level_button:HUBLevelPressableButton

@export var _play_button_altar:Graphic_Altar
@export var _play_button_scene:PackedScene
@export var _level_map_coordinate_display:Node3D
@export var _main_npc:HUBNpc
@export var _mobile_phone_pressable:Pressable
@export var _hub_mobile:HUBMobilePhone

@export var _hub_welcome_container:Node3D
@export var _hub_welcome_scene:PackedScene
var _hub_welcome:HUBWelcome

@export_category("Levels Setup")
@export var _zap_levels:Array[LevelInfo]
@export var _arcade_level:LevelInfo

var selected_level:LevelInfo
var _current_level:LevelInfo
var _previous_level:LevelInfo

var _selected_upgrade_index:int
var _selected_upgrade_set:UpgradeSet

var _play_holdable_button:Holdable

var _button_return_to_load:Button

var _controls_locked:bool = true

func update_tutorial():
	if _controls_locked || get_has_previous_level() || _lanes_system.get_lane_tab() != 0:
		_tutorial.stop_tutorial()
		return

	if _hub_mobile.is_ringing():
		_tutorial.play_tutorial_target(_hub_mobile)
	elif selected_level != null:
		_tutorial.play_tutorial_target(_play_holdable_button.button_graphic, 1.3, -90)
	else:
		_tutorial.play_tutorial_target(_first_level_button.graphic, 1, 30)

func hide_phone():
	_hub_mobile.hide()

func show_phone():
	_hub_mobile.show()

func start_phone_ringing():
	_hub_mobile.start_ringing()
	update_tutorial()

func stop_phone_ringing():
	_hub_mobile.stop_ringing()
	update_tutorial()

func lock_controls():
	_controls_locked = true
	_lanes_system.set_locked(true)
	select_level(null)
	_info_panel.panel_hide()
	update_tutorial()

func unlock_controls():
	_controls_locked = false
	_lanes_system.set_locked(false)
	_info_panel.panel_show()
	update_tutorial()

func set_hub_play():
	_lanes_system.set_lane_tab(0)
	if is_instance_valid(_hub_welcome): _hub_welcome.set_to_destroy()

func set_hub_stars():
	_lanes_system.set_lane_tab(1)
	if is_instance_valid(_hub_welcome): _hub_welcome.set_to_destroy()

func set_hub_welcome():
	prepare_hub_welcome()
	_lanes_system.set_lane_tab(2)

func prepare_hub_welcome():
	if !is_instance_valid(_hub_welcome):
		_hub_welcome = _hub_welcome_scene.instantiate()
		_hub_welcome_container.add_child(_hub_welcome)
		_hub_welcome.set_npc_max_count(_current_level.church_npc_max_count)
	else:
		_hub_welcome.cancel_destroy()

func get_has_shown_intro() -> bool:
	return Ma2MetaManager.get_quick_bool("HUB.INTRO_SHOWN")

func set_has_shown_intro(val:bool = true):
	Ma2MetaManager.set_quick_bool("HUB.INTRO_SHOWN", true)

func get_has_previous_level() -> bool:
	return _previous_level != null

func get_is_current_level_unlocked() -> bool:
	return _current_level.is_unlocked()

func _on_lane_set(index:int):
	if index == 0:
		_on_hub_play_set()
	elif index == 1:
		_on_hub_star_set()
	else:
		_info_panel.panel_hide()
	update_tutorial()

func _on_hub_play_set():
	_info_panel.show_level_info()
	if !_current_level.is_unlocked():
		if !_current_level.is_arcade_mode:
			if is_instance_valid(_main_npc):
				_main_npc.set_basic_talk(_current_level.dial_hub_pre_unlock)
		else:
			_current_level.set_unlocked()
			if is_instance_valid(_main_npc):
				_main_npc.set_basic_talk(_current_level.dial_hub_pos_unlock)
	else:
		if is_instance_valid(_main_npc):
			_main_npc.set_basic_talk(_current_level.dial_hub_pos_unlock)

	if _hub_mobile._zap_player.has_incoming_message():
		start_phone_ringing()

func _on_hub_star_set():
	var unlock_stage = Ma2MetaManager.get_upgrade_unlock_stage()
	if unlock_stage == 0:
		if is_instance_valid(_main_npc):
			_main_npc.set_basic_talk(_current_level.dial_hub_stars_locked)
	elif unlock_stage < 10:
		if is_instance_valid(_main_npc):
			_main_npc.set_basic_talk(_current_level.dial_hub_stars_unlocked_first)
	else:
		if is_instance_valid(_main_npc):
			_main_npc.set_basic_talk(_current_level.dial_hub_stars_unlocked_full)

	_info_panel.show_stars_info()

func _on_hub_zap_finished():
	set_hub_play()
	if !_current_level.is_unlocked():
		stop_phone_ringing()
		_current_level.set_unlocked()
		if is_instance_valid(_main_npc):
			_main_npc.set_basic_talk(_current_level.dial_hub_pos_unlock)
	select_level(_current_level)
	update_tutorial()

func cmd_npc_speak(dialogue:String, main:bool = true, waits_if_main = true) -> CMD:
	if !is_instance_valid(_main_npc) || _main_npc.is_queued_for_deletion(): return CMD_Nop.new()

	if main:
		if waits_if_main:
			return CMD_Await_AsyncCallable.new(_main_npc.do_main_talk.bind(dialogue), self)
		else:
			return CMD_Callable.new(_main_npc.do_main_talk.bind(dialogue))
	else:
		return CMD_Callable.new(_main_npc.set_basic_talk.bind(dialogue))

func fetch_current_and_previous_levels():
	_current_level = null
	_previous_level = null
	var current_found:bool = false
	var i = _zap_levels.size()
	while i > 0:
		i -= 1
		var lvl:LevelInfo = _zap_levels[i]

	 	#In normal conditions it should be unlocked if complete!
		#But we make sure for dev purposes
		if lvl.is_complete() || current_found:
			lvl.set_unlocked()
			lvl.set_complete()

		if !current_found:
			if !lvl.is_unlocked():
				_current_level = lvl
			else:
				current_found = true
				if lvl.is_complete():
					_previous_level = lvl
				else:
					_current_level = lvl
					if i > 0:
						_previous_level = _zap_levels[i-1]

	#for lvl in _zap_levels:
		#if !lvl.is_complete():
			#_current_level = lvl
			#break
		#else:
		 	##In normal conditions it should be unlocked if complete!
			##But we make sure for dev purposes
			#if !lvl.is_unlocked():
				#lvl.set_unlocked()
			#_previous_level = lvl
	if _previous_level:
		_previous_level.set_unlocked()

	if !_current_level:
		_current_level = _arcade_level

func add_time_manager_control():
	TimeManager.add_control_requester(self)

func remove_time_manager_control():
	TimeManager.remove_control_requester(self)

func prepare_level():
	cam.set_offset(Vector3(0,26,13))
	#cam.set_instant_position(Vector3(0,0,10))
	var wpn = WEAPON_HOLD_TOUCH_ONLY.instantiate()
	add_child(wpn)
	Player.instance.add_weapon(wpn)

	var should_set_hub_welcome = false

	#=== PREPARE
	hide_phone()
	lock_controls()
	fetch_current_and_previous_levels()
	_hub_mobile._zap_player.zap_set_levels(_zap_levels, _current_level)

	if _current_level.npc_mode == LevelInfo.NPCMode.Fanatic:
		_main_npc.set_fanatic()
	elif _current_level.npc_mode == LevelInfo.NPCMode.Dead:
		_main_npc.queue_free()
	_info_panel.show_level_info()

	#=== RECEPTION
	var reception_endgame:bool = _current_level.is_arcade_mode && !_current_level.is_unlocked()
	var reception_victory:bool = !reception_endgame && get_has_previous_level() && !get_is_current_level_unlocked()
	var reception_intro:bool = !get_has_shown_intro() && !get_has_previous_level()
	var reception_welcome:bool = !reception_intro && !reception_victory && !reception_endgame

	if reception_intro:
		should_set_hub_welcome = true
		cmd(
			CMD_Sequence.new([
				CMD_Callable.new(add_time_manager_control),
				cmd_npc_speak("dial_hub_intro_1"),
				cmd_npc_speak("dial_hub_intro_2"),
				cmd_npc_speak("dial_hub_intro_3"),
				cmd_npc_speak("dial_hub_intro_4"),
				CMD_Callable.new(set_has_shown_intro),
				CMD_Callable.new(remove_time_manager_control),
				CMD_Callable.new(func():
					SocialPlatformManager.unlock_achievement(SocialPlatformManager.Achievement.ACH_START)
					)
				]
			), false
		)

	if reception_victory:
		should_set_hub_welcome = true
		var seq:Array[Level.CMD] = []
		seq.append(CMD_Callable.new(add_time_manager_control))
		if !_previous_level.dial_hub_win.is_empty():
			seq.append(cmd_npc_speak(_previous_level.dial_hub_win))
		for val in _previous_level.dial_hub_win_array:
			seq.append(cmd_npc_speak(val))
		seq.append(CMD_Callable.new(remove_time_manager_control))
		cmd(CMD_Sequence.new(seq, false))

	if reception_welcome:
		cmd(cmd_npc_speak(_current_level.dial_hub_welcome, true, false), false)

	if reception_endgame:
		should_set_hub_welcome = true
		prepare_hub_welcome()
		cmd(
			CMD_Sequence.new([
				CMD_Callable.new(func():
					_hub_welcome.letter.show_letter()
					),
				CMD_Wait_Signal.new(_hub_welcome.letter.letter_closed),
				CMD_Callable.new(func():
					SocialPlatformManager.unlock_achievement(SocialPlatformManager.Achievement.ACH_ENDING)
					)
				]
			), false
		)

	#=== TUTORIALS
	var tutorials_cmd:Array[CMD]
	# for each tutorial
		#if should show tutorial:
		#tutorials_cmd.append(tutorial_cmd)
	if tutorials_cmd.size() > 0:
		should_set_hub_welcome = true
		cmd_array(tutorials_cmd)

	#=== UNLOCK INTERACTIONS
	cmd_array([
		CMD_Wait_Seconds.new(1 if reception_welcome else 0),
		CMD_Callable.new(HUDCoins.instance.add_hud_request.bind(self)),
		CMD_Callable.new(show_phone),
		CMD_Callable.new(unlock_controls),
		CMD_Wait_Seconds.new(0.5),
		CMD_Callable.new(set_hub_play),
		CMD_Callable.new(HUDCoins.instance.remove_hud_request.bind(self)),
		], false)

	#IMEDIATELY
	if should_set_hub_welcome:
		set_hub_welcome()
	else:
		set_hub_play()

	#(this is added in FORNT so there's time for scene preparation )
	cmd_array([
		#cam.cmd_position_vector_wait(Vector3.ZERO, 1),
		CMD_Wait_Seconds.new(2),
		])

func _enter_tree() -> void:
	instance = self
	super._enter_tree()

func _ready() -> void:
	instance = self

	prepare_level()

	_play_holdable_button = _play_button_scene.instantiate()
	_play_button_altar.get_instantiate_place().add_child(_play_holdable_button)

	await get_tree().process_frame

	AudioManager.post_music_event(AK.EVENTS.MUSIC_HUB_START)
	Menu.set_info("", "")

	_button_return_to_load = UIFactory.get_button()
	_button_return_to_load.text = "menu_back_to_load"
	_button_return_to_load.theme_type_variation = "button_magenta_main"
	_button_return_to_load.pressed.connect(
		func():
			Menu.unpause()
			LevelManager.change_with_transition(_back_to_load_transition_scene, LVL_INFO_LOAD)
	)
	Menu.add_element(_button_return_to_load)

	_play_holdable_button.button_hold_finished.connect(_on_play_button_hold_finished)

	if is_instance_valid(_main_npc):
		_main_npc.pressed.connect(_on_npc_pressed)

	_mobile_phone_pressable.pressed.connect(_on_hub_mobile_pressed)
	_hub_mobile.zap_finished.connect(_on_hub_zap_finished)
	_lanes_system.lane_set_finished.connect(_on_lane_set)

func _on_npc_pressed():
	_on_hub_mobile_pressed()

func _on_hub_mobile_pressed():
	if(!_controls_locked && _hub_mobile.visible && !_hub_mobile.is_on()):
		lock_controls()
		if is_instance_valid(_main_npc):
			_main_npc.disable_talk()
		HUDCoins.instance.add_force_hide_request(self)
		await _hub_mobile.show_zap()
		HUDCoins.instance.remove_force_hide_request(self)
		if is_instance_valid(_main_npc):
			_main_npc.enable_talk()
		unlock_controls()

		update_tutorial()

func _exit_tree() -> void:
	super._exit_tree()

	if _button_return_to_load: _button_return_to_load.queue_free()
	AudioManager.post_music_event(AK.EVENTS.MUSIC_HUB_END)
	remove_time_manager_control()

func select_level(level_info:LevelInfo):
	if level_info && !level_info.is_unlocked():
		if _level_ready && is_instance_valid(_main_npc):
			_main_npc.do_main_talk(_current_level.dial_hub_lvl_still_locked)
	elif level_info && level_info.is_unlocked():
		selected_level = level_info

		_play_button_altar.set_open(true)
		_play_holdable_button.button_graphic.set_colors(level_info.lvl_color, level_info.lvl_color_highlight)

		_level_map_coordinate_display.visible = selected_level.map_scale > 0

		var t := _level_map_coordinate_display.create_tween()
		t.set_ease(Tween.EASE_IN_OUT)
		t.set_trans(Tween.TRANS_SINE)
		t.tween_property(
			_level_map_coordinate_display, "position", selected_level.map_coordinate, .3
		)
		t.set_parallel()
		t.tween_property(
			_level_map_coordinate_display, "scale", Vector3(selected_level.map_scale, 1, selected_level.map_scale), 0.35
		)
	else:
		_play_button_altar.set_open(false)
		selected_level = null
		_level_map_coordinate_display.position = Vector3.ZERO
		_level_map_coordinate_display.scale = Vector3(7, 1, 7)
		_level_map_coordinate_display.visible = false

	_info_panel.set_level_info(selected_level)

	level_selected.emit(selected_level)
	update_tutorial()

func get_selected_upgrade_set() -> UpgradeSet:
	return _selected_upgrade_set

func get_selected_upgrade_info() -> UpgradeInfo:
	var upset = get_selected_upgrade_set()
	if upset:
		return upset.get_upgrade(get_selected_upgrade_info_index())
	return null

func get_selected_upgrade_info_index() -> int:
	return _selected_upgrade_index

func deselect_upgrade_index():
	select_upgrade_index(-1)

func select_upgrade_index(index:int):
	if _selected_upgrade_index == index:
		return

	_selected_upgrade_index = index
	upgrade_index_selected.emit(index)

	var info = get_selected_upgrade_info()
	if info && is_instance_valid(_main_npc):
		_main_npc.do_main_talk(info.upgrade_description)

func set_upgrading_stats(start:int, end:int, current:int):
	upgrading_stats_updated.emit(start, end, current)

func deselect_upgrade_set():
	select_upgrade_set(null)

func select_upgrade_set(upgrade_set:UpgradeSet):
	if _selected_upgrade_set == upgrade_set:
		return

	_selected_upgrade_set = upgrade_set
	deselect_upgrade_index()
	upgrade_set_selected.emit(upgrade_set)

func _on_play_button_hold_finished():
	if selected_level:

		var test_info = DevManager.test_info
		if test_info && test_info.is_hard_locked_level(selected_level):
			PromptWindow.new_prompt(test_info.hard_lock_title, test_info.hard_lock_message)
			return

		LevelManager.change_with_transition(_play_level_transition_scene, selected_level)
