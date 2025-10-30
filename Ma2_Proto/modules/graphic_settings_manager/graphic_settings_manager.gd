class_name GraphicSettingsManager extends Node

const ICON_GRAPHIC_QUALITY = preload("res://elements/icons/icon_star.png")
const SAVE_QUALITY:StringName = &"GRAPHIC_SETTINGS_MANAGER.GRAPHIC_QUALITY"

enum Quality
{
	Ultra,
	High,
	Mid,
	Low,
}

enum SpecialQualityCondition
{
	None,
	ParticlesEnabled,
	WindEnabled
}

const quality_options:Dictionary[Quality, String] = {
	Quality.Ultra : "graphics_quality_ultra",
	Quality.High : "graphics_quality_high",
	Quality.Mid : "graphics_quality_mid",
	Quality.Low : "graphics_quality_low",
}

static var instance:GraphicSettingsManager

signal any_settings_changed()

var _save:GameSave
var _button_pair:ButtonLabelPair

var _quality:Quality

#Just for printing easily
func p(text:String):
	print("[GRAPHIC SETTINGS MANAGER] " + text)

func error(text:String):
	printerr("[GRAPHIC SETTINGS MANAGER - ERROR] " + text)

func get_quality() -> Quality: return _quality
func set_quality(val:Quality):
	p("Will set quality: " + str(val))
	if !_save || !_button_pair:
		error("Setting quality before initialized! Will do nothing")
		return

	_quality = val
	_save.set_data(SAVE_QUALITY, str(_quality))
	_button_pair.label_text = quality_options[_quality]

	update_fps_by_quality()

	any_settings_changed.emit()
	p("New quality set and emited")

func get_particles_enabled() -> bool:
	return get_quality() in [Quality.Ultra, Quality.High, Quality.Mid]

func get_wind_feedback_enabled() -> bool:
	return get_quality() in [Quality.Ultra, Quality.High, Quality.Mid]

func get_post_process_enabled() -> bool:
	return get_quality() in [Quality.Ultra, Quality.High]

func get_shadows_quality() -> Quality:
	return get_quality()

func get_light_quality() -> Quality:
	return get_quality()

func get_initialized():
	return _save != null

func await_initialize():
	if instance:
		error("There was already an instance set! Will queue free")
		queue_free()
	instance = self
	p("Initializing")
	SaveManager.use_settings(_save_settings_ready)
	while !get_initialized():
		await get_tree().process_frame
	p("Initialized")

func _process(delta: float) -> void:
	if _save && !is_instance_valid(_button_pair):
		p("WILL RE-INIT")
		_save_settings_ready(_save)

func _save_settings_ready(save:GameSave):
	p("Loading settings from save")

	_save = save

	_button_pair = UIFactory.get_button_label_pair(
		"menu_graphics_quality",
		"Not initialized yet",
		show_quality_prompt)
	_button_pair.icon = ICON_GRAPHIC_QUALITY

	var arr:Array[String] = ["General", "Graphics"]
	var ag = Menu.get_aggregator(arr)
	ag.set_info("","")
	ag.add_element(_button_pair)

	#Now load and initialize values
	if _save.has_data(SAVE_QUALITY):
		_quality = int(_save.get_json_parsed_data(SAVE_QUALITY, str(Quality.Ultra)))
	else:
		_quality = Quality.Ultra
	set_quality(_quality) #this saves the option and calls the updated signal

	p("Settings loaded, and menu ready")

func show_quality_prompt():
	var current:String = TranslationServer.get_locale()
	var id:int = 0
	var current_index:int = 0

	var prompt_entries:Array[PromptWindow.PromptEntry] = []
	for opt in quality_options:
		prompt_entries.append(
			PromptWindow.PromptEntry.CreateButton(
				quality_options[opt], opt, false, true, opt == get_quality()
				)
			)
	prompt_entries.append(PromptWindow.PromptEntry.new(PromptWindow.PromptEntry.EntryStyle.Separator))
	prompt_entries.append(PromptWindow.PromptEntry.CreateButton("menu_confirm", -1, true))
	PromptWindow.new_prompt_advanced("menu_graphics_quality", "menu_graphics_quality_description", _on_prompt_quality_finished, prompt_entries, false, _on_prompt_quality_updated)

func _on_prompt_quality_updated(index:int):
	if index >= quality_options.size() || index < 0:
		return
	set_quality(index)

func _on_prompt_quality_finished(index:int):
	pass
	#_on_prompt_quality_updated(index) Not needed because it was already set when button was clicked

static func should_be_enabled(conditions_in:Array[Quality], negated:bool, special_quality_condition:SpecialQualityCondition = SpecialQualityCondition.None)->bool:
	if instance:
		match special_quality_condition:
			SpecialQualityCondition.None:
				return (instance.get_quality() in conditions_in) != negated;
			SpecialQualityCondition.ParticlesEnabled:
				return instance.get_particles_enabled();
			SpecialQualityCondition.WindEnabled:
				return instance.get_wind_feedback_enabled();
		return true;
	else:
		return true; ## Everything enabled by default! Explode the cellphone!!

func update_fps_by_quality():
	match get_quality():
		Quality.Low:
			set_fps(30, 60);
		Quality.Mid:
			set_fps(30, 60);
		Quality.High:
			set_fps(60, 60);
		Quality.Ultra:
			set_fps(0, 60);

func set_fps(fps_graphic:int, fps_physics:int):
	Engine.max_fps = fps_graphic; # 0 means uncapped
	Engine.physics_ticks_per_second = fps_physics;
	Engine.max_physics_steps_per_frame = roundi(lerp(5, 8, clampf(inverse_lerp(30, 60, fps_physics), 0, 1)))
