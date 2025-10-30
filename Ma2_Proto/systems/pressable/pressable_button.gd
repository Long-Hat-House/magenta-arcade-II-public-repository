class_name PressableButton extends Pressable

signal toggled_on
signal toggled_off

signal graphic_toggled_on
signal graphic_toggled_off

@export var disallow_untogle:bool
@export var toggle_mode:bool
@export var graphic:PressableButtonGraphic:
	set(val):
		if val != graphic:
			graphic = val
			on_graphic_set()
	get():
		return graphic

@export_category("Pressable Button Audio")
@export var _sfx_toggled_on:WwiseEvent
@export var _sfx_toggled_off:WwiseEvent

var _is_toggled:bool

func _ready() -> void:
	var area = null
	if graphic: area = graphic.get_area_3d()
	if area: search_for_area_inside = false

	super._ready()

	if area: setup_area(area)

func on_graphic_set():
	print("HERE PARENT")

func set_toggle(toggled:bool):
	if _is_toggled == toggled || !toggle_mode: return
	set_toggle_no_signal(toggled)
	if toggled:
		toggled_on.emit()
		if _sfx_toggled_on: _sfx_toggled_on.post(self)
	else:
		toggled_off.emit()
		if _sfx_toggled_off: _sfx_toggled_off.post(self)

func set_toggle_no_signal(toggled:bool):
	if _is_toggled == toggled || !toggle_mode: return
	_is_toggled = toggled

	if graphic:
		graphic.set_graphic_pressed(_is_toggled)

	if _is_toggled:
		graphic_toggled_on.emit()
	else:
		graphic_toggled_off.emit()

func toggle():
	if !toggle_mode: return
	set_toggle(!_is_toggled)

func _start_pressing(touch:Player.TouchData):
	if toggle_mode:
		if disallow_untogle && _is_toggled:
			return
		toggle()
		return

	if graphic:
		graphic.set_graphic_pressed(is_pressed)

func _end_pressing(touch:Player.TouchData):
	if toggle_mode:
		return

	if graphic:
		graphic.set_graphic_pressed(is_pressed)

func _pressing_process(touch:Player.TouchData, delta:float):
	pass;
