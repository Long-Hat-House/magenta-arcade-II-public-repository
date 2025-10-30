class_name UpdateProgressDisplay extends Control

const ICON_STAR = preload("res://elements/icons/icon_star.png")
const ICON_STAR_EMPTY = preload("res://elements/icons/icon_star_empty.png")

@export var _label_progress_text:Label
@export var _container_stars:Control

var _stars:Array[TextureRect]

#progress to display should be 1 or higher
func set_progress(upgrade_info:UpgradeInfo, progress_to_display:int):
	if progress_to_display < 0:
		hide()
		return
	else:
		show()

	if _label_progress_text:
		_label_progress_text.text = upgrade_info.get_progress_text(progress_to_display+1)

	var current_progress:int = upgrade_info.get_progress()
	if _container_stars:
		if _stars.is_empty():
			for child in _container_stars.get_children():
				if child is TextureRect:
					_stars.append(child)

		var required_stars = upgrade_info.get_required_stars(progress_to_display)
		while _stars.size() < required_stars:
			var new_star = _stars[0].duplicate()
			_stars.append(new_star)
			_container_stars.add_child(new_star)

		var i:int = 0
		for star in _stars:
			if i < required_stars:
				star.show()
				star.texture = ICON_STAR if progress_to_display < current_progress else ICON_STAR_EMPTY
			else:
				star.hide()
			i += 1

		var transparent_color = Color(1,1,1,.5)
		if progress_to_display < current_progress:
			modulate = Color.WHITE
			self_modulate = Color.WHITE if progress_to_display == current_progress -1 else transparent_color
		else:
			modulate = transparent_color
			self_modulate = Color.WHITE
