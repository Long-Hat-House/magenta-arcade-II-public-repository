extends VisibleOnScreenNotifier3D
const VFX_SIDE_WARNING = preload("res://elements/attack_previews/vfx_side_warning.tscn")

@export_category("Design")
@export var time_to_appear:float = 0.05;
@export var margin_x:float = 20;
@export var margin_y:float = 50;

@export_category("Can Appear")
@export var appear_left:bool = true;
@export var appear_right:bool = true;
@export var appear_up:bool = false;
@export var appear_down:bool = true;

var already_on_screen:bool;
var count:float;
var vfx:Node3D;

func _ready() -> void:
	self.screen_entered.connect(enter_screen);

func enter_screen():
	visible = true;
	already_on_screen = true;

func _process(delta: float) -> void:
	if vfx and is_instance_valid(vfx):
		vfx.global_position = get_vfx_position();
		if is_on_screen():
			disappear_vfx();
	elif not self.is_on_screen() and not already_on_screen:
		count += delta;
		if count > time_to_appear:
			appear_vfx();

func appear_vfx():
	vfx = VFX_SIDE_WARNING.instantiate();
	add_child(vfx);
	#print("[OUT OF SCREEN] %s from %s appearing out of screen VFX!" % [name, owner.name]);

func disappear_vfx():
	vfx.reparent(InstantiateUtils.get_topmost_instantiate_node());
	vfx = null;
	#print("[OUT OF SCREEN] %s from %s disappearing out of screen VFX!" % [name, owner.name]);

func get_vfx_position()->Vector3:
	var my_pos:Vector3 = self.global_position;
	var cam:Camera3D = LevelCameraController.main_camera;
	var rect:Rect2 = get_viewport().get_visible_rect();
	var screen_my_pos:Vector2 = cam.unproject_position(my_pos);
	var screen_new_pos:Vector2 = screen_my_pos;
	if screen_new_pos.x < rect.position.x + margin_x:
		visible = visible and appear_left;
		screen_new_pos.x = rect.position.x + margin_x;
	elif screen_new_pos.x > rect.end.x - margin_x:
		visible = visible and appear_right;
		screen_new_pos.x = rect.end.x - margin_x;
	if screen_new_pos.y < rect.position.y + margin_y:
		visible = visible and appear_up;
		screen_new_pos.y = rect.position.y + margin_y;
	elif screen_new_pos.y > rect.end.y - margin_y:
		visible = visible and appear_down;
		screen_new_pos.y = rect.end.y - margin_y;
	#print("Out of screen of %s of %s is %s -> %s! (%s)" % [name, owner.name, screen_new_pos, get_position_from(screen_new_pos, my_pos, cam), visible]);
	return get_position_from(screen_new_pos, my_pos, cam);

func get_position_from(screen_pos:Vector2, my_pos:Vector3, cam:Camera3D):
	return cam.project_position(screen_pos, (my_pos - cam.global_position).length());
