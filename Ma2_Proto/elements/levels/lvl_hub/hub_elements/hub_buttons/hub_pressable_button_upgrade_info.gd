class_name UpgradeInfoPressableButton extends PressableButton

@export var index_in_upgrade_set:int

@export var label_allocated_stars:Label3D
@export var label_progress:Label3D

var _current_info:UpgradeInfo

func on_hub_upgrade_set_selected(selected_set:UpgradeSet):
	_update_set(null)

func on_hub_upgrade_index_selected(index:int):
	set_toggle_no_signal(index_in_upgrade_set == index)

func on_meta_updated():
	_update_set(HUBLevel.instance._selected_upgrade_set)

func on_hub_upgrade_set_button_connected():
	_update_set(HUBLevel.instance.get_selected_upgrade_set())

func _update_set(selected_set:UpgradeSet):
	if !graphic: return

	_current_info = null

	if selected_set:
		_current_info = selected_set.get_upgrade(index_in_upgrade_set)

	if _current_info:
		label_allocated_stars.show()
		label_allocated_stars.text = str(_current_info.get_allocated_stars())
		if label_progress:
			label_progress.show()
			label_progress.text = _current_info.get_progress_text()
		graphic.set_button_color(selected_set.color)
		graphic.set_button_highlight_color(selected_set.color_highlight)
		graphic.set_icon(_current_info.upgrade_icon)
		graphic.set_icon_color(Color.WHITE)
	else:
		label_allocated_stars.hide()
		if label_progress:
			label_progress.hide()
		graphic.set_button_color(MA2Colors.GREY_DARK)
		graphic.set_button_highlight_color(MA2Colors.GREY)
		graphic.set_icon(null)
		graphic.set_icon_color(MA2Colors.GREY_LIGHT)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	toggle_mode = true
	_is_toggled = false

	super._ready()

	if HUBLevel.instance:
		toggled_on.connect(on_toggled_on)
		toggled_off.connect(on_toggled_off)
		HUBLevel.instance.upgrade_set_selected.connect(on_hub_upgrade_set_selected)
		HUBLevel.instance.upgrade_index_selected.connect(on_hub_upgrade_index_selected)
		HUBLevel.instance.upgrade_set_button_connected.connect(on_hub_upgrade_set_button_connected)

	on_hub_upgrade_set_selected(null)

func _enter_tree() -> void:
	Ma2MetaManager.meta_updated.connect(on_meta_updated)

func _exit_tree() -> void:
	Ma2MetaManager.meta_updated.disconnect(on_meta_updated)

func on_toggled_on():
	if _current_info:
		HUBLevel.instance.select_upgrade_index(index_in_upgrade_set)
	else:
		set_toggle_no_signal(false)

func on_toggled_off():
	HUBLevel.instance.deselect_upgrade_index()
