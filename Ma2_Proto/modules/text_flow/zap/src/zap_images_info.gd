class_name ZapImagesInfo extends Resource
@export var img_paths:Dictionary[StringName, String]

func get_img_path(key:StringName) -> String:
	if img_paths.has(key):
		return img_paths[key]
	return ""
