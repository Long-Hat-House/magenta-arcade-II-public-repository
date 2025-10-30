extends Node

const ICON_SFX = preload("res://elements/icons/icon_sfx.png")
const ICON_MUSIC = preload("res://elements/icons/icon_music.png")
const ICON_PANNING = preload("res://elements/icons/icon_panning.png")

const SAVE_VOLUME_MUSIC = &"AUDIO_MANAGER.VOLUME_MUSIC"
const SAVE_VOLUME_SFX = &"AUDIO_MANAGER.VOLUME_SFX"
const SAVE_PANNING = &"AUDIO_MANAGER.PANNING"

const _wwise_id_sfx:int = AK.GAME_PARAMETERS.UI_BUS_SOUNDEFFECTS;
const _wwise_id_music:int = AK.GAME_PARAMETERS.UI_BUS_MUSIC;
const _wwise_id_panning:int = AK.GAME_PARAMETERS.UI_ACC_PANNING;

var _volume_sfx:float
var _volume_music:float
var _panning:float

var _slider_sfx:HSlider
var _slider_music:HSlider
var _slider_panning:HSlider

var _save:GameSave
var _listener:Node3D

func await_initialize() -> void:
	while !Wwise.is_initialized():
		await get_tree().process_frame

	_listener = Node3D.new()
	add_child(_listener)

	Wwise.register_game_obj(_listener, "AudioManagerListener")
	Wwise.register_listener(_listener)

	#Wwise.load_bank("Init") #ALREADY LOADED?
	Wwise.load_bank("Music")
	Wwise.load_bank("SFX_Ambience")
	Wwise.load_bank("SFX_Enemy")
	Wwise.load_bank("SFX_Interactable")
	Wwise.load_bank("SFX_NPC")
	Wwise.load_bank("SFX_Player")
	Wwise.load_bank("SFX_Power")
	Wwise.load_bank("SFX_UI")


	Wwise.register_game_obj(self, "AudioManager")

	SaveManager.use_settings(_prepare_options)

func _process(delta: float) -> void:
	if _save && !is_instance_valid(_slider_sfx):
		_prepare_options(_save)

	if !is_instance_valid(_listener): return

	var new_listener_transform:Transform3D

	if is_instance_valid(LevelCameraController.main_camera):
		new_listener_transform = LevelCameraController.main_camera.global_transform
	else:
		new_listener_transform = Transform3D.IDENTITY

	_listener.global_transform = new_listener_transform

	Wwise.set_3d_position(_listener, new_listener_transform)

func _set_volume_sfx(val:float):
	_volume_sfx = val
	print("[AUDIO MANAGER] VOLUME SFX - %s (id:%s)" % [_volume_sfx, _wwise_id_sfx])

	Wwise.set_rtpc_value_id(_wwise_id_sfx, _volume_sfx, null)

	if _slider_sfx:
		_slider_sfx.set_value_no_signal(val)
	if _save:
		_save.set_data(SAVE_VOLUME_SFX, str(val))

func _set_volume_music(val:float):
	_volume_music = val
	print("[AUDIO MANAGER] VOLUME MUSIC - %s (id:%s)" % [_volume_music, _wwise_id_music])
	Wwise.set_rtpc_value_id(_wwise_id_music, _volume_music, null)

	if _slider_music:
		_slider_music.set_value_no_signal(val)
	if _save:
		_save.set_data(SAVE_VOLUME_MUSIC, str(val))

func _set_panning(val:float):
	_panning = val
	print("[AUDIO MANAGER] PANNING - %s (id:%s)" % [_panning, _wwise_id_panning])
	Wwise.set_rtpc_value_id(_wwise_id_panning, _panning, null)

	if _slider_panning:
		_slider_panning.set_value_no_signal(val)
	if _save:
		_save.set_data(SAVE_PANNING, str(val))

func _prepare_options(save:GameSave):
	_save = save

	var ar:Array[String] = ["General", "Volume"]
	var ag = Menu.get_aggregator(ar)
	ag.set_info("menu_volume_title", "", 5)

	var slider_combo_sfx = UIFactory.get_slider_combo("menu_volume_sfx", _set_volume_sfx, ICON_SFX)
	var slider_combo_music = UIFactory.get_slider_combo("menu_volume_music", _set_volume_music, ICON_MUSIC)
	var slider_combo_panning = UIFactory.get_slider_combo("menu_volume_panning", _set_panning, ICON_PANNING)

	_slider_sfx = slider_combo_sfx[UIFactory.SLIDER_COMBO_CONTROLS.SLIDER]
	_slider_music = slider_combo_music[UIFactory.SLIDER_COMBO_CONTROLS.SLIDER]
	_slider_panning = slider_combo_panning[UIFactory.SLIDER_COMBO_CONTROLS.SLIDER]

	ag.add_element(slider_combo_sfx[UIFactory.SLIDER_COMBO_CONTROLS.PARENT])
	ag.add_element(slider_combo_music[UIFactory.SLIDER_COMBO_CONTROLS.PARENT])
	ag.add_element(slider_combo_panning[UIFactory.SLIDER_COMBO_CONTROLS.PARENT])

	_set_volume_sfx(float(_save.get_data(SAVE_VOLUME_SFX, str(100))))
	_set_volume_music(float(_save.get_data(SAVE_VOLUME_MUSIC, str(100))))
	_set_panning(float(_save.get_data(SAVE_PANNING, str(50))))

func post_music_event(event_id:int):
	music_stop_all()
	Wwise.post_event_id(event_id, self)

#called by LevelManager when transitioning!
func music_stop_all():
	Wwise.post_event_id(AK.EVENTS.MUSIC_STOP, self)

func post_one_shot_event(event_id:int):
	Wwise.post_event_id(event_id, self)

func set_global_rtpc_value(parameter_id:int, value:float):
	Wwise.set_rtpc_value_id(parameter_id, value, null)
