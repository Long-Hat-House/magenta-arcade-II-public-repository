class_name Graphic_Settings_Enabler_Control extends Control



@export var in_conditions:Array[GraphicSettingsManager.Quality]
@export var negation:bool = true;
@export var special_condition:GraphicSettingsManager.SpecialQualityCondition;

func _ready() -> void:
	GraphicSettingsManager.instance.any_settings_changed.connect(check_enabled)
	check_enabled();

func check_enabled():
	_set_enabled(GraphicSettingsManager.should_be_enabled(in_conditions, negation, special_condition));
	
func _set_enabled(is_enabled:bool)->void:
	self.visible = is_enabled;
	self.process_mode = Node.PROCESS_MODE_INHERIT if is_enabled else Node.PROCESS_MODE_DISABLED;
	

	
