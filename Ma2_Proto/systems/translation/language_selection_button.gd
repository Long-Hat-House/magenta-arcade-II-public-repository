extends OptionButton

static var language_chosen:bool = false

func _ready() -> void:
	if !language_chosen:
		language_chosen = true
		TranslationServer.set_locale("pt_BR")

	get_popup().get_viewport().transparent_bg = true
	clear()
	var current:String = TranslationServer.get_locale()
	var id:int = 0
	var current_index:int = 0
	for locale in TranslationServer.get_loaded_locales():
		if locale not in ["pre", "pos", "tags"]:
			get_popup().add_radio_check_item(TranslationServer.get_locale_name(locale), id)
			var item_index = get_item_index(id)
			set_item_metadata(item_index, locale)
			if locale == current:
				current_index = item_index
			id += 1

	item_selected.connect(_on_item_selected)
	selected = current_index
	update_minimum_size()

func _on_item_selected(index:int):
	var item_text:String = get_item_metadata(index)
	TranslationServer.set_locale(item_text)
