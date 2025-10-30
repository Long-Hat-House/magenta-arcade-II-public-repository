class_name InputUtils

static func is_input_basic_touch(input_event:InputEvent):
	var e = input_event as InputEventMouseButton
	return e && e.button_index == MOUSE_BUTTON_LEFT && e.pressed
