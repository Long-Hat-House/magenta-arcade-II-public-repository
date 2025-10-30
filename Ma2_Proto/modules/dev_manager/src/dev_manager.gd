extends Control

const SAVE_ID_SCREENSHOT_PATH = &"DEV_MANAGER.SCREENSHOT.PATH"
const SAVE_ID_SCREENSHOT_OPTION = &"DEV_MANAGER.SCREENSHOT.OPTION"

var _screenshot_path:String = ""
var _screenshot_resolution_option:int = 0
var _original_window_size:Vector2 = Vector2.ZERO

# Resolution options dictionary
const SCREENSHOT_RESOLUTIONS:Dictionary[String, Vector3] = {
	#RESOLUTION ID - RESOLUTION WIDTH, RESOLUTION HEIGHT, SAFE AREA TOP MARGIN
	"Original": Vector3(900, 1800, 0),
	"All": Vector3.ZERO,
	"iPad13pol": Vector3(2064, 2752, 0),
	"iPhone69pol": Vector3(1320, 2868, 186),
	"iPhone65pol": Vector3(1320, 2868, 132),
}

const ICON_COIN = preload("res://elements/icons/icon_coin.png")
const ICON_DEV = preload("res://modules/dev_manager/icon_dev.png")
const ICON_CREDITS = preload("res://elements/icons/icon_credits.png")
const ICON_MANUAL = preload("res://elements/icons/icon_manual.png")

const CREDITS_IN_PAUSE = preload("res://elements/ui/menus/credits_menu/scenes/credits_in_pause.tscn")
const MANUAL_IN_PAUSE = preload("res://elements/ui/menus/manual_menu/scenes/manual_in_pause.tscn")

const SETTING_ENABLED = &"DEV_MANAGER.ENABLED"
const SETTING_DEBUG_UI_ENABLED = &"DEV_MANAGER.DEBUG_UI_ENABLED"
const SETTING_STAGE_VISUALS_ENABLED = &"DEV_MANAGER.STAGE_VISUALS_ENABLED"
const SETTING_DEV_SHORTCUTS_ENABLED = &"DEV_MANAGER.DEV_SHORTCUTS_ENABLED"
const SETTING_PLAYER_IMUNE_ENABLED = &"DEV_MANAGER.PLAYER_IMUNE"
const SETTING_INTEGRATIONS_UI_ENABLED = &"DEV_MANAGER.INTEGRATIONS_UI_ENABLED"
const SETTING_LOG_SAVE = &"DEV_MANAGER.LOG_SAVE"
const SETTING_HAS_HAND = &"DEV_MANAGER.HAS_HAND"
const SETTING_SHOW_FPS = &"DEV_MANAGER.SHOW_FPS"

const SAVE_ID_TEST_EXPORT_FEATURE = &"DEV_MANAGER.TEST_EXPORT_FEATURE"
const TEST_EXPORT_FEATURE_OPTIONS:Array[String] = ["None", "test-accessibility", "test-pitch", "test-playtesting"]

signal settings_changed()

enum ShortcutCommand{
	FinishLevel,
	SkipCutscene
}

@export var _enable_button:Button
@export var _vertical_container:Control
@export var _level_selection_menu_container:Control

@export_category("Callbacks")
@export var _debug_callback_box:PackedScene
@export var _debug_callbacks_container:Control

var debug_callbacks:Dictionary

var _settings:Dictionary

var _save:GameSave

var _initialized:bool = false

var _level_selection_menu:Control

var _dev_menu_aggregator:MenuAggregator

var _btn_select_screenshot_folder:ExtendedButton

var test_info:TestInfo:
	get:
		if has_feature("test-accessibility"):
			return load("res://modules/dev_manager/test_info_accessibility.tres")
		elif has_feature("test-pitch"):
			return load("res://modules/dev_manager/test_info_pitch.tres")
		elif has_feature("test-playtesting"):
			return load("res://modules/dev_manager/test_info_playtesting.tres")
		else:
			return null

var tools_enabled:bool:
	get: return _save && _save.get_json_parsed_data(SETTING_ENABLED, "FALSE")
	set(val): _save.set_data(SETTING_ENABLED, str(val))

var _tools_enabled_label:Label

func _ready() -> void:
	print("[DEV MANAGER] Readying")

func await_initialize() -> void:
	print("[DEV MANAGER] Initializing")
	SaveManager.use_settings(_on_save_settings_ready)
	while !_initialized:
		await get_tree().process_frame

func _on_save_settings_ready(save:GameSave):
	print("[DEV MANAGER] Initialized")
	_save = save

	_add_credits_menu()
	_add_info_menu()
	if tools_enabled:
		enable_developer_tools()
	else:
		disable_developer_tools()

	#var ag = Menu.get_aggregator(["General"])
	#ag.add_element(
		#UIFactory.get_button(
			#"menu_feedback_button",
			#OS.shell_open.bind("https://forms.gle/p9EzRbxWBVxzxc5Y8"),
			#true
		#),
		#100
		#)
	_initialized = true

func has_feature(feature:StringName) -> bool:
	return OS.has_feature(feature) or (_save && feature == TEST_EXPORT_FEATURE_OPTIONS[_save.get_json_parsed_data(SAVE_ID_TEST_EXPORT_FEATURE, str(0))])

func toggle_developer_tools():
	if tools_enabled:
		disable_developer_tools()
	else:
		enable_developer_tools()

func disable_developer_tools():
	tools_enabled = false
	set_enabled(false)
	set_setting(SETTING_DEBUG_UI_ENABLED, false)
	set_setting(SETTING_STAGE_VISUALS_ENABLED, false)
	set_setting(SETTING_DEV_SHORTCUTS_ENABLED, false)
	set_setting(SETTING_PLAYER_IMUNE_ENABLED, false)
	set_setting(SETTING_INTEGRATIONS_UI_ENABLED, false)
	if _tools_enabled_label:
		_tools_enabled_label.text = "Dev Tools 🔴 DISABLED\n(Restart to be effective)"

func enable_developer_tools():
	tools_enabled = true
	if !_dev_menu_aggregator: _add_developer_menu()
	if _tools_enabled_label:
		_tools_enabled_label.text = "Dev Tools 🟢 ENABLED"

func _add_developer_menu():
	_dev_menu_aggregator = Menu.get_aggregator(["Dev"])
	_dev_menu_aggregator.set_info("menu_developer_title", "menu_developer_text", -1, ICON_DEV)

	if !_tools_enabled_label:
		_tools_enabled_label = Label.new()
		_dev_menu_aggregator.add_element(_tools_enabled_label)

	_dev_menu_aggregator.create_prompt_button(
		 TEST_EXPORT_FEATURE_OPTIONS,
		"Select an export feature",
		"This will be used by internal code only so you need to know what you're testing",
		"Test Export Feature",
		"",
		_save,
		SAVE_ID_TEST_EXPORT_FEATURE,
		Callable(),
		null
	)

	_create_toggle_option(_dev_menu_aggregator, "Debug UI", SETTING_DEBUG_UI_ENABLED, false)
	_create_toggle_option(_dev_menu_aggregator, "Player Imune", SETTING_PLAYER_IMUNE_ENABLED, false)
	_create_toggle_option(_dev_menu_aggregator, "Integrations UI", SETTING_INTEGRATIONS_UI_ENABLED, false)
	_create_toggle_option(_dev_menu_aggregator, "Stage Grid", SETTING_STAGE_VISUALS_ENABLED, false)
	_create_toggle_option(_dev_menu_aggregator, "Shortcuts", SETTING_DEV_SHORTCUTS_ENABLED, false)
	_create_toggle_option(_dev_menu_aggregator, "Log Save", SETTING_LOG_SAVE, false)
	_create_toggle_option(_dev_menu_aggregator, "Show Hand", SETTING_HAS_HAND, false)
	_create_toggle_option(_dev_menu_aggregator, "Show FPS", SETTING_SHOW_FPS, true)

	var b = UIFactory.get_button()
	b.text = "Clear Saved Settings"
	b.pressed.connect(clear_settings)
	_dev_menu_aggregator.add_element(b)

	b = UIFactory.get_button()
	b.text = "Clear All Upgrades Progress"
	b.pressed.connect(Ma2MetaManager.clear_all_upgrades_progress)
	_dev_menu_aggregator.add_element(b)

	var ag_coins = _dev_menu_aggregator.get_aggregator(["Coins"])
	ag_coins.set_info("Moedas", "", 0, ICON_COIN)
	b = UIFactory.get_button()
	b.text = "Zerar"
	b.pressed.connect(Ma2MetaManager.set_coins_amount.bind(0))
	ag_coins.add_element(b)

	b = UIFactory.get_button()
	b.text = "+5000"
	b.pressed.connect(Ma2MetaManager.gain_coins.bind(5000))
	ag_coins.add_element(b)

	set_enabled(_enable_button.button_pressed)
	_enable_button.toggled.connect(set_enabled)

	# --- Screenshot buttons ---
	var ag_shot = _dev_menu_aggregator.get_aggregator(["Screenshot"])
	ag_shot.set_info("Screenshot", "", 0)

	_btn_select_screenshot_folder = UIFactory.get_button("",select_screenshot_folder)
	_on_screenshot_folder_selected(_save.get_data(SAVE_ID_SCREENSHOT_PATH, ""))

	ag_shot.add_element(_btn_select_screenshot_folder)

	ag_shot.create_prompt_button(
		SCREENSHOT_RESOLUTIONS.keys(),
		"Select Screenshot Resolution",
		"Choose resolution for screenshots",
		"Screenshot Resolution",
		"",
		_save,
		SAVE_ID_SCREENSHOT_OPTION,
		_on_screenshot_resolution_selected,
		null
	)


func _add_credits_menu():
	var cr = Menu.get_aggregator(["Credits"])
	cr.set_info("menu_credits_title", "menu_credits_text", 5, ICON_CREDITS)

	var credits = CREDITS_IN_PAUSE.instantiate()
	cr.add_element(credits, 0)

func _add_info_menu():
	var man = Menu.get_aggregator(["Info"])
	man.set_info("menu_game_manual_title", "menu_game_manual_text", 6, ICON_MANUAL)

	var manual = MANUAL_IN_PAUSE.instantiate()
	man.add_element(manual, 0)

func clear_settings():
	if _save:
		_save.clear_save()

func is_player_imune() -> bool:
	var imune:bool = get_setting(SETTING_PLAYER_IMUNE_ENABLED)

	if !get_setting(SETTING_DEV_SHORTCUTS_ENABLED):
		return imune

	elif Input.is_key_pressed(KEY_I):
		return not imune

	return imune

func set_setting(key:StringName, new_val):
	_settings[key] = new_val

	match key:
		SETTING_DEBUG_UI_ENABLED:
			if new_val:
				show()
				if !_level_selection_menu:
					var LEVEL_SELECTION_MENU:PackedScene = load("res://elements/ui/menus/level_selection_menu/level_selection_menu.tscn")
					_level_selection_menu = LEVEL_SELECTION_MENU.instantiate()
					_level_selection_menu_container.add_child(_level_selection_menu)
			else:
				hide()
				if _level_selection_menu:
					_level_selection_menu.queue_free()

	if _save:
		_save.set_data(key, "TRUE" if new_val else "FALSE")
	settings_changed.emit()

func get_setting(key:StringName, default:bool = false)->Variant:
	if _settings.has(key):
		return _settings[key]
	else:
		if key == SETTING_SHOW_FPS && test_info != null:
			return true
		return default

func set_enabled(enabled:bool):
	_vertical_container.set_process(enabled)
	if enabled:
		_vertical_container.add_child(_debug_callbacks_container)
	else:
		_vertical_container.remove_child(_debug_callbacks_container)

func get_shortcut_just_pressed(shortcut:ShortcutCommand) -> bool:
	if !get_setting(SETTING_DEV_SHORTCUTS_ENABLED):
		return false

	match shortcut:
		ShortcutCommand.FinishLevel:
			return Input.is_action_just_pressed("dev_finish_current_level")
		ShortcutCommand.SkipCutscene:
			return Input.is_action_just_pressed("dev_skip_cutscene")

	return false

func add_debug_callback(callback:Callable, path:String):
	await get_tree().process_frame
	if debug_callbacks.has(path):
		debug_callbacks[path].set_callback(callback)
		return

	var id:String = path
	var parent:String = ""

	if !path.is_empty():
		var spl = path.rsplit("/", false, 1)
		if spl.size() == 2:
			parent = spl[0]
			id = spl[1]

	var box := _debug_callback_box.instantiate() as DebugCallbackBox
	box.set_callback(callback)
	box.set_id(id)
	box.path = path
	debug_callbacks[path] = box

	while true:
		if parent.is_empty():
			_debug_callbacks_container.add_child(box)
			break

		var p_box:DebugCallbackBox = debug_callbacks.get(parent) as DebugCallbackBox
		if p_box:
			p_box.add_sub_box(box)
			break

		path = parent
		var spl = path.rsplit("/", false, 1)
		if spl.size() == 2:
			parent = spl[0]
			id = spl[1]
		else:
			parent = ""
			id = path

		p_box = _debug_callback_box.instantiate() as DebugCallbackBox
		p_box.set_id(id)
		p_box.add_sub_box(box)
		p_box.path = path
		debug_callbacks[path] = p_box

		box = p_box

func remove_debug_callback(path:String):
	if debug_callbacks.has(path):
		var box:DebugCallbackBox = debug_callbacks.get(path)
		debug_callbacks.erase(path)
		if box:
			box.queue_free()
			var parent:DebugCallbackBox = box.parent_box
			while parent:
				if parent.inform_sub_box_deletion(box):
					parent.queue_free()
					debug_callbacks.erase(parent.path)
					box = parent
					parent = box.parent_box
				else:
					break


func _create_toggle_option(ag:MenuAggregator, button_text:String, save_id:StringName, default_val:bool):
	var toggle_button:CheckBox = UIFactory.get_check_box()
	toggle_button.text = button_text
	toggle_button.toggled.connect(
		func(tog_val):
			set_setting(save_id, tog_val)
	)
	var val:bool = _save.get_data(save_id, "TRUE" if default_val else "FALSE") == "TRUE"
	toggle_button.set_pressed_no_signal(val)
	set_setting(save_id, val)
	ag.add_element(toggle_button, 0)
	settings_changed.connect(func on_settings_changed():
		var v:bool = _save.get_data(save_id, "TRUE" if default_val else "FALSE") == "TRUE"
		toggle_button.set_pressed_no_signal(v)
		)

#region StartingPrompts
const SAVE_ID_PROMPTS_SHOWN_DICTIONARY = &"DEV_MANAGER.PROMPTS.SHOWN_DICTIONARY"
const SAVE_ID_PROMPTS_PREVIOUS_VERSION = &"DEV_MANAGER.PROMPTS.PREVIOUS_VERSION"

class ShownPromptData:
	var shown_date:String
	var shown_version:String

	func _init(date:String, version:String):
		shown_date = date
		shown_version = version

	func to_dict() -> Dictionary:
		return {
			"shown_date": shown_date,
			"shown_version": shown_version,
		}

	static func from_dict(data:Dictionary) -> ShownPromptData:
		return ShownPromptData.new(
			data.get("shown_date", ""),   # now can be full timestamp
			data.get("shown_version", "")
		)

var _shown_prompts_data:Dictionary[StringName, ShownPromptData] = {}

var _starting_prompts:Array[PromptInfo] = [
	preload("res://modules/prompt_system/prompt_updated.tres"),
]

func awaitable_show_starting_prompts():
	if !_save:
		push_error("[DEV] SAVE SHOULD BE INITIALIZED BEFORE THIS!")
		return

	var current_version:String = ProjectSettings.get_setting("application/config/version")
	var previous_version:String = ""
	var is_first_play:bool = false
	var version_changed:bool = false

	if _save.has_data(SAVE_ID_PROMPTS_PREVIOUS_VERSION):
		previous_version = _save.get_data(SAVE_ID_PROMPTS_PREVIOUS_VERSION)
		version_changed = previous_version != current_version
	else:
		is_first_play = true
		version_changed = true

	# Load shown prompts dictionary from save
	if _shown_prompts_data.is_empty() && _save.has_data(SAVE_ID_PROMPTS_SHOWN_DICTIONARY):
		var raw_data = _save.get_json_parsed_data(SAVE_ID_PROMPTS_SHOWN_DICTIONARY)
		if typeof(raw_data) == TYPE_DICTIONARY:
			for k in raw_data.keys():
				_shown_prompts_data[k] = ShownPromptData.from_dict(raw_data[k])

	for prompt in _starting_prompts:
		if !prompt.is_good_for_today(): continue
		match prompt.when_to_show:
			PromptInfo.WhenToShow.Always:
				await awaitable_show_prompt_info(prompt)

			PromptInfo.WhenToShow.OnceIfFirstPlay:
				if is_first_play:
					await awaitable_show_prompt_info(prompt)

			PromptInfo.WhenToShow.OnceIfVersionChanged:
				if is_first_play: #If it's the first time, then version didn't actualy change.
					mark_prompt_info_just_shown(prompt)
				elif version_changed and (!_shown_prompts_data.has(prompt.prompt_id) or _shown_prompts_data[prompt.prompt_id].shown_version != current_version):
					await awaitable_show_prompt_info(prompt)

			PromptInfo.WhenToShow.Once:
				if !_shown_prompts_data.has(prompt.prompt_id):
					await awaitable_show_prompt_info(prompt)

			PromptInfo.WhenToShow.Cooldown:
				var should_show := true
				if _shown_prompts_data.has(prompt.prompt_id):
					var last := _shown_prompts_data[prompt.prompt_id]
					var last_time := Time.get_unix_time_from_datetime_string(last.shown_date) # full timestamp stored
					var now_time := Time.get_unix_time_from_system()
					var hours_passed:float = float(now_time - last_time) / 3600.0
					if hours_passed < prompt.cooldown_hours:
						should_show = false
				if should_show:
					await awaitable_show_prompt_info(prompt)

			PromptInfo.WhenToShow.Manually:
				pass

	# Save the current version for next time
	_save.set_data(SAVE_ID_PROMPTS_PREVIOUS_VERSION, current_version)


func awaitable_show_prompt_info(info:PromptInfo):
	var p = PromptWindow.new_prompt(
		info.title,
		info.text,
	)

	while is_instance_valid(p):
		await get_tree().process_frame

	mark_prompt_info_just_shown(info)

func mark_prompt_info_just_shown(info:PromptInfo):
	var current_version:String = ProjectSettings.get_setting("application/config/version")
	var current_timestamp:String = Time.get_datetime_string_from_system(true, true)
	# full ISO-like: "YYYY-MM-DD HH:MM:SS"

	_shown_prompts_data[info.prompt_id] = ShownPromptData.new(current_timestamp, current_version)

	# Serialize to dictionary for saving
	var serializable:Dictionary = {}
	for k in _shown_prompts_data.keys():
		serializable[k] = _shown_prompts_data[k].to_dict()

	_save.set_data(SAVE_ID_PROMPTS_SHOWN_DICTIONARY, JSON.stringify(serializable))

#Screenshot functionality ---------------
func select_screenshot_folder():
	print("[DEV MANAGER] SELECTING FOLDER ")
	var dialog := FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dialog.title = "Select Screenshot Folder"

	# Ensure it's in the visible UI tree
	if !_vertical_container.is_inside_tree():
		add_child(dialog)  # fallback, just in case
	else:
		_vertical_container.add_child(dialog)

	# Connect signal
	dialog.dir_selected.connect(_on_screenshot_folder_selected)

	# Show the dialog
	dialog.popup_centered()

func _on_screenshot_folder_selected(path:String):
	print("[DEV MANAGER] SELECTED FOLDER: " + path)
	_screenshot_path = path
	if _save:
		_save.set_data(SAVE_ID_SCREENSHOT_PATH, path)

	_btn_select_screenshot_folder.text = "Select Screenshot Folder
	(%s)" % path

func _on_screenshot_resolution_selected(option:int):
	print("[DEV MANAGER] Resolution changed: " + str(option))
	if option < 0: return
	_screenshot_resolution_option = option

func _set_screen_resolution(res:Vector2 = Vector2.ZERO, safe_area_top_margin:int = -1):
	# If not Original, temporarily set window size
	if res != Vector2.ZERO:
		if _original_window_size == Vector2.ZERO:
			_original_window_size = DisplayServer.window_get_size()
		print("[DEV MANAGER] WILL SET WINDOW SIZE: " + str(res))
	else:
		# Restore original size
		if _original_window_size != Vector2.ZERO:
			res = _original_window_size
			print("[DEV MANAGER] WILL RESET window size: " + str(_original_window_size))

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	DisplayServer.window_set_size(res)
	get_viewport().get_window().size = res
	SafeAreaMarginContainer.set_top_margin_override(safe_area_top_margin)
	print("[DEV MANAGER] JUST SET window size: " + str(res) + " and margin: " + str(safe_area_top_margin))

func _take_screenshot(option:int):
	if _screenshot_path == "":
		push_warning("Screenshot folder not selected")
		return

	var _screenshot_resolution_title = SCREENSHOT_RESOLUTIONS.keys()[option]
	if _screenshot_resolution_title == "All":
		for i in range(SCREENSHOT_RESOLUTIONS.size()):
			if i != option:
				_take_screenshot(i)
				await get_tree().process_frame
		return

	var screenshot_resolution = SCREENSHOT_RESOLUTIONS[_screenshot_resolution_title]
	_set_screen_resolution(Vector2(screenshot_resolution.x, screenshot_resolution.y), screenshot_resolution.z)

	var now = Time.get_datetime_dict_from_system(false) # false = local time, true = UTC
	var datetime_str = "%04d-%02d-%02d_%02d-%02d-%02d" % [
		now.year, now.month, now.day, now.hour, now.minute, now.second
	]
	var filename = "MA2_%s_%s_%dx%d_%s.png" % [TextManager.get_current_locale(), _screenshot_resolution_title, int(get_viewport().size.x), int(get_viewport().size.y), datetime_str]

	# build folder for this resolution option
	var folder = _screenshot_path + "/" + _screenshot_resolution_title
	DirAccess.make_dir_recursive_absolute(folder)

	var path = folder + "/" + filename
	print("[DEV] Will take Screenshot to: ", path)

	await RenderingServer.frame_post_draw
	var img:Image = get_viewport().get_texture().get_image()

	img.save_png(path)
	print("[DEV] Screenshot saved to: ", path)

	_set_screen_resolution()

func take_screenshot_shortcut_pressed():
	if Input.is_key_pressed(KEY_P):
		_take_screenshot(_screenshot_resolution_option)

func _process(delta):
	if get_setting(SETTING_DEV_SHORTCUTS_ENABLED):
		take_screenshot_shortcut_pressed()
