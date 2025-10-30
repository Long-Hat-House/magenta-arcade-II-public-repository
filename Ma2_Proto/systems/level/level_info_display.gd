class_name LevelInfoDisplay extends Control

@export var _to_set_level_color:Array[Control]
@export var _to_set_level_highlight_color:Array[Control]

@export var _label_level_name:Label
@export var _level_goal_text:Label
@export var _level_highscore_text:Label
@export var _trect_level_icons:Array[TextureRect]
@export var _boss_display_duplicate:TextFlowZapSpeakerInfoDisplay
@export var _max_bosses_display:int = 100

var _bosses_displays:Array[TextFlowZapSpeakerInfoDisplay]

func set_level(lvl:LevelInfo):
	for to_set in _to_set_level_color:
		to_set.modulate = lvl.lvl_color

	for to_set in _to_set_level_highlight_color:
		to_set.modulate = lvl.lvl_color_highlight

	if _label_level_name:
		_label_level_name.text = lvl.lvl_id

	if _level_goal_text:
		_level_goal_text.text = lvl.level_goal_text

	if _level_highscore_text:
		_level_highscore_text.text = str(lvl.get_highscore())

	for icon in _trect_level_icons:
		icon.texture = lvl.lvl_icon

	if _boss_display_duplicate:
		if _bosses_displays.size() <= 0:
			_bosses_displays.append(_boss_display_duplicate)

		if lvl.zap_speaker_bosses.size() > _max_bosses_display:
			for display in _bosses_displays:
				display.visible = false
		else:
			while _bosses_displays.size() < lvl.zap_speaker_bosses.size():
				var new_icon = _bosses_displays[0].duplicate()
				_bosses_displays.append(new_icon)
				_bosses_displays[0].add_sibling(new_icon)

			var i:int = 0
			for _boss_display in _bosses_displays:
				if i >= lvl.zap_speaker_bosses.size():
					_boss_display.set_speaker(null)
				else:
					_boss_display.set_speaker(lvl.zap_speaker_bosses[i])
				i += 1
