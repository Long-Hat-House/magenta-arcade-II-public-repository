extends Node

const ICON_LANGUAGE = preload("res://elements/icons/icon_language.png")
const SAVE_LANGUAGE:StringName = &"TEXT_MANAGER.LANGUAGE"

const TRANSLATION_POS = preload("res://translations/translation.pos.translation")
const TRANSLATION_PRE = preload("res://translations/translation.pre.translation")
const TRANSLATION_TAGS = preload("res://translations/translation.tags.translation")

signal locale_changed(new_locale:String)

var _language_chosen:bool = false

var _save:GameSave
var _button_pair:ButtonLabelPair

var _options:Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TranslationServer.add_translation(TRANSLATION_POS)
	TranslationServer.add_translation(TRANSLATION_PRE)
	TranslationServer.add_translation(TRANSLATION_TAGS)

	print("[TEXT MANAGER] Readying")
	SaveManager.use_settings(_save_settings_ready)

	#var t:Theme = MENU_THEME
	#t.default_font_size = t.default_font_size * 2
	#for theme_type in t.get_font_size_type_list():
		#for font_size in t.get_font_size_list(theme_type):
			#var size:int = t.get_font_size(font_size, theme_type)
			#t.set_font_size(font_size, theme_type, size*2)

func _process(delta: float) -> void:
	if _save && !is_instance_valid(_button_pair):
		print("[TEXT MANAGER] WILL RE-INIT")
		_save_settings_ready(_save)

func _save_settings_ready(save:GameSave):
	print("[TEXT MANAGER] Loading settings")

	_save = save

	_set_locale(_save.get_data(SAVE_LANGUAGE, OS.get_locale()))

	_button_pair = UIFactory.get_button_label_pair(
		"menu_choice_language",
		get_locale_name(TranslationServer.get_locale()),
		show_languages_prompt)
	_button_pair.icon = ICON_LANGUAGE

	var ag = Menu.get_aggregator(["General", "Language"])
	ag.set_info("","")
	ag.add_element(_button_pair)

var _is_showing_languages_prompt:bool = false
func show_languages_prompt_await():
	show_languages_prompt()

	while _is_showing_languages_prompt:
		await get_tree().process_frame

func show_languages_prompt():
	if _is_showing_languages_prompt:
		return

	_is_showing_languages_prompt = true

	var current:String = TranslationServer.get_locale()
	var id:int = 0
	var current_index:int = 0
	_options.clear()

	var prompt_entries:Array[PromptWindow.PromptEntry] = []
	for locale in TranslationServer.get_loaded_locales():
		if locale not in ["pre", "pos", "tags"]:
			_options[id] = locale
			var name = get_locale_name(locale)
			prompt_entries.append(PromptWindow.PromptEntry.CreateButton(name, id, false, true, locale == current))
			id += 1
	prompt_entries.append(PromptWindow.PromptEntry.new(PromptWindow.PromptEntry.EntryStyle.Separator))
	prompt_entries.append(PromptWindow.PromptEntry.CreateButton("menu_confirm", -1, true))
	PromptWindow.new_prompt_advanced("menu_choice_language", "", _on_item_selected, prompt_entries, false, _on_item_updated)

func get_locale_name(locale_id:StringName) -> String:
	var obj = TranslationServer.get_translation_object(locale_id)
	if obj:
		return obj.get_message(&"lang_name")
	else:
		return locale_id

func get_current_locale() -> String:
	return TranslationServer.get_locale()

func _on_item_updated(index:int):
	if index >= _options.size() || index < 0:
		return
	_set_locale(_options[index])
	_save.set_data(SAVE_LANGUAGE, _options[index])
	_button_pair.label_text = get_locale_name(TranslationServer.get_locale())

func _on_item_selected(index:int):
	_is_showing_languages_prompt = false
	_on_item_updated(index)

func _set_locale(locale:String):
	TranslationServer.set_locale(locale)
	locale_changed.emit(locale)
