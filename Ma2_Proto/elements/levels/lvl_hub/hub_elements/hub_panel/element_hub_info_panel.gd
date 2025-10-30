class_name HUBInfoPanel extends Control

const ICON_LVL_SELECTION = preload("res://elements/icons/icon_lvl_selection_screen.png")
const ICON_STAR = preload("res://elements/icons/icon_star.png")
const ICON_STAR_EMPTY = preload("res://elements/icons/icon_star_empty.png")

enum State{
	ShowingLevelInfo,
	ShowingStarsInfo,
}

@export var _to_set_self_modulate:Array[Control]
@export var _on_off_anim:Switch_Oning_Offing_AnimationPlayer
@export var _upgrading_screen_animation:Switch_Oning_Offing_AnimationPlayer
@export var _upgrade_info_display:UpgradeInfoDisplay
@export var _upgrade_set_display:UpgradeSetDisplay
@export var _tabs:TabContainer
@export var _stars_container:Control
@export var _lvl_incomplete_display:LevelInfoDisplay
@export var _info_title:Label
@export var _label_level_highscore:Label
@export var _lvl_score_container:Control
@export var _lvl_score_label:Label
@export var _lvl_leaderboards_button:LeaderboardButton
@export var _screen_icon:TextureRect
@export var _manual_movement_multiplier:float = 60;

var _star_info_displays:Array[StarInfoDisplay]

var _current_state:State
var _current_level_info:LevelInfo

var initial_pos:Vector2;

func _ready() -> void:
	visible = false

	for child in _stars_container.get_children():
		if child is StarInfoDisplay:
			_star_info_displays.append(child)

	HUBLevel.instance.upgrade_set_selected.connect(on_hub_upgrade_set_selected)
	HUBLevel.instance.upgrade_index_selected.connect(on_hub_upgrade_index_selected)
	HUBLevel.instance.upgrading_stats_updated.connect(on_hub_upgrading_stats_updated)

	initial_pos = self.position;

func _process(delta: float) -> void:
	if LevelCameraController.instance:
		var manual_pos:Vector3 = LevelCameraController.instance.get_manual_position();
		self.position = initial_pos - _manual_movement_multiplier * Vector2(manual_pos.x, manual_pos.z);
		#self.position = -LevelCameraController.instance.get_manual_position();

func reset_to_current_screen():
	match _current_state:
		State.ShowingLevelInfo:
			show_level_info()
		State.ShowingStarsInfo:
			show_stars_info()

func on_hub_upgrade_set_selected(new_set:UpgradeSet):
	if _current_state == State.ShowingStarsInfo:
		show_stars_info()

func on_hub_upgrade_index_selected(new_index:int):
	if _current_state == State.ShowingStarsInfo:
		show_stars_info()

func on_hub_upgrading_stats_updated(start:int, end:int, current:int):
	if start == end:
		_upgrading_screen_animation.set_switch(false)
	else:
		_upgrading_screen_animation.set_switch(true)

func panel_hide():
	_on_off_anim.set_switch(false)

func panel_show():
	_on_off_anim.set_switch(true)

func set_level_info(info:LevelInfo):
	_current_level_info = info
	if _current_state == State.ShowingLevelInfo:
		show_level_info()

func show_stars_info():
	_current_state = State.ShowingStarsInfo

	if Ma2MetaManager.get_upgrade_unlock_stage() == 0:
		_set_header("hub_info_unfinished_title")
		_screen_icon.texture = ICON_STAR_EMPTY
		_set_bg_color(MA2Colors.SKY_BLUE)
		_tabs.current_tab = 6
		return

	HUDCoins.instance.add_hud_request(self)

	var selected_upgrade_set:UpgradeSet = HUBLevel.instance.get_selected_upgrade_set()
	var selected_upgrade_info:UpgradeInfo = HUBLevel.instance.get_selected_upgrade_info()

	if selected_upgrade_info:
		_upgrade_info_display.set_info(selected_upgrade_info)
		_set_header(selected_upgrade_set.set_id)
		_screen_icon.texture = selected_upgrade_info.upgrade_icon
		_set_bg_color(selected_upgrade_set.color_highlight)
		_tabs.current_tab = 3
	elif selected_upgrade_set:
		_upgrade_set_display.set_upgrade_set(selected_upgrade_set)
		_set_header(selected_upgrade_set.set_id)
		_screen_icon.texture = selected_upgrade_set.icon
		_set_bg_color(selected_upgrade_set.color)
		_tabs.current_tab = 4
	else:
		_set_header("hub_info_upgrades_title")
		_screen_icon.texture = ICON_STAR
		_set_bg_color(MA2Colors.SKY_BLUE)
		_tabs.current_tab = 5

func show_level_info():
	_current_state = State.ShowingLevelInfo

	HUDCoins.instance.remove_hud_request(self)

	var info = _current_level_info
	if !info:
		_set_header("hub_info_level_title")
		_screen_icon.texture = ICON_LVL_SELECTION
		_set_bg_color(MA2Colors.GREENISH_BLUE_DARK)
		_tabs.current_tab = 2
		return
	else:
		_set_header(info.lvl_id)
		_screen_icon.texture = info.lvl_icon
		_set_bg_color(info.lvl_color)

		if info.is_complete():
			_tabs.current_tab = 0
			_label_level_highscore.text = info.get_highscore_text()
			_lvl_leaderboards_button.leaderboard_to_show = info._leaderboard_id
		else:
			_tabs.current_tab = 1
			_lvl_incomplete_display.set_level(info)

		while _star_info_displays.size() < info.star_list.size() + 1:
			var new_star = _star_info_displays[0].duplicate()
			_stars_container.add_child(new_star)
			_star_info_displays.append(new_star)

		var i:int = 0
		for display in _star_info_displays:
			if i >= info.star_list.size():
				display.set_star(null)
			else:
				display.set_star(info.star_list[i], info)
			i += 1

func _set_header(title:String, lvl_score:int = -1):
	_info_title.text = title
	_info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lvl_score_container.hide()

	if lvl_score > 0:
		_lvl_score_label.text = str(lvl_score)
		_lvl_score_container.show()
		_info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

func _set_bg_color(color:Color):
	for to_set in _to_set_self_modulate:
		to_set.self_modulate = color
