class_name Graphic_Boss_Pirulito_Screen extends Node3D

var anim_id:int = 0;
func _up_id()->int:
	anim_id += 1;
	return anim_id;

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var tumbler: Node3D = $Tumbler
@onready var tumble_corner: Node3D = $Tumbler/Pivot/Box/TumbleCorner
@onready var screen: MeshInstance3D = $Tumbler/Pivot/Box/Screen
@onready var anim_screen:AnimatedSprite3D = $Tumbler/Pivot/Box/AnimatedSprite3D

var tumble_value:float;
var tumble_value_vel:float;

var exploded:bool;

func nando_damage(velocity:float)->void:
	if exploded:
		return;
	var id:int = _up_id();
	anim_screen.play(&"panel_nando_hurt", velocity);
	await anim_screen.animation_looped;
	if id != anim_id: return;
	_check_queue();

func explode_tv():
	add_queue(&"panel_static");
	exploded = true;

func _process(delta: float) -> void:
	var basis = screen.global_basis;
	TransformUtils.tumble_rect(tumbler, -self.global_basis.z * 2 * tumble_value, tumble_corner.position, basis.y )

	tumble_value_vel -= tumble_value * 40 * delta;
	tumble_value_vel -= tumble_value_vel * 4 * delta;
	tumble_value += tumble_value_vel * delta;
	#tumble_value -= tumble_value * delta * 0.5;


func set_show(on:bool):
	animation_tree.set("parameters/conditions/show", on);
	if on:
		await animation_tree.animation_finished;
		add_queue(&"panel_nando_show");

func _on_health_hit(damage:Health.DamageData, health: Health) -> void:
	tumble_value_vel += 1 * damage.amount;
	if not exploded:
		_do_no_signal(6.0, 8.0);

var queue:Array[StringName] = [];

func add_queue(anim:StringName):
	queue.push_back(anim);
	_check_queue();

func erase_queue(anim:StringName):
	queue.erase(anim);
	_check_queue();

func _check_queue():
	if queue.size() > 0:
		anim_screen.play(queue.back());



func _do_no_signal(static_velocity:float = 2.0, no_signal_velocity:float = 1.0)->void:
	var id:int = _up_id();
	anim_screen.play(&"panel_static", static_velocity);
	await anim_screen.animation_looped;
	if id != anim_id: return;
	anim_screen.play(&"panel_no_signal", no_signal_velocity);
	await anim_screen.animation_looped;
	if id != anim_id: return;
	anim_screen.play(&"panel_static", static_velocity);
	await anim_screen.animation_looped;
	if id != anim_id: return;
	_check_queue();


func _on_pressable_pressed_process(touch:Player.TouchData, delta: float) -> void:
	var target_value:float = touch.instance.global_position.y * 1.25;
	tumble_value = target_value;
	tumble_value_vel = 0;
