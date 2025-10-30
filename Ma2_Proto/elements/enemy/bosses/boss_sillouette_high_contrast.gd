extends AccessibilityHighContrastSignal

@export var sprite:SpriteBase3D;
@export var render_priority:int = 5;

var _old_no_depth_test:bool;
var _old_rend_priority:int;


func _enter_tree() -> void:
	self.any_high_contrast_change.connect(_change);
	_old_no_depth_test = sprite.no_depth_test;
	_old_rend_priority = sprite.render_priority;
	super._enter_tree();
	
func _exit_tree() -> void:
	self.any_high_contrast_change.disconnect(_change);
	super._exit_tree();
	
func _change():
	var enabled:bool = Accessibility.high_contrast_controller.get_enabled();
	if enabled:
		sprite.no_depth_test = true;
		sprite.render_priority = max(render_priority, _old_rend_priority);
	else:
		sprite.no_depth_test = _old_no_depth_test;
		sprite.render_priority = _old_rend_priority;
	
