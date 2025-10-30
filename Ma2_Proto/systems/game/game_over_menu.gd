class_name GameOverMenu extends Control

const LVL_INFO_HUB = preload("res://elements/levels/lvl_info_hub.tres")

const GAME_OVER_LINE_DEFAULT = preload("res://elements/ui/menus/game_over_menu/game_over_line_default.tscn")
const GAME_OVER_LINE_RESUME = preload("res://elements/ui/menus/game_over_menu/game_over_line_resume.tscn")
const GAME_OVER_LINE_STAR_LOCKED = preload("res://elements/ui/menus/game_over_menu/game_over_line_star_locked.tscn")
const GAME_OVER_LINE_STAR_NEW = preload("res://elements/ui/menus/game_over_menu/game_over_line_star_new.tscn")
const GAME_OVER_LINE_STAR_UNLOCKED = preload("res://elements/ui/menus/game_over_menu/game_over_line_star_unlocked.tscn")
const GAME_OVER_LINE_TITLE = preload("res://elements/ui/menus/game_over_menu/game_over_line_title.tscn")
const GAME_OVER_LINE_SEPARATOR = preload("res://elements/ui/menus/game_over_menu/game_over_line_separator.tscn")
const GAME_OVER_LINE_SUPERSCRIPT = preload("res://elements/ui/menus/game_over_menu/game_over_line_superscript.tscn")
const GAME_OVER_LINE_NOTIFICATION = preload("res://elements/ui/menus/game_over_menu/game_over_line_notification.tscn")
const GAME_OVER_LINE_STARS_ALL = preload("res://elements/ui/menus/level_clear_menu/game_over_line_stars_all.tscn")

enum LineStyle{
	Default,
	StarLocked,
	StarUnlocked,
	StarNew,
	Separator,
	Superscript,
	Notification,
	Title,
}

@export var _sfx_start:WwiseEvent
@export var _sfx_step:WwiseEvent
@export var _sfx_step_pre:WwiseEvent
@export var _sfx_complete:WwiseEvent
@export var _level_display:LevelInfoDisplay
@export var _retry_button:Button
@export var _continue_button:Button
@export var _leaderboards_button:LeaderboardButton
@export var _skip_button:Button
@export var _group_icon:TextureRect
@export var _performance_label:Label
@export var _tip:Label
@export var _anims:AnimationPlayer
@export var _next_switch:Switch_Oning_Offing_AnimationPlayer

@export_group("Lines")
@export var _lines_container:Control
@export var _resume_container:Control

@export_group("Transitions")
@export var retry_transition_scene:PackedScene
@export var exit_transition_scene:PackedScene

var _line_groups:Array[GameOverLineGroup]

var _skipped:bool = false

func set_level(level_info:LevelInfo):
	_level_display.set_level(level_info)
	if _leaderboards_button:
		_leaderboards_button.leaderboard_to_show = level_info._leaderboard_id

func set_performance(val:String):
	_performance_label.text = val

func add_separator():
	add_line("","",null,LineStyle.Separator)

func add_resume(value:String, icon:Texture2D, comes_on:bool=false):
	if _resume_container:
		var resume:GameOverLine = GAME_OVER_LINE_RESUME.instantiate()
		resume.set_info("", value, icon)
		_resume_container.add_child(resume)
		if comes_on: resume.skip()

func add_group(group_icon:Texture2D):
	var group:GameOverLineGroup = GameOverLineGroup.new()
	group.group_icon = group_icon
	_lines_container.add_child(group)
	_line_groups.append(group)

func add_line(title:String, value:String = "", icon:Texture2D = null, style:LineStyle = LineStyle.Default, line_color:GameOverLine.LineColor = GameOverLine.LineColor.Default) -> GameOverLine:
	if _line_groups.size() <= 0:
		add_group(null)

	var line_group:GameOverLineGroup = _line_groups.back()

	var line_scene:PackedScene = GAME_OVER_LINE_DEFAULT

	match style:
		LineStyle.StarLocked:		line_scene = GAME_OVER_LINE_STAR_LOCKED
		LineStyle.StarUnlocked:		line_scene = GAME_OVER_LINE_STAR_UNLOCKED
		LineStyle.StarNew:			line_scene = GAME_OVER_LINE_STAR_NEW
		LineStyle.Title:			line_scene = GAME_OVER_LINE_TITLE
		LineStyle.Separator:		line_scene = GAME_OVER_LINE_SEPARATOR
		LineStyle.Default:			line_scene = GAME_OVER_LINE_DEFAULT
		LineStyle.Superscript:		line_scene = GAME_OVER_LINE_SUPERSCRIPT
		LineStyle.Notification:		line_scene = GAME_OVER_LINE_NOTIFICATION
		_:							line_scene = GAME_OVER_LINE_DEFAULT

	var line:GameOverLine = line_scene.instantiate()

	line.set_info(title, value, icon, line_color)
	line_group.add_child(line)

	return line

func add_stars_line() -> GameOverLineStarsAll:
	var line_group:GameOverLineGroup = _line_groups.back()
	var line:GameOverLineStarsAll = GAME_OVER_LINE_STARS_ALL.instantiate()
	line_group.add_child(line)
	return line

func show_lines():
	_skip_button.show()

	var prev_line_group:GameOverLineGroup = null
	for line_group in _line_groups:
		_skipped = false
		if prev_line_group:
			if _anims:
				_anims.play("flash")
			if _sfx_step: _sfx_step.post(self)
			await get_tree().create_timer(.2).timeout
			if _next_switch: _next_switch.set_switch(true)
			_skipped = false
			while (!_skipped):
				await get_tree().process_frame
			_skipped = false
			if _next_switch: _next_switch.set_switch(false)
			prev_line_group.hide_group()

		prev_line_group = line_group
		line_group.show_group()
		_group_icon.texture = line_group.group_icon

		for child in line_group.get_children():
			var line:GameOverLine = child as GameOverLine
			if line:
				line.line_show()
				while (!_skipped && !line.get_line_show_finished()):
					await get_tree().process_frame
				if _skipped:
					line.skip()

		if _resume_container:
			for child in _resume_container.get_children():
				var line:GameOverLine = child as GameOverLine
				if line && !line.get_line_show_finished():
					line.line_show()
					if _sfx_step_pre: _sfx_step_pre.post(self)
					while (!_skipped && !line.get_line_show_finished()):
						await get_tree().process_frame
					if _skipped:
						line.skip()
					break #only show one resume and go on.


	if _sfx_complete: _sfx_complete.post(self)
	if _next_switch: _next_switch.set_switch(false)
	if _anims:
		_anims.play("complete")
	_skip_button.hide()
	if _retry_button:
		_set_button_enabled(_retry_button, true)
	if _leaderboards_button:
		_set_button_enabled(_leaderboards_button, true)
	_set_button_enabled(_continue_button, true)

func _set_button_enabled(button:Button, enabled:bool):
	if enabled:
		button.modulate = Color.WHITE
		button.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		button.modulate = Color.TRANSPARENT
		button.process_mode = Node.PROCESS_MODE_DISABLED

func _enter_tree() -> void:
	LevelManager.removing_current_level.connect(queue_free)
	if _tip:
		var list:PackedStringArray = tr("menu_gameover_tips").split("%",false)
		var tip:String = list[randi_range(1, list.size())-1]
		tip.strip_edges()
		_tip.text = tip
	_group_icon.texture = null
	if _retry_button:
		_set_button_enabled(_retry_button, false)
		_retry_button.pressed.connect(_on_retry_button_pressed, CONNECT_ONE_SHOT)
	if _leaderboards_button:
		_set_button_enabled(_leaderboards_button, false)
	_set_button_enabled(_continue_button, false)
	_continue_button.pressed.connect(_on_continue_button_pressed, CONNECT_ONE_SHOT)

	_skip_button.pressed.connect(_on_skip_button_pressed)
	_skip_button.hide()
	if _next_switch: _next_switch.set_switch(false)

	for child in _lines_container.get_children():
		child.queue_free()

	if _resume_container:
		for child in _resume_container.get_children():
			child.queue_free()

	if HUD.instance:
		HUD.instance.hide()
	_sfx_start.post(self)

func _on_retry_button_pressed() -> void:
	await LevelManager.change_with_transition(
		retry_transition_scene,
		LevelManager.current_level_info
		)
	queue_free()

func _on_continue_button_pressed() -> void:
	await LevelManager.change_with_transition(
		exit_transition_scene,
		LVL_INFO_HUB
		)
	queue_free()

func _on_skip_button_pressed() -> void:
	_skipped = true
