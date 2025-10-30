extends Holdable

@export var _hub_cable: Path3D

@export var _vfx_upgrade_removed:PackedScene
@export var cost_required_per_star:int = 100;

@export_category("Audio")
@export var _sfx_upgrade_removed:WwiseEvent


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
		HUBLevel.instance.set_upgrading_stats(animation_loops-1, 0, animation_loops-1)

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
	if info && info.get_progress() > 0:
			_enable_button(info)
	else:
		_disable_button()

func _enable_button(info:UpgradeInfo):
	var required = info.get_required_stars(info.get_progress()-1)
	animation_loops = required + 1
	set_cost(required * cost_required_per_star)
	button_graphic.set_colors(MA2Colors.RED, MA2Colors.RED_LIGHT)
	_hub_cable.set_on()

func _disable_button():
	animation_loops = -1
	button_graphic.set_colors(MA2Colors.GREY_DARK, MA2Colors.GREY)
	set_cost(0)
	_hub_cable.set_off()

func _on_hold_finished():
	var info = HUBLevel.instance.get_selected_upgrade_info()
	if info:
		if info.set_progress_downgrade():
			_sfx_upgrade_removed.post(self)
			InstantiateUtils.InstantiateTransform3D(_vfx_upgrade_removed, transform)
		else:
			button_pressed_feedback.set_pressed(false);
			button_pressed_feedback.finish_playing();
	HUBLevel.instance.set_upgrading_stats(-1, -1, 0)

func on_animation_looped():
	super.on_animation_looped()
	if !waiting_next_press:
		HUBLevel.instance.set_upgrading_stats(animation_loops-1, 0, animation_loops-1-loops)
	#button_pressed_feedback.set_neutral_speed_scale();
