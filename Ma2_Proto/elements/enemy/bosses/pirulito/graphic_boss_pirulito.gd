class_name Graphic_Boss_Pirulito extends LHH3D

@onready var shaker: Node3D = $SHAKER
@onready var tumbler: Node3D = $SHAKER/TUMBLER
@onready var shot_origin: Node3D = %"shot origin"
@onready var ornament: Graphic_Boss_Pirulito_Ornament = $SHAKER/base/boss_pirulito_ornament_graphic
@onready var cap_base_2: Node3D = $SHAKER/TUMBLER/cap_base2
@onready var base: Node3D = $SHAKER/base;
@onready var lamp_left:Boss_Pirulito_Lamp = $SHAKER/base/column/Lamp_Left;
@onready var lamp_right:Boss_Pirulito_Lamp = $SHAKER/base/column2/Lamp_Right;
@onready var lamp_back_left: Node3D = $SHAKER/base/column3/lamp3
@onready var lamp_back_right: Node3D = $SHAKER/base/column4/lamp4
@onready var lamps:Array[Node3D] = [lamp_left.graphic, lamp_right.graphic, lamp_back_left, lamp_back_right];
@onready var lamp_target_left: Node3D = $"SHAKER/base/column/Lamp Target Left"
@onready var lamp_target_right: Node3D = $"SHAKER/base/column2/Lamp Target Right"
@onready var column_sound_left: Node3D = $"SHAKER/base/column/column sound left"
@onready var column_sound_right: Node3D = $"SHAKER/base/column2/column sound right"
@onready var screen_left: Graphic_Boss_Pirulito_Screen = $enemy_boss_pirulito_screen_graphic
@onready var screen_right: Graphic_Boss_Pirulito_Screen = $enemy_boss_pirulito_screen_graphic2

@onready var sfx_shot_left: AkEvent3D = $"SHAKER/base/column/Lamp Target Left/SFX_ShotLeft"
@onready var sfx_shot_right: AkEvent3D = $"SHAKER/base/column2/Lamp Target Right/SFX_ShotRight"
@onready var sfx_shot_middle: AkEvent3D = $"SHAKER/base/boss_pirulito_ornament_graphic/shot origin/SFX_ShotMiddle"

@onready var high_contrast_base: AccessibilityHighContrastObject = $SHAKER/base/HighContrastBase


@onready var to_hide:Array[Node3D] = [tumbler, base]

@onready var enemy_boss_nando_and_nene:Graphic_Boss_Pirulito_NandoENene = %Enemy_Boss_Nando_And_Nene



var shot_right_origin:Node3D:
	get:
		return column_sound_right.get_aim_position();

var shot_left_origin:Node3D:
	get:
		return column_sound_left.get_aim_position();

@onready var animation: AnimationPlayer = $AnimationPlayer


var sprite_animation:AnimatedSprite3D:
	get:
		return enemy_boss_nando_and_nene.animation;

var nando_e_nene:Graphic_Boss_Pirulito_NandoENene:
	get:
		return enemy_boss_nando_and_nene;

var tumble_value:float;
var tumble_direction:Vector3;
var tumble_vel:float;
var shake_force:float;
var constant_shake_force:float;

var _rot_tween:Tween;
var _y_tween:Tween;

func _ready():
	lamp_left.set_thunder_target(lamp_target_left);
	lamp_right.set_thunder_target(lamp_target_right);


func _process(delta: float) -> void:
	if tumbler:
		tumble_vel = -tumble_value * 500 * delta;
		tumble_value += tumble_vel * delta;
		tumble_vel -= tumble_vel * 0.5 * delta;

		TransformUtils.tumble_rect(tumbler, tumble_direction * tumble_value * 0.5, Vector3(5,0,5), Vector3.UP);

	if shaker:
		shake_force -= delta * 16;
		shake_force = maxf(shake_force, 0);

		TransformUtils.tremble(shaker, Vector3(1,0,1) * (shake_force + constant_shake_force) * 0.06)

func hide_main_graphic():
	for hider in to_hide:
		hider.hide();

func explode_tvs():
	screen_left.explode_tv();
	screen_right.explode_tv();


func set_vulnerable(vulnerable:bool):
	if vulnerable:
		if high_contrast_base:
			high_contrast_base.change_group(&"neutral");
		#animation.play("shield_offing");
		#await animation.animation_finished;
		#animation.play("shield_off");
	else:
		high_contrast_base.change_group(&"danger");
		#animation.play("shield_on");

func set_lights(on:bool)->void:
	var now_lights:Array[Node3D] = Array(lamps);
	while now_lights.size() > 0:
		var light:Node3D = now_lights.pick_random();
		now_lights.erase(light);
		light.set_on(on);
		await get_tree().create_timer(0.1 + randf() * 0.15).timeout;
	set_lights_detail(true);

func set_lights_detail(on:bool)->void:
	for lamp in lamps:
		lamp.set_detail(on);

func set_open(open:bool)->void:
	if _rot_tween and _rot_tween.is_running():
		_rot_tween.kill();
	if _y_tween and _y_tween.is_running():
		_y_tween.kill();
	_rot_tween = create_tween();
	_y_tween = create_tween();
	if open:
		_rot_tween.tween_property(cap_base_2, "rotation", Vector3.LEFT * PI * 0.40, 1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE);
		_y_tween.tween_property(cap_base_2, "position:y", 1.75, 1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE);

		await get_tree().create_timer(1 + randf()).timeout
		screen_left.set_show(true);
		await get_tree().create_timer(randf()).timeout
		screen_right.set_show(true);
	else:
		if cap_base_2.rotation != Vector3.ZERO:
			_rot_tween.tween_property(cap_base_2, "rotation", Vector3.RIGHT * PI * 0.025, 0.55).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC);
			_rot_tween.tween_property(cap_base_2, "rotation", Vector3.ZERO, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE);
			_y_tween.tween_property(cap_base_2, "position:y", 0, 0.80).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE);



func set_open_sound(open:bool)->void:
	column_sound_right.set_open(open);
	column_sound_left.set_open(open);

func set_open_sound_central(open:bool)->void:
	if open:
		ornament.set_open();

func feedback_get_shot(origin:Node3D):
	tumble_direction = self.global_position - origin.global_position;
	tumble_direction.x *= 30;
	tumble_direction = tumble_direction.normalized();
	tumble_value = 1;
	tumble_vel = 50;

	shake_force = 3;

	screen_left.nando_damage(1);
	screen_right.nando_damage(1);

func feedback_shake(on:bool):
	constant_shake_force = 3 if on else 0;

func destroy():
	cap_base_2.hide();
	base.hide();
	enemy_boss_nando_and_nene.finish();

func get_middle_shot_origin()->Node3D:
	return shot_origin;
