class_name LevelSetViewer extends VBoxContainer

@export var level_selection_button:Button
@export var set_foldout_button:Button
@export var child_container:VBoxContainer
@export var setbox:Control

func _ready() -> void:
	set_foldout_button.toggled.connect(func(val:bool): setbox.visible = val)

	DevManager.settings_changed.connect(
		func():
			set_foldout_button.visible = DevManager.get_setting(DevManager.SETTING_SUBLEVELS_ENABLED)
	)
	set_foldout_button.visible = DevManager.get_setting(DevManager.SETTING_SUBLEVELS_ENABLED)

func _enter_tree() -> void:
	if child_container.get_child_count() == 0:
		set_foldout_button.visible = false
		setbox.visible = false
	else:
		setbox.visible = set_foldout_button.button_pressed

func set_text(text:String):
	level_selection_button.text = text

func set_level_selection_callback(callback:Callable):
	if callback.is_valid():
		level_selection_button.pressed.connect(callback)
	else:
		level_selection_button.disabled = true

func add_set_child(child:Control):
		set_foldout_button.visible = true
		child_container.add_child(child)

func set_open():
	set_foldout_button.button_pressed = true
