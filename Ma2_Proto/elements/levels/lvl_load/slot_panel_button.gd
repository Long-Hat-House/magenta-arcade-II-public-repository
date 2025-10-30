extends Control

const LEVEL_TRANSITION_SIDESLIDE = preload("res://systems/level/level_transition_sideslide.tscn")
const LVL_INFO_HUB:LevelInfo = preload("res://elements/levels/lvl_info_hub.tres")
const ICON_LOCKED = preload("res://elements/icons/icon_locked.png")

@export var slot_id:StringName = "slot_"
@export var debug_only:bool = false

@export_group("setup")
@export var level_infos:Array[LevelInfo]
@export var arcade_info:LevelInfo
@export var arcade_icon_texture_rect:TextureRect
@export var tab_container:TabContainer
@export var controler_info:Control
@export var label_slot_name:Label
@export var label_slot_number:Label
@export var label_slot_creation:Label
@export var label_star_count:Label
@export var label_coins_amount:Label
@export var label_playtime:Label
@export var label_playtime_full:Label
@export var label_last_played:Label
@export var level_info_container:Control
@export var line_edit_slot_name:LineEdit

var _save:GameSave

func _ready() -> void:
	_set_tab_loading()
	print("[SlotButton] " + slot_id + " - Will Ready")
	SaveManager.use_save_by_name(slot_id, _on_save_ready)

	if debug_only:
		DevManager.settings_changed.connect(_on_settings_changed)
		_on_settings_changed()

func _on_settings_changed():
	visible = DevManager.get_setting(DevManager.SETTING_DEBUG_UI_ENABLED)

func _set_tab_loading():
	print("[SlotButton] " + slot_id + " - Set Tab Loading")
	tab_container.current_tab = 3

func _on_save_ready(save:GameSave):
	print("[SlotButton] " + slot_id + " - Save is Ready")
	_save = save
	_update_tab_info()
	_save.loading_started.connect(_set_tab_loading)
	_save.loading_finished.connect(_update_tab_info)
	
func _update_tab_info():
	print("[SlotButton] " + slot_id + " - Updating Tab")
	if _save.is_empty():
		tab_container.current_tab = 0
	else:
		tab_container.current_tab = 1
		if label_slot_name:
			label_slot_name.text = Ma2MetaManager.peek_slot_name(_save)
		if label_slot_number:
			label_slot_number.text = str(Ma2MetaManager.peek_slot_number(_save))
		var completed_levels = Ma2MetaManager.peek_completed_levels(_save)
		var unlocked_levels = Ma2MetaManager.peek_unlocked_levels(_save)
		var unlocked_stars_count:int = Ma2MetaManager.peek_unlocked_stars_count(_save)
		var coins_amount:int = Ma2MetaManager.peek_coins_amount(_save)
		label_slot_creation.text = Ma2MetaManager.peek_creation_date(_save)
		label_playtime.text = Ma2MetaManager.peek_playtime_text(_save, false)
		label_playtime_full.text = Ma2MetaManager.peek_playtime_text(_save, true)
		label_last_played.text = Ma2MetaManager.peek_last_played_date(_save)

		label_star_count.text = "%d" % [unlocked_stars_count]
		label_coins_amount.text = "%d" % [coins_amount]

		var ts:Array[TextureRect]
		for child in level_info_container.get_children():
			if child is TextureRect:
				if ts.size() >= level_infos.size():
					child.queue_free()
				else:
					ts.append(child)

		if unlocked_levels.keys().has(arcade_info.lvl_id):
			arcade_icon_texture_rect.visible = true
			arcade_icon_texture_rect.texture = arcade_info.lvl_icon
			if completed_levels.keys().has(arcade_info.lvl_id):
				arcade_icon_texture_rect.modulate = arcade_info.lvl_color_highlight
			else:
				arcade_icon_texture_rect.modulate = MA2Colors.GREY_LIGHT
		else:
			arcade_icon_texture_rect.visible = false

		var i:int = 0
		for info in level_infos:
			var t:TextureRect
			if i >= ts.size():
				t = ts[0].duplicate()
				level_info_container.add_child(t)
				ts.append(t)
			else:
				t = ts[i]

			if info && unlocked_levels.keys().has(info.lvl_id):
				t.texture = info.lvl_icon
				if completed_levels.keys().has(info.lvl_id):
					t.modulate = info.lvl_color_highlight
				else:
					t.modulate = MA2Colors.GREY_LIGHT
			else:
				t.texture = ICON_LOCKED
				t.modulate = Color.WHITE
			i += 1

func _on_button_pressed() -> void:
	Ma2MetaManager.set_current_save(_save)
	LevelManager.change_with_transition(LEVEL_TRANSITION_SIDESLIDE, LVL_INFO_HUB)
	#LevelManager.change_level_by_info(LVL_INFO_HUB)

func _on_clear_save_button_pressed() -> void:
	PromptWindow.new_prompt(
		Ma2MetaManager.peek_slot_name(_save),
		"menu_files_delete_warning",
		func(i:int):
			if i == 0:
				_save.clear_save()
				_on_save_ready(_save)
			,
		["menu_files_delete_confirm", "menu_cancel"]
		)


func _on_exit_edits_button_pressed() -> void:
	tab_container.current_tab = 1
	if line_edit_slot_name:
		Ma2MetaManager.set_save_slot_name(_save, line_edit_slot_name.text)
	if label_slot_name:
		label_slot_name.text = Ma2MetaManager.peek_slot_name(_save)

func _on_start_edit_button_pressed() -> void:
	if line_edit_slot_name:
		line_edit_slot_name.text = Ma2MetaManager.peek_slot_name(_save)
	tab_container.current_tab = 2
