class_name PauseMenu extends MenuAggregator

const HC_THEME = preload("res://elements/ui/themes/menu/hc_theme.tres")
const MENU_THEME = preload("res://elements/ui/themes/menu/menu_theme.tres")

const ICON_SETTINGS = preload("res://elements/icons/icon_settings.png")
const ICON_PAUSE = preload("res://elements/icons/icon_pause.png")
const ICON_CLOSE = preload("res://elements/icons/icon_close.png")
const ICON_SCORE = preload("res://elements/icons/icon_score.png")
const ICON_STAR = preload("res://elements/icons/icon_star.png")

@export var sfx_player:AkEvent3DLoop
@export var animation_player:Switch_Oning_Offing_AnimationPlayer

@export var _menu_openclose_texture:TextureRect
@export var _menu_openclose_button:ExtendedButton
@export var _tab_animation_player:Switch_Oning_Offing_AnimationPlayer
@export var _level_info_display:LevelInfoDisplay
@export var _tab_container:TabContainer
@export var _tab_buttons_container:Control
@export var _save_icon_control:Control
@export var _save_number_label:Label

var _tab_button_group:ButtonGroup
var _tab_buttons:Array[Button]
var _opened_time_usec:int

var _social_aggregator:MenuAggregator

func _on_high_contrast_controller_enabled_changed():
	if Accessibility.high_contrast_controller.get_enabled():
		print("[PAUSE MENU] Will set HIGH CONTRAST THEME")
		theme = HC_THEME
	else:
		print("[PAUSE MENU] Will set DEFAULT MENU THEME")
		theme = MENU_THEME

func _ready() -> void:
	set_info("","")

	LevelManager.transition_started.connect(hide)
	LevelManager.transition_ended.connect(unpause.bind(true))

	var ag = get_aggregator(["General"])
	ag.set_info("menu_options_title", "menu_options_text", 1000, ICON_SETTINGS)
	visible = false
	animation_player.set_switch(false)

	while !Accessibility.high_contrast_controller:
		await get_tree().process_frame

	Accessibility.high_contrast_controller.enabled_changed.connect(_on_high_contrast_controller_enabled_changed)
	_on_high_contrast_controller_enabled_changed()

func is_paused() -> bool:
	return get_tree().paused

func pause():
	if is_paused(): return

	TimeManager.set_game_paused()

	update_social_menu()

	_opened_time_usec = Time.get_ticks_usec()
	_menu_openclose_texture.texture = ICON_CLOSE
	_menu_openclose_button._tts_custom_hover_text = "tts_button_menu_close"
	animation_player.set_switch(true)
	get_tree().paused = true
	_tab_buttons[0].button_pressed = true
	_level_info_display.set_level(LevelManager.current_level_info)

	var save:int = Ma2MetaManager.get_slot_number()
	_save_number_label.text = TextServerManager.get_primary_interface().format_number(str(save))
	_tab_buttons_container.size_flags_vertical = Control.SIZE_SHRINK_END
	sfx_player.start_loop()
	AudioManager.post_one_shot_event(AK.EVENTS.PLAY_UI_PAUSE_OPEN)


func unpause(instant = false):
	if !is_paused() && !instant: return

	TimeManager.set_game_unpaused()

	_menu_openclose_texture.texture = ICON_PAUSE
	_menu_openclose_button._tts_custom_hover_text = "tts_button_menu_open"
	if instant:
		animation_player.set_switch_immediate(false)
	else:
		animation_player.set_switch(false)
	await get_tree().process_frame
	get_tree().paused = false
	visible = true
	sfx_player.stop_loop()
	if !instant:
		AudioManager.post_one_shot_event(AK.EVENTS.PLAY_UI_PAUSE_CLOSE)

func update_social_menu():
	var integrations_ui:bool = (
		DevManager.get_setting(DevManager.SETTING_INTEGRATIONS_UI_ENABLED)
		or
		SocialPlatformManager.is_authenticated()
		)

	if _social_aggregator && !integrations_ui:
		_social_aggregator.queue_free()
	elif !_social_aggregator && integrations_ui:
		_social_aggregator = get_aggregator(["General","Social"])
		_social_aggregator.set_info("","")
		var social_buttons = HBoxContainer.new()
		social_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		social_buttons.add_child(
			UIFactory.get_button(
				SocialPlatformManager.get_leaderboards_text(),
				SocialPlatformManager.show_all_leaderboards,
				false,
				SocialPlatformManager.get_leaderboards_icon()
				)
		)
		social_buttons.add_child(
			UIFactory.get_button(
				SocialPlatformManager.get_achievements_text(),
				SocialPlatformManager.show_all_achievements,
				false,
				SocialPlatformManager.get_achievements_icon()
				)
		)
		_social_aggregator.add_element(social_buttons,-1)

func show_save_number():
	_save_icon_control.visible = true

func hide_save_number():
	_save_icon_control.visible = false

func toggle():
	if is_paused(): unpause()
	else: pause()

func on_toggle_button_pressed():
	if is_paused():
		AudioManager.post_one_shot_event(AK.EVENTS.PLAY_UI_BUTTON_BACK)
	else:
		AudioManager.post_one_shot_event(AK.EVENTS.PLAY_UI_BUTTON_PRESSED)
	toggle()

func go_to_aggregator(ag_id:StringName):
	var ag = get_aggregator([ag_id])
	if ag:
		if !is_paused():
			pause()

		for button in _tab_buttons:
			var idx:int = button.get_index()
			if idx < _tab_container.get_tab_count():
				var control:Control = _tab_container.get_tab_control(idx)
				if control == ag:
					button.button_pressed = true

func _tab_button_pressed(button:Button):
	_tab_container.current_tab = button.get_index()
	var tab_control = _tab_container.get_current_tab_control()
	if tab_control is MenuAggregator:
		Accessibility.tts_speak(tr(tab_control.title))
	_tab_animation_player.set_switch(button.button_pressed)

	#Famosa gambs, pra evitar tocar o som na hora que abre o menu
	var time_since_opened:int = Time.get_ticks_usec() - _opened_time_usec
	if time_since_opened > 1000:
		if button.button_pressed:
			AudioManager.post_one_shot_event(AK.EVENTS.PLAY_UI_PAUSE_TAB_CHANGE)
		else:
			AudioManager.post_one_shot_event(AK.EVENTS.PLAY_UI_PAUSE_TAB_CLOSE)

func _reorder_aggregators_container():
	super._reorder_aggregators_container()

	if _tab_buttons.size() == 0:
		for child in _tab_buttons_container.get_children():
			if child is Button:
				_tab_button_group = child.button_group
				_tab_buttons.append(child)
		if _tab_button_group:
			_tab_button_group.pressed.connect(_tab_button_pressed)

	while _tab_buttons.size() < _tab_container.get_tab_count():
		var new = _tab_buttons[0].duplicate()
		_tab_buttons_container.add_child(new)
		_tab_buttons.append(new)

	for button in _tab_buttons:
		var idx:int = button.get_index()
		if idx >= _tab_container.get_tab_count():
			button.hide()
		else:
			button.show()
			var control:Control = _tab_container.get_tab_control(idx)
			if control is MenuAggregator:
				button.icon = control.icon

	_tab_button_group.allow_unpress = true
