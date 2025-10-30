class_name FakeCursorManager extends Control

var mouse_position:Vector2;
@export var cursor:PlayerFakeFinger;

var ground_plane:Plane = Plane(Vector3.UP, Vector3.ZERO);
var last_button_pressed:bool;
var enabled_pressed:bool;

func _ready():
	DevManager.settings_changed.connect(_on_settings_changed);
	_on_settings_changed();
	
func _on_settings_changed():
	cursor.visible = DevManager.get_setting(DevManager.SETTING_HAS_HAND, false)

func _process(delta: float) -> void:
	if cursor:
		mouse_position = get_global_mouse_position();
		cursor.global_position = get_ground_plane_position(mouse_position);
		var press:bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT);
		if press != last_button_pressed:
			cursor.set_pressed(press);
			last_button_pressed = press;
			
	var enable_press:bool = Input.is_key_pressed(KEY_H);
	if enabled_pressed != enable_press:
		if enable_press:
			visible = !visible;
		enabled_pressed = enable_press;

func _unhandled_input(event: InputEvent) -> void:
	## Simulate Mouse 
	if cursor.visible and event is InputEventMouse:
		print("hi mouse %s (%s) [%s]" % [event.position, event.global_position, Engine.get_physics_frames()]);
		mouse_position = event.global_position;
		if cursor:
			cursor.global_position = get_ground_plane_position(mouse_position);
			
		if event is InputEventMouseButton:
			if cursor:
				var buttonEvent := event as InputEventMouseButton;
				cursor.set_pressed(buttonEvent.is_pressed())



func get_ground_plane_position(touchPosition:Vector2) -> Vector2:
	return touchPosition;
	
	#var ray_length:float = 100.0;
	#var cam = LevelCameraController.main_camera
	#if cam != null:
		#var from:Vector3 = cam.project_ray_origin(touchPosition);
		#var toRelative:Vector3 = cam.project_ray_normal(touchPosition) * ray_length;
		#return ground_plane.intersects_ray(from, toRelative);
