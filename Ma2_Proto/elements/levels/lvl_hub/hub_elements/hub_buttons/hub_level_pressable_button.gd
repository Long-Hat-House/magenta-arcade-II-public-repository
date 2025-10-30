class_name HUBLevelPressableButton extends PressableButton

const ICON_LOCKED = preload("res://elements/icons/icon_locked.png")

@export var stars_info:Node3D

@export var material_star_unlocked:Material
@export var material_star_normal:Material

@export var hide_if_locked:bool = false

@export var level_info:LevelInfo:
	set(val):
		if level_info != val:
			level_info = val
		update_graphic_with_level_info()
	get():
		return level_info

func on_graphic_set():
	super.on_graphic_set()
	update_graphic_with_level_info()

func update_graphic_with_level_info():
	print("Updating graphics!")
	if !graphic: return

	var stars_infos:Array = stars_info.get_children()
	var star1:MeshInstance3D = stars_infos[0]
	var star2:MeshInstance3D = stars_infos[1]
	var star3:MeshInstance3D = stars_infos[2]

	if level_info && level_info.is_unlocked():
		if hide_if_locked:
			visible = true
			set_disabled(false)

		graphic.set_button_color(level_info.lvl_color)
		graphic.set_button_highlight_color(level_info.lvl_color_highlight)
		graphic.set_icon(level_info.lvl_icon)
		graphic.set_icon_color(Color.WHITE)

		if level_info.is_complete():
			var stars:Array[StarInfo] = level_info.star_list
			star1.visible = stars.size() > 0
			star2.visible = stars.size() > 1
			star3.visible = stars.size() > 2

			if star1.visible:
				star1.material_override = material_star_unlocked if stars[0].is_unlocked() else material_star_normal
			if star2.visible:
				star2.material_override = material_star_unlocked if stars[1].is_unlocked() else material_star_normal
			if star3.visible:
				star3.material_override = material_star_unlocked if stars[2].is_unlocked() else material_star_normal
	else:
		if hide_if_locked:
			visible = false
			set_disabled(true)
		else:
			star1.material_override = material_star_normal
			star2.material_override = material_star_normal
			star3.material_override = material_star_normal
			graphic.set_button_color(MA2Colors.GREY_DARK)
			graphic.set_button_highlight_color(MA2Colors.GREY)
			graphic.set_icon(ICON_LOCKED)
			graphic.set_icon_color(MA2Colors.GREY_LIGHT)

func on_hub_level_selected(selected_level:LevelInfo):
	if level_info:
		set_toggle_no_signal(selected_level == level_info)
	else:
		set_toggle_no_signal(false)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	toggle_mode = true
	_is_toggled = false

	super._ready()

	if HUBLevel.instance:
		toggled_on.connect(on_toggled_on)
		toggled_off.connect(on_toggled_off)
		HUBLevel.instance.level_selected.connect(on_hub_level_selected)

	update_graphic_with_level_info()

func _enter_tree() -> void:
	Ma2MetaManager.meta_updated.connect(update_graphic_with_level_info)

func _exit_tree() -> void:
	Ma2MetaManager.meta_updated.disconnect(update_graphic_with_level_info)

func on_toggled_on():
	if level_info:
		HUBLevel.instance.select_level(level_info)
	else:
		HUBLevel.instance.select_level(null)

func on_toggled_off():
	HUBLevel.instance.select_level(null)
