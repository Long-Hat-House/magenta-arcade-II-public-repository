class_name UpgradeSetPressableButton extends PressableButton

@export var upgrade_set:UpgradeSet

@export var label_allocated_stars:Label3D

func update_graphics():
	if !graphic: return

	if upgrade_set:
		label_allocated_stars.show()
		label_allocated_stars.text = str(upgrade_set.get_allocated_summed_stars())
		graphic.set_button_color(upgrade_set.color)
		graphic.set_button_highlight_color(upgrade_set.color_highlight)
		graphic.set_icon(upgrade_set.icon)
		graphic.set_icon_color(Color.WHITE)
	else:
		label_allocated_stars.hide()
		graphic.set_button_color(MA2Colors.GREY_DARK)
		graphic.set_button_highlight_color(MA2Colors.GREY)
		graphic.set_icon(null)
		graphic.set_icon_color(MA2Colors.GREY_LIGHT)

func on_hub_upgrade_set_selected(selected_set:UpgradeSet):
	if upgrade_set:
		set_toggle_no_signal(selected_set == upgrade_set)

func on_meta_updated():
	update_graphics()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	toggle_mode = true
	_is_toggled = false
	disallow_untogle = false
	graphic.graphic_turned_on.connect(HUBLevel.instance.upgrade_set_button_connected.emit)

	super._ready()

	if HUBLevel.instance:
		toggled_on.connect(on_toggled_on)
		toggled_off.connect(on_toggled_off)
		HUBLevel.instance.upgrade_set_selected.connect(on_hub_upgrade_set_selected)

	update_graphics()

func _enter_tree() -> void:
	Ma2MetaManager.meta_updated.connect(on_meta_updated)

func _exit_tree() -> void:
	Ma2MetaManager.meta_updated.disconnect(on_meta_updated)

func on_toggled_on():
	if upgrade_set:
		HUBLevel.instance.select_upgrade_set(upgrade_set)

func on_toggled_off():
	if upgrade_set:
		HUBLevel.instance.deselect_upgrade_set()
