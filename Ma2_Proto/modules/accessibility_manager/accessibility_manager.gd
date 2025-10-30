extends Node

const ICON_ACCESSIBILITY = preload("res://elements/icons/icon_accessibility.png")
const ACCESSIBILITY_TEXT_PREVIEW = preload("res://modules/accessibility_manager/accessibility_text_preview.tscn")

const SAVE_ACCESSIBILITY_SETTINGS = &"ACCESSIBILITY.SETTINGS"

const TEXT_EFFECT_TAGS:Array[String] = [
	"wave",
	"color",
	"shake"
]

var _initialized:bool = false
var _save:GameSave

var _tts_speed_slider_parent:Control
var _tts_volume_slider_parent:Control
var _tts_dialogue_speed_slider_parent:Control
var _tts_dialogue_volume_slider_parent:Control

var _high_contrast_controls:Control

var _text_options_controls:Control
var _dialogue_text_preview:AccessibilityTextPreview

var _colors:Array[Color] = [
	MA2Colors.BLACK,
	MA2Colors.BLUE,
	MA2Colors.BUTTON_ICON,
	MA2Colors.GREENISH_BLUE,
	MA2Colors.GREENISH_BLUE_DARK,
	MA2Colors.GREENISH_BLUE_MEDIUM,
	MA2Colors.GREY,
	MA2Colors.MAGENTA,
	MA2Colors.MAGENTA_VERY_BRIGHT,
	MA2Colors.PINK_BRIGHT,
]

var _high_contrast_color_buttons:Dictionary[StringName, ExtendedButton] = {}

func _ready() -> void:
	print("[ACCESSIBILITY] Readying")

func await_initialize() -> void:
	print("[ACCESSIBILITY] Initializing")
	SaveManager.use_settings(_on_save_settings_ready)
	while !_initialized:
		await get_tree().process_frame

func _custom_save_function(data:String):
	_save.set_data(SAVE_ACCESSIBILITY_SETTINGS, data)

func _custom_load_function() -> String:
	return _save.get_data(SAVE_ACCESSIBILITY_SETTINGS)

func _on_save_settings_ready(save:GameSave):
	print("[ACCESSIBILITY] Initialized")
	_save = save
	Accessibility.initialize(
		self,
		_custom_save_function,
		_custom_load_function
		)

	TextManager.locale_changed.connect(_on_locale_changed)
	_on_locale_changed(TextManager.get_current_locale())

	var ag_ac = Menu.get_aggregator(["Access"])
	ag_ac.set_info("menu_accessibility_title", "menu_accessibility_text", 10, ICON_ACCESSIBILITY)
	_create_accessibility_menus(ag_ac)

	Accessibility.high_contrast_controller.group_settings_changed.connect(_on_group_settings_changed)
	Accessibility.high_contrast_controller.groups_settings_changed.connect(_on_groups_settings_changed)
	Accessibility.high_contrast_controller.enabled_changed.connect(update_enabled_controls)

	_initialized = true

func _on_groups_settings_changed():
	for group_id in _high_contrast_color_buttons:
		_on_group_settings_changed(group_id)

func _on_group_settings_changed(group_id:StringName):
	_high_contrast_color_buttons[group_id].set_button_icon_fixed_color(
		Accessibility.high_contrast_controller.get_group_color(group_id))

func _on_locale_changed(new_locale:String):
	_assert_tts(Accessibility.set_tts_voice_language(new_locale))
	if _dialogue_text_preview:
		_dialogue_text_preview.re_parse()

func _create_accessibility_menus(ag_ac:MenuAggregator):
	_create_tts_menu(ag_ac)
	_create_high_contrast_menu(ag_ac)
	_create_text_options_menu(ag_ac)

	ag_ac.add_element(UIFactory.get_button("menu_accessibility_restore_settings", _restore_settings.bind(ag_ac), true))

	update_enabled_controls()

func update_enabled_controls():
	var enabled:bool = Accessibility.get_tts_enabled()
	_tts_speed_slider_parent.visible = enabled
	_tts_volume_slider_parent.visible = enabled

	enabled = Accessibility.get_tts_dialogues_enabled()
	_tts_dialogue_speed_slider_parent.visible = enabled
	_tts_dialogue_volume_slider_parent.visible = enabled

	enabled = Accessibility.get_high_contrast_enabled()
	_high_contrast_controls.visible = enabled

func _create_high_contrast_menu(ag_ac:MenuAggregator):
	var ag_hc = ag_ac.get_aggregator(["HighContrast"])
	ag_hc.set_info("menu_accessibility_highcontrast", "menu_accessibility_highcontrast_text")

	ag_hc.add_element(UIFactory.get_check_box(
		"menu_accessibility_highcontrast_toggle",
		Accessibility.set_high_contrast_enabled,
		Accessibility.get_high_contrast_enabled()
		))

	_high_contrast_controls = VBoxContainer.new()
	_high_contrast_controls.add_child(UIFactory.get_slider_combo(
		"menu_accessibility_highcontrast_bg_visibility",
		Accessibility.set_high_contrast_background_visibility,
		null,
		Accessibility.get_high_contrast_background_visibility(),
		0.05, 5, 1, 0
		)[UIFactory.SLIDER_COMBO_CONTROLS.PARENT])

	var groups = Accessibility.get_high_contrast_groups()
	for group_id in groups:
		var group_current_color:Color = groups[group_id]
		var b = UIFactory.get_button(
			"menu_accessibility_highcontrast_group_" + group_id,
			_show_high_contrast_group_selection_prompt.bind(group_id),
			false,
			PromptWindow.ICON_COLOR_PALETTE
			)
		b.set_button_icon_fixed_color(group_current_color)
		_high_contrast_controls.add_child(b)
		_high_contrast_color_buttons[group_id] = b

	ag_hc.add_element(_high_contrast_controls)

func _create_text_options_menu(ag_ac:MenuAggregator):
	var ag_t = ag_ac.get_aggregator(["TextOptions"])
	ag_t.set_info("menu_accessibility_textoptions", "menu_accessibility_textoptions_text")

	_text_options_controls = VBoxContainer.new()

	_dialogue_text_preview = ACCESSIBILITY_TEXT_PREVIEW.instantiate()
	_dialogue_text_preview.re_parse()

	_text_options_controls.add_child(UIFactory.get_slider_combo(
		"menu_accessibility_textoptions_fontsize",
		func(val:float):
			Accessibility.set_font_size_ratio(val)
			_dialogue_text_preview.re_parse()
			,
		null,
		Accessibility.get_font_size_ratio(),
		0.1, 6, 1.5, 1
		)[UIFactory.SLIDER_COMBO_CONTROLS.PARENT])

	_text_options_controls.add_child(_dialogue_text_preview)

	_text_options_controls.add_child(
		UIFactory.get_button_color_selector(
			"menu_accessibility_textoptions_color_default",
			"menu_accessibility_textoptions_color_default",
			"menu_accessibility_color_popup_select",
			_colors,
			func() -> Color: return Color.BLACK,
			Accessibility.get_font_color_default,
			func(val:Color):
				Accessibility.set_font_color_default(val)
				_dialogue_text_preview.re_parse()
				)
		)

	_text_options_controls.add_child(
		UIFactory.get_button_color_selector(
			"menu_accessibility_textoptions_color_highlight",
			"menu_accessibility_textoptions_color_highlight",
			"menu_accessibility_color_popup_select",
			_colors,
			func() -> Color: return Color.BLACK,
			Accessibility.get_font_color_highlight,
			func(val:Color):
				Accessibility.set_font_color_highlight(val)
				_dialogue_text_preview.re_parse()
				)
		)

	ag_t.add_element(_text_options_controls)

	var ag_tags = ag_t.get_aggregator(["TextOptions"])
	ag_tags.set_info("menu_accessibility_textoptions_tags", "")

	for tag in TEXT_EFFECT_TAGS:
		var b = UIFactory.get_check_box(
			"menu_accessibility_textoptions_tags_"+tag,
			func(val:bool):
				Accessibility.set_bbcode_removed_tag(tag, !val)
				_dialogue_text_preview.re_parse()
				,
			!Accessibility.get_bbcode_removed_tag(tag)
		)
		ag_tags.add_element(b)


func _generic_button_color_callback(color:Color, to_call:Callable, button:ExtendedButton):
	to_call.call(color)
	button.set_button_icon_fixed_color(color)

func _show_high_contrast_group_selection_prompt(group_id:StringName):
	var current_color:Color = Accessibility.high_contrast_controller.get_group_color(group_id)
	var default_color:Color = Accessibility.high_contrast_controller.get_group_default_color(group_id)
	PromptWindow.new_prompt_color(
		"menu_accessibility_highcontrast_group_" + group_id,
		"menu_accessibility_color_popup_select",
		_on_high_contrast_group_color_selected.bind(group_id),
		_colors, current_color, default_color
		)

func _on_high_contrast_group_color_selected(color:Color, group_id:StringName):
	Accessibility.set_high_contrast_group_color(group_id, color)

func _create_tts_menu(ag_ac:MenuAggregator):
	var ag_tts = ag_ac.get_aggregator(["TTS"])
	ag_tts.set_info("menu_accessibility_tts", "menu_accessibility_tts_text")

	## GENERAL
	var ag_tts_gen = ag_tts.get_aggregator(["General"])
	ag_tts_gen.set_info("menu_accessibility_tts_general", "")

	var tts_checkbox = UIFactory.get_check_box(
		"menu_accessibility_tts_toggle_general",
		func (val):
			_assert_tts(Accessibility.set_tts_enabled(val))
			update_enabled_controls()
			,
		Accessibility.get_tts_enabled()
	)

	_tts_speed_slider_parent = UIFactory.get_slider_combo(
		"menu_accessibility_tts_speed",
		Accessibility.set_tts_speed,
		null,
		Accessibility.get_tts_speed(),
		0.25, 5, 3.25, 0.25
		)[UIFactory.SLIDER_COMBO_CONTROLS.PARENT]

	_tts_volume_slider_parent = UIFactory.get_slider_combo(
		"menu_accessibility_tts_volume",
		Accessibility.set_tts_volume,
		null,
		Accessibility.get_tts_volume(),
		.25, 5, 1, 0
		)[UIFactory.SLIDER_COMBO_CONTROLS.PARENT]


	ag_tts_gen.add_element(tts_checkbox)
	ag_tts_gen.add_element(_tts_speed_slider_parent)
	ag_tts_gen.add_element(_tts_volume_slider_parent)

	## DIALOGUES
	var ag_tts_dial = ag_tts.get_aggregator(["Dialogue"])
	ag_tts_dial.set_info("menu_accessibility_tts_dialogues", "")

	var tts_dialogues = UIFactory.get_check_box(
		"menu_accessibility_tts_toggle_dialogues",
		func (val):
			_assert_tts(Accessibility.set_tts_dialogues_enabled(val))
			update_enabled_controls()
			,
		Accessibility.get_tts_dialogues_enabled()
	)

	_tts_dialogue_speed_slider_parent = UIFactory.get_slider_combo(
		"menu_accessibility_tts_speed",
		Accessibility.set_tts_dialogue_speed,
		null,
		Accessibility.get_tts_dialogue_speed(),
		0.25, 5, 3.25, 0.25
		)[UIFactory.SLIDER_COMBO_CONTROLS.PARENT]

	_tts_dialogue_volume_slider_parent = UIFactory.get_slider_combo(
		"menu_accessibility_tts_volume",
		Accessibility.set_tts_dialogue_volume,
		null,
		Accessibility.get_tts_dialogue_volume(),
		.25, 5, 1, 0
		)[UIFactory.SLIDER_COMBO_CONTROLS.PARENT]

	ag_tts_dial.add_element(tts_dialogues)
	ag_tts_dial.add_element(_tts_dialogue_speed_slider_parent)
	ag_tts_dial.add_element(_tts_dialogue_volume_slider_parent)

func _assert_tts(state:Accessibility.TTS_VOICES_STATE):
	match state:
		Accessibility.TTS_VOICES_STATE.VOICES_NOT_REQUESTED:
			return
		Accessibility.TTS_VOICES_STATE.SUCCESS_VOICES_AVAILABLE:
			return
		Accessibility.TTS_VOICES_STATE.WARNING_NO_VOICES_IN_LANGUAGE:
			PromptWindow.new_prompt(
				"menu_accessibility_tts_warning_title",
				tr("menu_accessibility_tts_warning_message").format({"lang" = Accessibility.get_tts_voice_language()})
			)
			return
		Accessibility.TTS_VOICES_STATE.ERROR_NO_VOICES_IN_SYSTEM:
			PromptWindow.new_prompt(
				"menu_accessibility_tts_error_title",
				"menu_accessibility_tts_error_message"
			)
			return

func _restore_settings(ag_ac:MenuAggregator):
	Accessibility.reset_all_settings()
	_on_locale_changed(TextManager.get_current_locale())
	ag_ac.delete_all_elements_and_subs()
	_create_accessibility_menus(ag_ac)
