class_name Game extends Node3D

const LEVEL_TRANSITION = preload("res://systems/level/level_transition.tscn")
const LEVEL_TRANSITION_FADEOUT = preload("res://systems/level/level_transition_fadeout.tscn")
const LEVEL_TRANSITION_SIDESLIDE = preload("res://systems/level/level_transition_sideslide.tscn")

const LVL_INFO_HUB = preload("res://elements/levels/lvl_info_hub.tres")

static var instance:Game

const ICON_COIN = preload("res://elements/icons/icon_coin.png")
const ICON_SCORE = preload("res://elements/icons/icon_score.png")
const ICON_TIME = preload("res://elements/icons/icon_time.png")
const ICON_STAR = preload("res://elements/icons/icon_star.png")
const ICON_ENEMY = preload("res://elements/icons/icon_lvl_selection_screen.png")

static func get_time_text_from_sec(seconds:int) -> String:
	var minutes:int = seconds/60
	seconds = seconds - minutes*60
	return "%02d:%02d" % [minutes, seconds]

enum Target_Style{
	Nearest,
	Medium
}

signal level_clear()

@export_group("menus")
@export var _game_over_scene:PackedScene
@export var _level_clear_scene:PackedScene

@export_group("General Objects Configuration")
@export var enemy_positional_node_group_name:String = "enemy_position";
@export var enemy_health_group_name:String = "enemy_healths";
@export var enemy_projectile_group_name:String = "enemy_projectile";

var _game_timer:float = 0
var _game_timer_paused:bool = false

var _skip_first_frame:bool = true

var _game_finished:bool = false


var _bad_menu_buttons:Array[Button]

func get_timer() -> float: return _game_timer

func create_exit_menu_button():
	var button = UIFactory.get_button()
	button.text = "menu_give_up"
	button.theme_type_variation = "button_magenta_main"
	button.pressed.connect(func():
		PromptWindow.new_prompt_advanced("menu_give_up", "menu_give_up_text",
		func(opt:int):
			if opt == 0:
				HUD.instance.hide()
				LevelManager.change_with_transition(LEVEL_TRANSITION, LVL_INFO_HUB)
			elif opt == 1:
				HUD.instance.hide()
				LevelManager.change_with_transition(LEVEL_TRANSITION_FADEOUT, LevelManager.current_level_info)
		,
		[
			PromptWindow.PromptEntry.new(PromptWindow.PromptEntry.EntryStyle.VBoxBegin),
			PromptWindow.PromptEntry.CreateButton("menu_back_to_hub", 0, true),
			PromptWindow.PromptEntry.CreateButton("menu_restart", 1, true),
			PromptWindow.PromptEntry.new(PromptWindow.PromptEntry.EntryStyle.BoxEnd),
		]
		))

	Menu.add_element(button)
	_bad_menu_buttons.append(button)

func _ready():
	instance = self
	pause_timer()

	ObjectPool.clear_all();
	if LevelManager.current_level_info.is_arcade_mode:
		LevelShopStagePiece.arcade_shop_clear()
	TextFlowPlayer.CLEAR_GLOBAL_SPEAKERS()
	Menu.set_info("menu_pause_title", "menu_pause_text")

	create_exit_menu_button()

	await get_tree().process_frame

	LevelManager.current_level.level_finished.connect(_on_level_finished)
	Player.instance.dead.connect(_on_player_dead)
	Player.instance.finger_took_damage.connect(_on_player_took_damage)

	var lvl_info:LevelInfo = LevelManager.current_level_info
	if lvl_info:
		var star_time:float = -1
		for star in lvl_info.star_list:
			if star.type == StarInfo.StarType.TargetTime:
				var time = star.get_target_time()
				if star_time < time:
					star_time = time

		HUD.instance.timer.set_times(lvl_info.score_max_seconds)


func _exit_tree() -> void:
	_on_scene_end_finally();
	for button in _bad_menu_buttons:
		button.queue_free()

func _process(delta:float):
	if !HUD.instance:
		return;

	if _skip_first_frame:
		_skip_first_frame = false
		return

	if _game_finished: return

	var time_multiplier = 1
	if Input.is_key_pressed(KEY_2):
		time_multiplier = 50

	if !_game_timer_paused:
		_game_timer += delta * time_multiplier;
	HUD.instance.set_seconds_in_game(_game_timer)

func pause_timer():
	_game_timer_paused = true

func release_timer():
	_game_timer_paused = false

func kill_all_enemies(force_kill:bool = true):
	for node:Node in get_tree().get_nodes_in_group(enemy_health_group_name):
		var hNode:Health = node as Health;
		if hNode and (force_kill or hNode.can_process()):
			hNode.kill();

func kill_all_projectiles():
	for node:Node in get_tree().get_nodes_in_group(enemy_projectile_group_name):
		if node.has_method("projectile_kill"):
			node.projectile_kill();
		else:
			ObjectPool.repool(node);

func get_best_direction_to(from:Node3D, group_name:StringName, style:Target_Style = Target_Style.Nearest)->Vector3:
	var array:Array = get_tree().get_nodes_in_group(group_name);
	if not array.is_empty():
		var target:Vector3 = get_target_from_vector(from, array, style);
		var direction:Vector3 = target - from.global_position;
		direction.y = 0;
		return direction;
	return Vector3.ZERO;

static func get_target_from_vector(from: Node3D, targets:Array, where:Target_Style)->Vector3:
	var p:Vector3 = from.global_position;
	match where:
		Target_Style.Nearest:
			var nearest:Node3D = null;
			var nearest_value:float = 999999;
			for target in targets:
				if target is Node3D:
					if not target.can_process():
						continue;
					var dist:float = (target.global_position - p).length_squared();
					if dist < nearest_value:
						nearest_value = dist;
						nearest = target;
			if nearest:
				return nearest.global_position;
		Target_Style.Medium:
			var sum:Vector3 = Vector3.ZERO;
			var count:int = 0;
			for target in targets:
				if target is Node3D:
					if not target.can_process():
						continue;
					count += 1;
					sum += target.global_position;
			if count > 0:
				return sum / count;
	return Vector3.ZERO;

func _on_scene_end_finally():
	ObjectPool.clear_all();

func _menu_performance_lines(menu:GameOverMenu) -> int:
	var lvl_info:LevelInfo = LevelManager.current_level_info

	menu.add_group(ICON_SCORE)

	var score:int = ScoreManager.instance.get_current_score()


	var previous_highscore = Ma2MetaManager.get_highscore(lvl_info)
	var invalidated:bool = ScoreManager.instance.SCORE_INVALIDATED
	lvl_info.submit_score(score, invalidated)

	var prev_highscore_text:String = StarInfo.get_score_text(previous_highscore) if previous_highscore >= 0 else "-"
	if score > previous_highscore:
		menu.add_line("menu_levelclear_record_current", prev_highscore_text, null, GameOverMenu.LineStyle.Superscript, GameOverLine.LineColor.Bad)
		menu.add_separator()
		menu.add_line("menu_levelclear_score_final", StarInfo.get_score_text(score), ICON_SCORE, GameOverMenu.LineStyle.Title, GameOverLine.LineColor.Good)
		menu.add_line("menu_levelclear_record_new", StarInfo.get_score_text(score), null, GameOverMenu.LineStyle.Notification, GameOverLine.LineColor.Good)
	else:
		menu.add_line("menu_levelclear_record_current", prev_highscore_text, ICON_SCORE, GameOverMenu.LineStyle.Superscript)
		menu.add_separator()
		menu.add_line("menu_levelclear_score_final", StarInfo.get_score_text(score), null, GameOverMenu.LineStyle.Title, GameOverLine.LineColor.Bad)
	if invalidated:
		menu.add_line("SCORE INVALIDATED", "", null, GameOverMenu.LineStyle.Notification, GameOverLine.LineColor.Bad)

	return score

func _menu_coin_lines(menu:GameOverMenu, lost:bool = false) -> int:
	menu.add_group(ICON_COIN)

	var coins:int = ScoreManager.instance.get_current_score()

	menu.add_line("menu_gameover_coins_tax", "10%", ICON_COIN)
	coins = coins * 0.1

	if lost:
		menu.add_line("menu_gameover_coins_fee", "-50%", ICON_COIN, GameOverMenu.LineStyle.Default, GameOverLine.LineColor.Bad)
		coins = coins * 0.5

	menu.add_separator()
	menu.add_line("menu_gameover_coins_final", HUDCoins.get_coins_text(coins), ICON_COIN, GameOverMenu.LineStyle.Title)
	Ma2MetaManager.gain_coins(coins)

	return coins

func _on_player_dead():
	if _game_finished: return
	_game_finished = true

	HUD.instance.hide()
	Menu.hide()
	Player.instance.remove_all_touches()

	var menu:GameOverMenu = _game_over_scene.instantiate();
	LevelManager.add_child(menu);

	menu.set_level(LevelManager.current_level_info)
	menu.set_performance(ScoreManager.instance.get_current_score_text())

	_menu_coin_lines(menu, true)

	#await get_tree().create_timer(0.5).timeout
	TimeManager.remove_all_time_changes()
	get_tree().paused = true

func _on_player_took_damage(token:PlayerToken):
	pass

func _on_level_finished():
	if _game_finished: return
	_game_finished = true

	level_clear.emit()

	HUD.instance.hide()
	Menu.hide()
	Player.instance.remove_all_touches()
	ScoreManager.instance.finish_combo()
	

	var menu:GameOverMenu = _level_clear_scene.instantiate();
	LevelManager.add_child(menu);

	var lvl_info = LevelManager.current_level_info

	var new_lvl_complete:bool = lvl_info.set_complete()

	menu.set_level(lvl_info)
	menu.set_performance(ScoreManager.instance.get_current_score_text())

	menu.add_group(lvl_info.lvl_icon)
	menu.add_line("menu_levelclear_title", lvl_info.lvl_id, lvl_info.lvl_icon)
	menu.add_separator()
	menu.add_line("menu_levelclear_time", get_time_text_from_sec(_game_timer), ICON_TIME, GameOverMenu.LineStyle.Title)
	menu.add_resume(get_time_text_from_sec(_game_timer), ICON_TIME)

	var coins:int = _menu_coin_lines(menu, false)
	menu.add_resume(HUDCoins.get_coins_text(coins), ICON_COIN)
	var score:int = _menu_performance_lines(menu)
	menu.add_resume(StarInfo.get_score_text(score), ICON_SCORE)

	menu.add_group(ICON_STAR)
	var stars_group:GameOverLineStarsAll = menu.add_stars_line()

	var new_star_unlocked:bool

	for star:StarInfo in lvl_info.star_list:
		new_star_unlocked = false
		match star.type:
			StarInfo.StarType.LevelComplete:
				new_star_unlocked = star.set_unlocked()
			StarInfo.StarType.TargetTime:
				if _game_timer <= star.get_target_time():
					new_star_unlocked = star.set_unlocked()
			StarInfo.StarType.TargetScore:
				if score >= star.get_target_score():
					new_star_unlocked = star.set_unlocked()
				pass
			_:
				pass

		var style:GameOverMenu.LineStyle = GameOverMenu.LineStyle.StarLocked
		if star.is_unlocked():
			style = GameOverMenu.LineStyle.StarNew if new_star_unlocked else GameOverMenu.LineStyle.StarUnlocked

		stars_group.add_star(star.get_target_score(), star.is_unlocked(), new_star_unlocked)
#
