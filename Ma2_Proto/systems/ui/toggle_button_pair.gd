@tool
class_name ToggleButtonPair extends BoxContainer

@export var _is_toggled:bool:
	set(val):
		_is_toggled = val
		_update_view()

@export var _text:String = "Toggle Button Pair":
	set(val):
		_text = val
		_update_view()

@export var _toggle_on:Texture2D:
	set(val):
		_toggle_on = val
		_update_view()

@export var _toggle_off:Texture2D:
	set(val):
		_toggle_off = val
		_update_view()

@export var _toggle_expand_mode:TextureRect.ExpandMode = TextureRect.ExpandMode.EXPAND_FIT_WIDTH_PROPORTIONAL:
	set(val):
		_toggle_expand_mode = val
		if _toggle_rect:
			_toggle_rect.expand_mode = val


@export var _toggle_stretch_mode:TextureRect.StretchMode = TextureRect.StretchMode.STRETCH_KEEP_ASPECT_CENTERED:
	set(val):
		_toggle_stretch_mode = val
		if _toggle_rect:
			_toggle_rect.stretch_mode = val

var _toggle_rect:TextureRect
var _button:Button

func _enter_tree() -> void:
	for child in get_children():
		if child is Button:
			_button = child
		elif child is TextureRect:
			_toggle_rect = child

	if not _button:
		_button = Button.new()
		_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_child(_button, false, Node.INTERNAL_MODE_BACK)

	if not _toggle_rect:
		_toggle_rect = TextureRect.new()
		_toggle_rect.expand_mode = _toggle_expand_mode
		_toggle_rect.stretch_mode = _toggle_stretch_mode
		_toggle_rect.size_flags_horizontal = Control.SIZE_FILL
		_toggle_rect.size_flags_vertical = Control.SIZE_FILL
		add_child(_toggle_rect, false, Node.INTERNAL_MODE_BACK)

		_button.pressed.connect(_toggle)

	_update_view()

func _toggle() -> void:
	_is_toggled = !_is_toggled

func _update_view():
	if _button:
		_button.text = _text
	if _toggle_rect:
		_toggle_rect.texture = _toggle_on if _is_toggled else _toggle_off
