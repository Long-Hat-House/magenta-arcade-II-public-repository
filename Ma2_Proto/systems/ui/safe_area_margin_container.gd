@tool
extends MarginContainer
class_name SafeAreaMarginContainer

static var _safe_area_containers:Dictionary[SafeAreaMarginContainer, bool]
static var _top_margin_override:int = -1

static func set_top_margin_override(margin:int = -1):
	_top_margin_override = margin

	for c in _safe_area_containers:
		c._update_safe_area(true)

static func _add_area_container(c:SafeAreaMarginContainer):
	_safe_area_containers[c] = true

static func _remove_area_container(c:SafeAreaMarginContainer):
	_safe_area_containers.erase(c)

# Minimum extra margins beyond safe area
@export var min_vertical_margin: int = 15:
	set(value):
		min_vertical_margin = value
		_update_safe_area(true)

@export var min_horizontal_margin: int = 0:
	set(value):
		min_horizontal_margin = value
		_update_safe_area(true)

# Apply safe area margins on horizontal/vertical sides
@export var apply_vertical: bool = true:
	set(value):
		apply_vertical = value
		_update_safe_area(true)

@export var apply_horizontal: bool = false:
	set(value):
		apply_horizontal = value
		_update_safe_area(true)

# Equalize margins
@export var equalize_vertical_margins: bool = true:
	set(value):
		equalize_vertical_margins = value
		_update_safe_area(true)

@export var equalize_horizontal_margins: bool = false:
	set(value):
		equalize_horizontal_margins = value
		_update_safe_area(true)

# Cache to avoid unnecessary updates
var _last_window_position: Vector2i
var _last_window_size: Vector2i
var _last_safe_area: Rect2i

func _enter_tree() -> void:
	_add_area_container(self)

func _exit_tree() -> void:
	_remove_area_container(self)

func _process(_delta: float) -> void:
	_update_safe_area()

func _update_safe_area(force:bool = false) -> void:
	var window_size: Vector2i = get_window_size()
	var safe_area: Rect2i = get_safe_area()
	var window_position: Vector2i = get_window_position()

	if not force:
		if window_size == _last_window_size and safe_area == _last_safe_area and window_position == _last_window_position:
			return

	var left: 	float = 0
	var top: 	float = 0
	var right: 	float = 0
	var bottom: float = 0

	if _top_margin_override >= 0:
		# Use margin overrides
		var s := get_tree().root.content_scale_size
		var vws := get_tree().root.get_viewport().get_window().size
		top = _top_margin_override*(s.y/float(vws.y))
	else:
		# Margins are calculated relative to the window
		left	= float(safe_area.position.x - window_position.x)
		top		= float(safe_area.position.y - window_position.y)
		right 	= float((window_position.x + window_size.x) - (safe_area.position.x + safe_area.size.x))
		bottom 	= float((window_position.y + window_size.y) - (safe_area.position.y + safe_area.size.y))

	# Adjust for Android cutouts
	var cutouts: Array = DisplayServer.get_display_cutouts()
	for cutout in cutouts:
		# Cutout is Rect2, positioned in screen coordinates
		if cutout.position.x <= safe_area.position.x: # Left edge
			left = max(left, float(cutout.size.x))
		if cutout.position.y <= safe_area.position.y: # Top edge
			top = max(top, float(cutout.size.y))
		if cutout.position.x + cutout.size.x >= safe_area.position.x + safe_area.size.x: # Right edge
			right = max(right, float(cutout.size.x))
		if cutout.position.y + cutout.size.y >= safe_area.position.y + safe_area.size.y: # Bottom edge
			bottom = max(bottom, float(cutout.size.y))

	# Apply minimum margins
	left = max(left, float(min_horizontal_margin))
	right = max(right, float(min_horizontal_margin))
	top = max(top, float(min_vertical_margin))
	bottom = max(bottom, float(min_vertical_margin))

	# Equalize if requested
	if equalize_horizontal_margins:
		var max_h: float = max(left, right)
		left = max_h
		right = max_h
	if equalize_vertical_margins:
		var max_v: float = max(top, bottom)
		top = max_v
		bottom = max_v

	# Apply margins to MarginContainer
	add_theme_constant_override("margin_left", int(left) if apply_horizontal else min_horizontal_margin)
	add_theme_constant_override("margin_right", int(right) if apply_horizontal else min_horizontal_margin)
	add_theme_constant_override("margin_top", int(top) if apply_vertical else min_vertical_margin)
	add_theme_constant_override("margin_bottom", int(bottom) if apply_vertical else min_vertical_margin)

	_last_window_position = window_position
	_last_window_size = window_size
	_last_safe_area = safe_area


# ======= Utility functions =======
static func get_window_position() -> Vector2i:
	return DisplayServer.window_get_position()

static func get_window_size() -> Vector2i:
	return DisplayServer.window_get_size_with_decorations()

static func get_safe_area() -> Rect2i:
	return DisplayServer.get_display_safe_area()
