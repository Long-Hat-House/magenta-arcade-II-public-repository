@tool
class_name UpgradeInfo extends Resource

const TEXT_LEVEL_COMPLETE:String = "Encontre e derrote {char_name}"
const TEXT_THE_BOSS:String = "O Chefe"
const TEXT_TARGET_TIME:String = "Termine antes de {target_time}"
const TEXT_DESTROY_ALL:String = "Destrua todos os robotos brilhantes!"

@export var upgrade_id:StringName:
	set(val):
		if val.is_empty():
			val = resource_path.get_file().get_basename()
		upgrade_id = val
	get:
		if upgrade_id.is_empty():
			return resource_path.get_file().get_basename()
		return upgrade_id

@export var upgrade_description:StringName:
	set(val):
		if val.is_empty():
			val = upgrade_id+"_description"
		upgrade_description = val
	get:
		if upgrade_description.is_empty():
			return upgrade_id+"_description"
		return upgrade_description

@export var upgrade_icon:Texture2D

@export_category("Upgrade Design")
@export var stars_per_progress:Array[int] = [3]
@export_multiline var upgrade_developer_instruction:String = "
	Describe in inspector which vals are used and for what!
	Example1: In every hold projectile [damage = proj_damage + float_val * progress]
	Example2: In every hold projectile [damage = proj_damage + float_val_array[progress]]
	"
@export var float_val:float
@export var float_val_array:Array[float]

## Should only be called when Meta is loaded
func get_progress() -> int:
	return Ma2MetaManager.get_upgrade_progress(upgrade_id)

func get_max_progress() -> int:
	return stars_per_progress.size()

func get_required_stars(progress:int = -1) -> int:
	if progress < 0:
		progress = get_progress()

	var max = get_max_progress()

	if progress < max:
		return stars_per_progress[progress]
	else:
		return 0

func get_allocated_stars() -> int:
	var progress = get_progress()
	var max = get_max_progress()
	if progress > max:
		set_progress(max)
		progress = max
	var stars = 0
	while progress > 0:
		stars += get_required_stars(progress-1)
		progress -= 1
	return stars

func get_progress_text(progress:int = -1) -> String:
	if progress < 0:
		progress = get_progress()
	match progress:
		1: return "I"
		2: return "II"
		3: return "III"
		4: return "IV"
		5: return "V"
		6: return "VI"
		7: return "VII"
		8: return "VIII"
		9: return "IX"
		10: return "X"
	return "-"

## Should only be called when Meta is loaded
func set_progress(progress:int):
	if progress < 0:
		progress = 0
	if progress > stars_per_progress.size():
		progress = stars_per_progress.size()
	Ma2MetaManager.set_upgrade_progress(upgrade_id, progress)

func set_progress_upgrade(ignore_stars:bool = false) -> bool:
	var required_stars = get_required_stars()
	if ignore_stars || Ma2MetaManager.get_unused_stars_count() >= required_stars:
		set_progress(get_progress()+1)
		SocialPlatformManager.unlock_achievement(SocialPlatformManager.Achievement.ACH_USE_STAR_1)
		return true
	return false

func set_progress_downgrade() -> bool:
	var prog = get_progress()
	if prog > 0:
		set_progress(get_progress()-1)
		return true
	return false
