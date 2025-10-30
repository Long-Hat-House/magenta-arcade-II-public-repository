class_name UpgradeSetDisplay extends Control

@export var _label_title:Label
@export var _label_description:Label
@export var _label_current_allocated_stars:Label
@export var _texrect_icon:TextureRect

func set_upgrade_set(upgrade_set:UpgradeSet):
	if _label_title: _label_title.text = upgrade_set.set_id
	if _label_description: _label_description.text = upgrade_set.set_description
	if _label_current_allocated_stars: _label_current_allocated_stars.text = str(upgrade_set.get_allocated_summed_stars())
	if _texrect_icon: _texrect_icon.texture = upgrade_set.icon
