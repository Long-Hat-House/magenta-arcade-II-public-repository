class_name TextFlowZap extends BoxContainer

const ZAP_IMAGES_INFO = preload("uid://cerui0p25xe7x")

enum AnimationStyle{
	None,
	Basic
}

signal portrait_clicked(speaker:TextFlowZapSpeaker)

@export var _chars_large:int = 35

@export var _text_prefix:String
@export var _line_text_label:RichTextLabel
@export var _speaker_name_label:Label
@export var _image_rect:TextureRect
@export var _speaker_icon_texture_rect:TextureRect
@export var _animation_player:AnimationPlayer
@export var _hide_with_speaker_info:Control
@export var _bg_no_speaker_texture:Texture
@export var _text_bg_panel:PanelContainer

var _speaker:TextFlowZapSpeaker

func click_speaker():
	portrait_clicked.emit(_speaker)

func set_speaker(speaker:TextFlowZapSpeaker):
	if !speaker:
		_speaker_name_label.visible = false
		_speaker_icon_texture_rect.visible = false
		_hide_with_speaker_info.queue_free()
		(_text_bg_panel.get_theme_stylebox("panel") as StyleBoxTexture).texture = _bg_no_speaker_texture
	else:
		_speaker_name_label.text = speaker.name
		_speaker_name_label.self_modulate = speaker.color
		_speaker_icon_texture_rect.texture = speaker.icon_1
		_speaker = speaker

func set_speaker_name(speaker_name:String):
	set_speaker(null)
	if _speaker_name_label:
		_speaker_name_label.visible = true
		_speaker_name_label.text = speaker_name

func set_line(text:String):
	var use_image:bool = false
	if _image_rect:
		var sub_finish:int = text.find("|")
		if sub_finish > 0:
			var sub:String = text.substr(0, sub_finish)
			sub = sub.strip_edges()
			text = text.substr(sub_finish+1)
			text = text.strip_edges()
			var path = ZAP_IMAGES_INFO.get_img_path(sub)
			if !path.is_empty():
				set_image(path)
				use_image = true
			else:
				printerr("[TEXT FLOW ZAP] Not sure what to do with this ID: " + sub)
		if !use_image:
			_image_rect.queue_free()

	var default_font_size:int = _line_text_label.get_theme_font_size("normal_font_size")
	text = Accessibility.parse_bbcode(text, default_font_size)

	_line_text_label.text = _text_prefix+text

	var parsed_text = _line_text_label.get_parsed_text()
	var size_ratio:float = inverse_lerp(0, _chars_large, parsed_text.length())
	if size_ratio >= 1:
		_line_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		self.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		print_debug("Here: " + parsed_text)
	else:
		_line_text_label.custom_minimum_size.x = clamp(550 * size_ratio, 220, 550)

func set_image(path:String):
	ResourceLoader.load_threaded_request(path, str(Texture2D))
	while ResourceLoader.load_threaded_get_status(path) < 1:
		await get_tree().process_frame
		if !is_instance_valid(self) || is_queued_for_deletion():
			return
	var img:Texture2D = ResourceLoader.load_threaded_get(path)
	_image_rect.texture = img

func animate(animation_style:AnimationStyle = AnimationStyle.None):
	if _animation_player:
		match animation_style:
			AnimationStyle.Basic:
				_animation_player.play("basic")
