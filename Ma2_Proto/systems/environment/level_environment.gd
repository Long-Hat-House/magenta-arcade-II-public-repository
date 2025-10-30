class_name LevelEnvironment extends Node

static func set_tree_parameter(parameter:StringName, value):
	if is_instance_valid(main_environment):
		if main_environment._tree:
			main_environment._tree.set(parameter, value);

static func set_state(state:StringName):
	if is_instance_valid(main_environment):
		if main_environment.set_state_as_tree_boolean and main_environment._tree:
			set_tree_parameter(state, true);
		elif main_environment._animation:
			main_environment._animation.play(state)

static func set_animation_speed_scale(speed_scale:float):
	if is_instance_valid(main_environment):
		if main_environment._animation:
			main_environment._animation.speed_scale = speed_scale


static var main_environment:LevelEnvironment

@export var _animation:AnimationPlayer
@export var _tree:AnimationTree;
@export var set_state_as_tree_boolean:bool;

@export var _light:DirectionalLight3D
@export var _environment:WorldEnvironment

var _original_glow_enabled:bool
var _original_fog_enabled:bool
var _original_adjustments_enabled:bool
var _original_tonemap_mode:Environment.ToneMapper
var _original_environment:Environment


func _ready() -> void:
	if is_instance_valid(main_environment):
		main_environment.queue_free()
	main_environment = self
	await get_tree().process_frame
	reparent(get_tree().root)

	if _environment && _environment.environment:
		_original_glow_enabled = _environment.environment.glow_enabled
		_original_fog_enabled = _environment.environment.fog_enabled
		_original_adjustments_enabled = _environment.environment.adjustment_enabled
		_original_tonemap_mode = _environment.environment.tonemap_mode

	GraphicSettingsManager.instance.any_settings_changed.connect(graphic_settings_updated)
	graphic_settings_updated()

func graphic_settings_updated():
	var disable_environment:bool = false

	if _light:
		if GraphicSettingsManager.instance.get_shadows_quality() == GraphicSettingsManager.Quality.Low:
			_light.shadow_enabled = false
		else:
			_light.shadow_enabled = true

		if GraphicSettingsManager.instance.get_light_quality() == GraphicSettingsManager.Quality.Low:
			_light.visible = false
			disable_environment = true
		else:
			_light.visible = true
			disable_environment = false

	var post_process_enabled = GraphicSettingsManager.instance.get_post_process_enabled()
	if _environment:
		if disable_environment && _environment.environment != null && _original_environment == null:
			_original_environment = _environment.environment
			_environment.environment = Environment.new()
			_environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			_environment.environment.ambient_light_color = Color("d2eaff")
			_environment.environment.ambient_light_energy = 3
		elif !disable_environment && _original_environment != null:
			_environment.environment = _original_environment
			_original_environment = null

		if _environment.environment:
			_environment.environment.glow_enabled = _original_glow_enabled if post_process_enabled else false
			_environment.environment.fog_enabled = _original_fog_enabled if post_process_enabled else false
			_environment.environment.adjustment_enabled = _original_adjustments_enabled if post_process_enabled else false
			_environment.environment.tonemap_mode = _original_tonemap_mode if post_process_enabled else Environment.ToneMapper.TONE_MAPPER_LINEAR
