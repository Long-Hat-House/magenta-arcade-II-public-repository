@tool
class_name ExtendedLabel extends Label

@export var _extended_mouse_filter:MouseFilter = Control.MOUSE_FILTER_PASS:
	set(val):
		_extended_mouse_filter = val
		mouse_filter = _extended_mouse_filter

@export var _tts_disabled:bool = false
@export var _tts_custom_text:String = ""

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_filter = _extended_mouse_filter

func _on_mouse_entered():
	if !_tts_disabled:
		if _tts_custom_text.is_empty():
			Accessibility.tts_speak(tr(text))
		else:
			Accessibility.tts_speak(tr(_tts_custom_text))
