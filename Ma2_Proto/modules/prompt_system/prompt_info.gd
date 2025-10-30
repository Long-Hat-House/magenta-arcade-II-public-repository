@tool
class_name PromptInfo extends Resource

enum WhenToShow {
	Manually,
	Always,
	OnceIfFirstPlay,
	OnceIfVersionChanged,
	Once,
	Cooldown, # replaces "Daily"
}

## The ID that will be used for saving and checking when to show
@export var prompt_id:StringName
@export var title:String = "Prompt Title"
@export_multiline var text:String = "Prompt Text"
@export var when_to_show:WhenToShow = WhenToShow.Manually:
	set(val):
		when_to_show = val
		notify_property_list_changed()
## For WhenToShow.Cooldown: time in hours before showing again (default: 24h)
@export var cooldown_hours:float = 24.0
@export var icon:Texture2D

# Use Strings in the inspector for easy input.
# Accepts "DD/MM/YYYY", "DD/MM/YY", "YYYY-MM-DD", or "YYYYMMDD".
# Blank = ignored.
@export var good_since:String = "":
	set(val):
		good_since = val
		_update_error_text()
@export var good_until:String = "":
	set(val):
		good_until = val
		_update_error_text()
@export_multiline var validate:String = ""

func _update_error_text():
	validate = (
		"GoodSince: " + str(_parse_date_to_unix(good_since, false)) +
		"\nGoodUntil: " + str(_parse_date_to_unix(good_until, true)) +
		"\nGoodToday: " + str(is_good_for_today())
		)

func _validate_property(property):
	if property.name == "cooldown_hours" and when_to_show != WhenToShow.Cooldown:
		property.usage &= ~PROPERTY_USAGE_EDITOR

	if property.name == "validate":
		property.usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY

# Parse some common human-friendly date strings into a unix timestamp.
# - Accepts "DD/MM/YYYY", "DD/MM/YY", "YYYY-MM-DD", "YYYYMMDD".
# - If end_of_day == true it returns the timestamp for 23:59:59 of that date (inclusive).
# - Returns -1 on empty/invalid input (meaning "no bound").
func _parse_date_to_unix(date_str:String, end_of_day:bool=false) -> int:
	var s := date_str.strip_edges()
	if s == "":
		return -1

	var day:int
	var month:int
	var year:int

	# slash format: dd/mm/yyyy or dd/mm/yy
	if s.find("/") != -1:
		var parts := s.split("/", false)
		if parts.size() < 3:
			return -1
		day = int(parts[0])
		month = int(parts[1])
		year = int(parts[2])
		if year < 100:
			year += 2000  # interpret 2-digit years as 2000+

	# iso-like: yyyy-mm-dd
	elif s.find("-") != -1:
		var parts := s.split("-", false)
		if parts.size() < 3:
			return -1
		year = int(parts[0])
		month = int(parts[1])
		day = int(parts[2])

	# compact: YYYYMMDD
	elif s.length() == 8 and s.is_valid_int():
		year = int(s.substr(0, 4))
		month = int(s.substr(4, 2))
		day = int(s.substr(6, 2))

	else:
		return -1  # unknown format

	if month < 1 or month > 12 or day < 1 or day > 31:
		return -1

	var hour := 0
	var minute := 0
	var second := 0
	if end_of_day:
		hour = 23
		minute = 59
		second = 59

	var dt_str := "%04d-%02d-%02d %02d:%02d:%02d" % [year, month, day, hour, minute, second]
	var unix := Time.get_unix_time_from_datetime_string(dt_str)
	if typeof(unix) != TYPE_INT:
		return -1
	return unix


# Returns true if the prompt is allowed to show for the *current system date/time*.
# Uses the user's system time so comparisons respect the user's local clock.
# Both bounds are inclusive. Blank bounds are ignored.
func is_good_for_today() -> bool:
	var now_unix := Time.get_unix_time_from_system()

	var start_unix := _parse_date_to_unix(good_since, false)   # midnight start
	var end_unix := _parse_date_to_unix(good_until, true)     # end of day

	if start_unix == -1 and end_unix == -1:
		return true
	if start_unix != -1 and now_unix < start_unix:
		return false
	if end_unix != -1 and now_unix > end_unix:
		return false
	return true
