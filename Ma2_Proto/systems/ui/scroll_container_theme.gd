extends ScrollContainer
@export var _v_scroll_bar_theme: String
@export var _h_scroll_bar_theme: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var v_scroll:VScrollBar = get_v_scroll_bar()
	var h_scroll:HScrollBar = get_h_scroll_bar()
	v_scroll.theme_type_variation = _v_scroll_bar_theme
	h_scroll.theme_type_variation = _h_scroll_bar_theme
