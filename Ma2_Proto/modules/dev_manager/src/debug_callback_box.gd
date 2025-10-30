class_name DebugCallbackBox extends Node

@export var enable_button:Button
@export var content_container:Control
@export var label_id:Label
@export var label_text:RichTextLabel

var _callback:Callable
var _sub_boxes:Dictionary

var parent_box:DebugCallbackBox
var path:String

func _ready():
	set_enabled(enable_button.button_pressed)
	enable_button.toggled.connect(set_enabled)

func set_callback(callback:Callable):
	_callback = callback

func set_id(id:String):
	label_id.text = id

func set_enabled(enabled:bool):
	set_process(enabled)
	content_container.visible = enabled
	if !_callback.is_valid():
		label_text.text = ""

func add_sub_box(sub:DebugCallbackBox):
	sub.parent_box = self
	content_container.add_child(sub)
	_sub_boxes[sub] = true

# returns true if this box should also be deleted
func inform_sub_box_deletion(sub:DebugCallbackBox) -> bool:
	if _sub_boxes.has(sub):
		_sub_boxes.erase(sub)
		if _sub_boxes.size() <= 0 && !_callback.is_valid():
			return true

	return false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _callback.is_valid():
		var text:String = _callback.call();
		label_text.text = text;
		print(text);
