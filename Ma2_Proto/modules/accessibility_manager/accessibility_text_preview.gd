class_name AccessibilityTextPreview extends PanelContainer

@export_multiline var _text:String
@export var _label:RichTextLabel

func re_parse():
	var default_font_size:int = _label.get_theme_font_size("normal_font_size")
	var text = Accessibility.parse_bbcode(tr(_text), default_font_size)

	_label.text = text
