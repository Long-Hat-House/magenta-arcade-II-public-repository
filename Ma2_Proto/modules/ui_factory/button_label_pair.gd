@tool
class_name ButtonLabelPair extends BoxContainer

signal pressed

@export var icon:Texture2D = null:
	set(val):
		icon = val
		_update_view()

@export var label_text:String = "Label Value":
	set(val):
		label_text = val
		_update_view()

@export var button_text:String = "Button Text":
	set(val):
		button_text = val
		_update_view()

@export var button_size_flags_horizontal:Control.SizeFlags = Control.SIZE_EXPAND_FILL:
	set(val):
		button_size_flags_horizontal = val
		if _button:
			_button.expand_mode = val


@export var button_size_flags_vertical:Control.SizeFlags = Control.SIZE_EXPAND_FILL:
	set(val):
		button_size_flags_vertical = val
		if _button:
			_button.stretch_mode = val

@export var label_size_flags_horizontal:Control.SizeFlags = Control.SIZE_EXPAND_FILL:
	set(val):
		label_size_flags_horizontal = val
		if _label:
			_label.expand_mode = val

@export var label_size_flags_vertical:Control.SizeFlags = Control.SIZE_SHRINK_CENTER:
	set(val):
		label_size_flags_vertical = val
		if _label:
			_label.stretch_mode = val

var _label:Label
var _button:Button

func _enter_tree() -> void:
	for child in get_children():
		if child is Button:
			_button = child
		elif child is Label:
			_label = child

	if not _button:
		_button = UIFactory.get_button(button_text)
		_button.size_flags_horizontal = button_size_flags_horizontal
		_button.size_flags_vertical = button_size_flags_vertical
		_button.pressed.connect(_on_button_pressed)
		_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		add_child(_button, false, Node.INTERNAL_MODE_BACK)

	if not _label:
		_label = UIFactory.get_label(label_text)
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.size_flags_horizontal = label_size_flags_horizontal
		_label.size_flags_vertical = label_size_flags_vertical
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(_label, false, Node.INTERNAL_MODE_BACK)

	_update_view()

func _on_button_pressed():
	pressed.emit()

func _update_view():
	if _button:
		_button.text = button_text
		_button.icon = icon
	if _label:
		_label.text = label_text
