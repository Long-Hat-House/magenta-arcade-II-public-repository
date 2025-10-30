class_name UpgradeInfoDisplay extends Control

@export var _label_title:Label
@export var _label_description:Label
@export var _label_current_progress:Label
@export var _texrect_icon:TextureRect
@export var _container_progress_displays:Control

var _progress_displays:Array[UpdateProgressDisplay]

var _current_info:UpgradeInfo

func _ready() -> void:
	Ma2MetaManager.meta_updated.connect(_on_meta_updated)

func _on_meta_updated():
	set_info(_current_info)

func set_info(info:UpgradeInfo):
	_current_info = info

	if !info:
		return

	if _label_title: _label_title.text = info.upgrade_id
	if _label_description: _label_description.text = info.upgrade_description
	if _label_current_progress: _label_current_progress.text = info.get_progress_text()
	if _texrect_icon: _texrect_icon.texture = info.upgrade_icon

	if _container_progress_displays:
		if _progress_displays.is_empty():
			for child in _container_progress_displays.get_children():
				if child is UpdateProgressDisplay:
					_progress_displays.append(child)

		var progresses_count = info.stars_per_progress.size()
		while _progress_displays.size() < progresses_count:
			var new_prog = _progress_displays[0].duplicate()
			_progress_displays.append(new_prog)
			_container_progress_displays.add_child(new_prog)

		var i:int = 0
		for prog in _progress_displays:
			if i < progresses_count:
				prog.show()
				prog.set_progress(info, i)
			else:
				prog.hide()
			i += 1
