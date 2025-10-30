@tool
class_name UIFactory extends Node

static var DEFAULT_SFX_BUTTON_PRESS:int = AK.EVENTS.PLAY_UI_BUTTON_PRESSED
static var DEFAULT_SFX_BUTTON_UNTOGLE:int = AK.EVENTS.PLAY_UI_BUTTON_UNTOGGLED

static var _slider_sound_debouncing_timer_msec:float
enum SLIDER_COMBO_CONTROLS{
	PARENT,
	ICON,
	LABEL,
	SLIDER
}

static func get_button_color_selector(
	button_text:String,
	prompt_title:String,
	prompt_text:String,
	colors_palette:Array[Color],
	color_default_getter:Callable,
	color_current_getter:Callable,
	color_onselected_setter:Callable
) -> ExtendedButton:
	var b:ExtendedButton = get_button(
		button_text,
		Callable(),
		false,
		PromptWindow.ICON_COLOR_PALETTE)

	b.set_button_icon_fixed_color(color_current_getter.call())
	b.pressed.connect(
		func():
			PromptWindow.new_prompt_color(
				prompt_title,
				prompt_text,
				func(color:Color):
					color_onselected_setter.call(color)
					b.set_button_icon_fixed_color(color_current_getter.call())
					,
				colors_palette, color_current_getter.call(), color_default_getter.call()
				)
	)

	return b

static func get_button(
	text:String = "",
	pressed_callable:Callable = Callable(),
	magenta:bool = false,
	icon:Texture2D = null
) -> ExtendedButton:
	var b:ExtendedButton = ExtendedButton.new()
	b.text = text
	b.sfx_id_press = DEFAULT_SFX_BUTTON_PRESS
	b.sfx_id_untoggle = DEFAULT_SFX_BUTTON_UNTOGLE
	if icon:
		b.icon = icon
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if pressed_callable.is_valid():
		b.pressed.connect(pressed_callable)
	if magenta:
		b.theme_type_variation = "button_magenta"
	return b

static func get_check_box(
	text:String = "",
	toggled_callable:Callable = Callable(),
	button_pressed_default:bool = false
) -> ExtendedCheckBox:
	var b:ExtendedCheckBox = ExtendedCheckBox.new()
	b.text = text
	b.sfx_id_press = DEFAULT_SFX_BUTTON_PRESS
	b.sfx_id_untoggle = DEFAULT_SFX_BUTTON_UNTOGLE
	if toggled_callable.is_valid():
		b.toggled.connect(toggled_callable)
	b.set_pressed_no_signal(button_pressed_default)
	return b

static func get_label(
	text:String = "",
	autorap_and_expand:bool = true,
	centered:bool = true,
) -> ExtendedLabel:
	var l:ExtendedLabel = ExtendedLabel.new()
	if centered:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if autorap_and_expand:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.text = text
	return l

static func get_button_label_pair(
	button_text:String = "",
	label_text:String = "",
	pressed_callable:Callable = Callable()
) -> ButtonLabelPair:
	var pair:ButtonLabelPair = ButtonLabelPair.new()
	pair.button_text = button_text
	pair.label_text = label_text
	if pressed_callable.is_valid():
		pair.pressed.connect(pressed_callable)
	return pair

static func get_slider_combo(
	id:String,
	callback:Callable,
	icon_texture:Texture2D,
	default_value:float = 50,
	step:float = 5.0,
	tick_count:int = 5,
	max_value:float = 100,
	min_value:float = 0,
) -> Dictionary[SLIDER_COMBO_CONTROLS, Control]:
	var h = HBoxContainer.new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_theme_constant_override("separation", 20)

	var icon = TextureRect.new()
	icon.texture = icon_texture
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(120,120)
	if icon_texture == null:
		icon.visible = false

	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 5)

	var label = UIFactory.get_label(id, true, false)

	var slider = HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.max_value = max_value
	slider.min_value = min_value
	slider.value_changed.connect(callback)
	slider.tick_count = tick_count
	slider.step = step
	slider.rounded = false
	slider.value_changed.connect(
		func(val):
			var current_time:float = Time.get_ticks_msec()
			if current_time - _slider_sound_debouncing_timer_msec > 50:
				AudioManager.post_one_shot_event(AK.EVENTS.PLAY_UI_SLIDER_CHANGED)
				_slider_sound_debouncing_timer_msec = current_time
			)
	slider.drag_ended.connect(
		func(changed:bool):
			Accessibility.tts_speak(str(slider.value))
	)
	slider.set_value_no_signal(default_value)


	h.add_child(icon)
	h.add_child(v)
	v.add_child(label)
	v.add_child(slider)

	return {
		SLIDER_COMBO_CONTROLS.PARENT : h,
		SLIDER_COMBO_CONTROLS.ICON : icon,
		SLIDER_COMBO_CONTROLS.LABEL : label,
		SLIDER_COMBO_CONTROLS.SLIDER : slider,
	}
