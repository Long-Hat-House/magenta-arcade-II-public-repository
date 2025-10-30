class_name PromptWindow
extends Control

const HC_THEME = preload("res://elements/ui/themes/menu/hc_theme.tres")
const MENU_THEME = preload("res://elements/ui/themes/menu/menu_theme.tres")

const PROMPT_WINDOW = preload("res://modules/prompt_system/prompt_window.tscn")
const ICON_CLOSE = preload("res://elements/icons/icon_close.png")
const ICON_COLOR_PALETTE:Texture2D = preload("res://elements/icons/icon_hold.png")

class PromptEntry:
	enum EntryStyle{
		ButtonGood,
		ButtonBad,
		ButtonCheck,
		HBoxBegin,
		VBoxBegin,
		BoxEnd,
		Separator,
		Custom,
	}

	var _style:EntryStyle
	var _entry_id:int
	var _text:String
	var _toggled:bool
	var _icon:Texture2D
	var _custom:Control

	func _init(style:EntryStyle, text = "", entry_id:int = -1):
		_style = style
		_text = text
		_entry_id = entry_id

	static func CreateButton(text = "", entry_id:int = -1, bad_button:bool = false, check:bool = false, toggled:bool = false, icon:Texture2D = null) -> PromptEntry:
		var entry = PromptEntry.new(EntryStyle.ButtonCheck if check else (EntryStyle.ButtonGood if !bad_button else EntryStyle.ButtonBad), text, entry_id)
		entry._toggled = toggled
		entry._icon = icon
		return entry

	static func CreateCustom(custom_control:Control) -> PromptEntry:
		var entry = PromptEntry.new(EntryStyle.Custom)
		entry._custom = custom_control
		return entry

static func new_prompt(
	title: String,
	text: String,
	callback:Callable = Callable(),
	button_text_array: Array[String] = [],
	allow_exit:bool = true
	) -> PromptWindow:
	# Create a new instance of the PromptWindow scene
	var prompt_window = PROMPT_WINDOW.instantiate()
	if Accessibility.high_contrast_controller:
		prompt_window.theme = HC_THEME if Accessibility.high_contrast_controller.get_enabled() else MENU_THEME
	(Engine.get_main_loop() as SceneTree).root.add_child(prompt_window)
	# Add the prompt window to the scene tree and show it
	#get_tree().root.add_child(prompt_window)

	# Set up the prompt window with provided data
	return prompt_window.set_data(title, text, callback, button_text_array, allow_exit)

## this will create a prompt with a color picker and palette.
## When closing will call callback(color) with the selected color, even if unchanged
static func new_prompt_color(
	title: String,
	text: String,
	color_selected_callback:Callable,
	palette:Array[Color],
	current:Color,
	default:Color) -> PromptWindow:
	var color_rect:ColorRect = ColorRect.new()
	color_rect.color = current
	color_rect.custom_minimum_size = Vector2(64,64)

	var picker:ColorPicker = ColorPicker.new()
	picker.can_add_swatches = false
	picker.color_modes_visible = false
	picker.presets_visible = false
	picker.sampler_visible = false
	picker.hex_visible = false
	picker.picker_shape = ColorPicker.SHAPE_HSV_RECTANGLE
	picker.color = current
	picker.color_changed.connect(func(c): color_rect.color = c)

	var color_button_callback:Callable = func color_button_callback(color:Color):
		picker.color = color
		color_rect.color = color

	var default_color_button:ExtendedButton = UIFactory.get_button("menu_select_color_default", color_button_callback.bind(default), false, ICON_COLOR_PALETTE)
	default_color_button.set_button_icon_fixed_color(default)

	var palette_grid:GridContainer = GridContainer.new()
	palette_grid.columns = 6
	for c in palette:
		var cb:ExtendedButton = UIFactory.get_button("", color_button_callback.bind(c))
		cb.icon = ICON_COLOR_PALETTE
		cb.set_button_icon_fixed_color(c)
		palette_grid.add_child(cb)

	var v_box:BoxContainer = VBoxContainer.new()
	v_box.add_child(picker)
	v_box.add_child(default_color_button)
	v_box.add_child(palette_grid)

	var entries:Array[PromptEntry] = [
		PromptEntry.CreateCustom(v_box),
		PromptEntry.new(PromptEntry.EntryStyle.Separator),
		PromptEntry.CreateCustom(color_rect),
		PromptEntry.CreateButton("menu_confirm", 1),
	]

	var prompt_callback:Callable = func prompt_callback(id:int):
		if id <= 0:
			color_selected_callback.call(current)
		else:
			color_selected_callback.call(picker.color)

	return new_prompt_advanced(title, text, prompt_callback, entries, true)

static func new_prompt_advanced(
	title: String,
	text: String,
	callback:Callable = Callable(),
	entry_array: Array[PromptEntry] = [],
	allow_exit:bool = true,
	button_value_updated_callback:Callable = Callable()
) -> PromptWindow:
	var prompt_window = PROMPT_WINDOW.instantiate()
	if Accessibility.high_contrast_controller:
		prompt_window.theme = HC_THEME if Accessibility.high_contrast_controller.get_enabled() else MENU_THEME
	(Engine.get_main_loop() as SceneTree).root.add_child(prompt_window)

	return prompt_window.set_data_advanced(title, text, callback, entry_array, allow_exit, button_value_updated_callback)


# Public properties for setting up the prompt
@export var sfx_on:WwiseEvent
@export var sfx_off:WwiseEvent
@export var switch_animation: Switch_Oning_Offing_AnimationPlayer
@export var label_title: Label
@export var label_text: RichTextLabel
@export var button_container: Container

var _selected_button_id:int = -1

func _ready() -> void:
	label_text.meta_clicked.connect(_richtextlabel_on_meta_clicked)

func set_data(
	title: String,
	text: String,
	callback:Callable = Callable(),
	button_text_array: Array[String] = [],
	allow_exit:bool = true) -> PromptWindow:
	# Set up the title and text.
	label_title.text = title
	label_text.text = text

	# Remove existing buttons if any.
	for child in button_container.get_children():
		button_container.remove_child(child)
		child.queue_free()

	var button_pressed_callable:Callable = func button_pressed(button_id:int) -> void:
		if callback:
			callback.call(button_id)
		button_container.process_mode = Node.PROCESS_MODE_DISABLED
		print_debug("BUTTON PRESSED: %d" % button_id)
		switch_animation.set_switch(false)
		switch_animation.turned_off.connect(queue_free)
		if sfx_off: sfx_off.post(AudioManager)

	# Create buttons based on button_text_array and button_callback_array.
	for i in range(button_text_array.size()):
		var button = UIFactory.get_button()
		button.text = button_text_array[i]
		button.pressed.connect(button_pressed_callable.bind(i))
		button_container.add_child(button)

	if allow_exit:
		if button_text_array.size() > 0:
			var separator:Separator = VSeparator.new() if button_container is HBoxContainer else HSeparator.new()
			button_container.add_child(separator)
		var button = UIFactory.get_button()
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.text = ""
		button.icon = ICON_CLOSE
		button.pressed.connect(
			func():
				button_pressed_callable.call(_selected_button_id)
				)
		button_container.add_child(button)

	switch_animation.set_switch(true)
	if sfx_on: sfx_on.post(AudioManager)

	return self

func set_data_advanced(
	title: String,
	text: String,
	button_callback:Callable = Callable(),
	entries: Array[PromptEntry] = [],
	allow_exit:bool = true,
	button_value_updated_callback:Callable = Callable()
	) -> PromptWindow:
	# Set up the title and text.
	label_title.text = title
	label_text.text = text

	# Remove existing buttons if any.
	for child in button_container.get_children():
		button_container.remove_child(child)
		child.queue_free()

	var button_pressed_callable:Callable = func button_pressed(button_id:int) -> void:
		if button_callback:
			button_callback.call(button_id)
		button_container.process_mode = Node.PROCESS_MODE_DISABLED
		print_debug("BUTTON PRESSED: %d" % button_id)
		switch_animation.set_switch(false)
		switch_animation.turned_off.connect(queue_free)
		if sfx_off: sfx_off.post(AudioManager)

	var subcontrols:Array[Control] = []

	var button_group:ButtonGroup = null

	for entry in entries:

		var current_parent:Control = subcontrols.back() if subcontrols.size() > 0 else button_container

		match entry._style:
			PromptEntry.EntryStyle.ButtonGood:
				var button = UIFactory.get_button()
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				button.text = entry._text
				button.icon = entry._icon
				if button.icon:
					button.alignment = HORIZONTAL_ALIGNMENT_LEFT
				button.pressed.connect(button_pressed_callable.bind(entry._entry_id))
				current_parent.add_child(button)
			PromptEntry.EntryStyle.ButtonBad:
				var button = UIFactory.get_button()
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				button.text = entry._text
				button.icon = entry._icon
				if button.icon:
					button.alignment = HORIZONTAL_ALIGNMENT_LEFT
				button.pressed.connect(button_pressed_callable.bind(entry._entry_id))
				button.theme_type_variation = "button_magenta"
				current_parent.add_child(button)
			PromptEntry.EntryStyle.ButtonCheck:
				if button_group == null:
					button_group = ButtonGroup.new()
					button_group.allow_unpress = false
				var button = UIFactory.get_check_box()
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				button.text = entry._text
				button.icon = entry._icon
				if button.icon:
					button.alignment = HORIZONTAL_ALIGNMENT_LEFT
				button.set_pressed_no_signal(entry._toggled)
				button.button_group = button_group
				var id = entry._entry_id
				button.toggled.connect(
					func(val):
						if val:
							_selected_button_id = id
							if button_value_updated_callback.is_valid():
								button_value_updated_callback.call(id)
						)
				current_parent.add_child(button)
			PromptEntry.EntryStyle.HBoxBegin:
				var hbox = HBoxContainer.new()
				hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				current_parent.add_child(hbox)
				subcontrols.append(hbox)
			PromptEntry.EntryStyle.VBoxBegin:
				var vbox = VBoxContainer.new()
				vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				current_parent.add_child(vbox)
				subcontrols.append(vbox)
			PromptEntry.EntryStyle.BoxEnd:
				subcontrols.pop_back()
			PromptEntry.EntryStyle.Separator:
				var separator:Separator = VSeparator.new() if current_parent is HBoxContainer else HSeparator.new()
				current_parent.add_child(separator)
			PromptEntry.EntryStyle.Custom:
				current_parent.add_child(entry._custom)

	if allow_exit:
		var separator:Separator = VSeparator.new() if button_container is HBoxContainer else HSeparator.new()
		button_container.add_child(separator)
		var button = UIFactory.get_button()
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.text = ""
		button.icon = ICON_CLOSE
		button.pressed.connect(
			func():
				button_pressed_callable.call(_selected_button_id)
				)
		button_container.add_child(button)

	switch_animation.set_switch(true)
	if sfx_on: sfx_on.post(AudioManager)

	return self

func _richtextlabel_on_meta_clicked(meta):
	OS.shell_open(str(meta))
