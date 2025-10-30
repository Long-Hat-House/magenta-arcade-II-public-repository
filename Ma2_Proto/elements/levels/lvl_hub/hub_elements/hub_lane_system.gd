class_name HUBLanesSystem extends Node3D

const ICON_LOCKED = preload("res://elements/icons/icon_locked.png")
const ICON_LVL_SELECTION_SCREEN = preload("res://elements/icons/icon_lvl_selection_screen.png")
const ICON_STAR = preload("res://elements/icons/icon_star.png")

signal lane_movement_ratio_updated(lane_position:float)
signal lane_set_finished(index:int)

static var instance:HUBLanesSystem

@export_category("Lanes Movement Style")
@export var movement_easing:Tween.EaseType = Tween.EASE_IN_OUT
@export var movement_transition:Tween.TransitionType = Tween.TRANS_SINE
@export var movement_duration:float = 1
@export var lane_moving_graphic:Node3D
@export var lane_moving_graphic_counterpart:Node3D

@export_category("Lane Tabs Controls")
@export var lane_tabs:Array[Node3D]
@export var tab_buttons:Array[PressableButton]
@export var tab_buttons_box_animation:Switch_Oning_Offing_AnimationPlayer

@export_category("Lane Movement Audio")
@export var sfx_movement_start:WwiseEvent
@export var sfx_movement_stop:WwiseEvent

var lane_position:float:
	get:
		return lane_position
	set(val):
		lane_position = val
		lane_movement_ratio_updated.emit(lane_position)

var _current_tween:Tween

var _has_first_set_lane:bool

var _is_locked:bool

var _current_lane:int

func _ready() -> void:
	instance = self

	var i:int = 0
	for button in tab_buttons:
		button.toggled_on.connect(set_lane_tab.bind(i))
		i += 1

	var g:PressableButtonGraphic = tab_buttons[0].graphic
	g.set_button_color(MA2Colors.GREENISH_BLUE_DARK)
	g.set_button_highlight_color(MA2Colors.GREENISH_BLUE)
	g.set_icon(ICON_LVL_SELECTION_SCREEN)
	g.set_icon_color(MA2Colors.GREENISH_BLUE)

	g = tab_buttons[1].graphic
	g.set_button_color(MA2Colors.GREY)
	g.set_button_highlight_color(MA2Colors.GREY_LIGHT)
	g.set_icon(ICON_STAR)
	g.set_icon_color(MA2Colors.GREY_LIGHT)

	set_locked(true, true)

func set_locked(locked:bool = true, force:bool = false):
	if 	!force && (_is_locked == locked): return
	_is_locked = locked
	tab_buttons_box_animation.set_switch(_is_locked)

	for button in tab_buttons:
		button.set_disabled(_is_locked)

func get_lane_tab() -> int:
	return _current_lane

func set_lane_tab(index:int):
	if index < 0 || index >= lane_tabs.size():
		index = 0
	_current_lane = index
	var i:int = 0
	for button in tab_buttons:
		if i == index:
			button.set_toggle_no_signal(true)
		else:
			button.set_toggle_no_signal(false)
		i += 1

	if _current_tween && _current_tween.is_running():
		if sfx_movement_stop: sfx_movement_stop.post(self)
		_current_tween.kill()

	if _has_first_set_lane:
		if lane_moving_graphic.position.x == -lane_tabs[index].position.x:
			_lane_movement_finish(index)
			return

		if sfx_movement_start: sfx_movement_start.post(self)
		_current_tween = create_tween()
		_current_tween.set_ease(movement_easing)
		_current_tween.set_trans(movement_transition)
		_current_tween.tween_property(lane_moving_graphic, "position:x", -lane_tabs[index].position.x, movement_duration)
		_current_tween.set_parallel()
		_current_tween.tween_property(self, "lane_position", -lane_tabs[index].position.x, movement_duration).finished.connect(_lane_movement_finish.bind(index))
	else:
		_has_first_set_lane = true
		lane_moving_graphic.position.x = -lane_tabs[index].position.x
		lane_position = lane_moving_graphic.position.x

func _lane_movement_finish(lane_index:int):
	lane_set_finished.emit(lane_index)
	if sfx_movement_stop: sfx_movement_stop.post(self)
