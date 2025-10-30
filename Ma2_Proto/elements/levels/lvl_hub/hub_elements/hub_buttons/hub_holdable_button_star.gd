extends Holdable

@export var _hub_cable: Path3D

@export var _material_to_set_color:StandardMaterial3D

@export var _vfx_on_complete:PackedScene

@export_category("Audio")
@export var _sfx_upgrade_complete:WwiseEvent

func _ready() -> void:
	super._ready()

	HUBLevel.instance.upgrade_set_selected.connect(_on_hub_upgrade_set_selected)
	HUBLevel.instance.upgrade_index_selected.connect(_on_hub_upgrade_index_selected)
	Ma2MetaManager.meta_updated.connect(_on_meta_updated)
	button_hold_finished.connect(_on_hold_finished)
	released.connect(_on_released)
	pressed.connect(_on_pressed)

	_disable_button()

func _on_pressed():
	if animation_loops > 0:
		HUBLevel.instance.set_upgrading_stats(0, animation_loops-1, 0)

func _on_released():
	HUBLevel.instance.set_upgrading_stats(-1, -1, 0)

func _on_meta_updated():
	_update_state()

func _on_hub_upgrade_set_selected(upgrade_set:UpgradeSet):
	_update_state()

func _on_hub_upgrade_index_selected(index:int):
	_update_state()

func _update_state():
	var info = HUBLevel.instance.get_selected_upgrade_info()
	if info:
		var available_stars:int = Ma2MetaManager.get_unused_stars_count()
		var required_stars:int = info.get_required_stars()

		if required_stars < 10:
			_enable_button(required_stars)
		else:
			_disable_button()
	else:
		_disable_button()

func _enable_button(n_stars:int):
	var upset = HUBLevel.instance.get_selected_upgrade_set()
	animation_loops = n_stars+1
	button_graphic.set_colors(upset.color, upset.color_highlight)
	if _material_to_set_color:
		_material_to_set_color.emission = upset.color_highlight
		_material_to_set_color.emission_energy_multiplier = 2
	_hub_cable.set_on()

func _disable_button():
	animation_loops = -1
	button_graphic.set_colors(MA2Colors.GREY_DARK, MA2Colors.GREY)
	if _material_to_set_color:
		_material_to_set_color.emission_energy_multiplier = 0
	_hub_cable.set_off()
	button_pressed_feedback.set_pressed(false);

func _on_hold_finished():
	var info = HUBLevel.instance.get_selected_upgrade_info()
	if info:
		if info.set_progress_upgrade():
			_sfx_upgrade_complete.post(self)
			InstantiateUtils.InstantiateTransform3D(_vfx_on_complete, transform)
	HUBLevel.instance.set_upgrading_stats(-1, -1, 0)

func _start_pressing(p:Player.TouchData):
	super._start_pressing(p)
	var info := HUBLevel.instance.get_selected_upgrade_info()

	var available_stars:int = Ma2MetaManager.get_unused_stars_count()
	if available_stars <= 0 or info.get_progress() >= info.get_max_progress():
		button_pressed_feedback.set_pressed(false);
		button_pressed_feedback.finish_playing();

func on_animation_looped():
	var available_stars:int = Ma2MetaManager.get_unused_stars_count()
	super.on_animation_looped()
	if available_stars < loops:
		button_pressed_feedback.set_pressed(false);
		return
	if !waiting_next_press:
		HUBLevel.instance.set_upgrading_stats(0, animation_loops-1, loops)
	#button_pressed_feedback.set_neutral_speed_scale();
