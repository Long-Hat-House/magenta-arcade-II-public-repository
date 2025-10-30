class_name ExtendedButton extends Button

@export var _tts_hover_disabled:bool = false
@export var _tts_custom_hover_text:String = ""

@export var _sfx_press:WwiseEvent
@export var _sfx_untoggle:WwiseEvent

var sfx_id_press:int = -1
var sfx_id_untoggle:int = -1

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)

func _on_mouse_entered():
	if !_tts_hover_disabled:
		if _tts_custom_hover_text.is_empty():
			Accessibility.tts_speak(tr(text))
		else:
			Accessibility.tts_speak(tr(_tts_custom_hover_text))

func _pressed() -> void:
	if toggle_mode:
		return

	if _sfx_press:
		_sfx_press.post(AudioManager)
	if sfx_id_press != -1:
		AudioManager.post_one_shot_event(sfx_id_press)

func _toggled(toggled_on: bool) -> void:
	if !toggle_mode:
		return

	if toggled_on:
		if !Accessibility.tts_speak(tr("tts_toggle_turned_on")):
			if _sfx_press:
				_sfx_press.post(AudioManager)
			if sfx_id_press != -1:
				AudioManager.post_one_shot_event(sfx_id_press)
	elif !(button_group && !button_group.allow_unpress):
		if !Accessibility.tts_speak(tr("tts_toggle_turned_off")):
			if _sfx_untoggle:
				_sfx_untoggle.post(AudioManager)
			if sfx_id_untoggle != -1:
				AudioManager.post_one_shot_event(sfx_id_untoggle)

func set_button_icon_fixed_color(default:Color):
	add_theme_color_override("icon_normal_color", default)
	add_theme_color_override("icon_focus_color", default)
	add_theme_color_override("icon_hover_color", default)
	add_theme_color_override("icon_disabled_color", default)
	add_theme_color_override("icon_hover_pressed_color", default)
	add_theme_color_override("icon_pressed_color", default)
