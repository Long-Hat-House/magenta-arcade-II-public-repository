class_name Graphic_Boss_Cachorro extends LHH3D

@export var emission_material:Material;
@export var shot:Node3D;
var shot_position:Vector3;

@onready var nose: MeshInstance3D = $head/nose
var nose_pos:Vector3;

@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var dialogue_idle: QuickDialogue = $"head/Boss_Cachorro_Turing_Sidekick/Dialogue Position/Idle"
@onready var dialogue_hurt: QuickDialogue = $"head/Boss_Cachorro_Turing_Sidekick/Dialogue Position/Hurt"
@onready var dialogue_end: QuickDialogue =  $"head/Boss_Cachorro_Turing_Sidekick/Dialogue Position/End"
@onready var sidekick: Boss_Cachorro_Turing_Sidekick = $head/Boss_Cachorro_Turing_Sidekick
@onready var dialogues:Array[QuickDialogue] = [
	dialogue_idle,
	dialogue_hurt,
	dialogue_end,
]

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree

@onready var vfx_wind_common: GPUParticles3D = $"VFX Wind Common"
@onready var vfx_wind_intense: GPUParticles3D = $"VFX Wind Intense"

signal shot_there;

func _ready() -> void:
	shot_position = shot.position;
	shot.visible = false;
	nose_pos = nose.position;

	animation_player.animation_finished.connect(_on_animation_changed);

	set_wind_intensity(false);

func _on_animation_changed(anim:String):
	print("CACHORRO current animation changed %s" % [anim]);
	set_wind_intensity(anim == "sugar");

func set_wind_intensity(intense:bool):
	pass;
	#vfx_wind_common.emitting = not intense;
	#vfx_wind_intense.emitting = intense;

func _process(delta: float) -> void:
	if (Engine.get_process_frames() % 3) == 0:
		nose.position = nose_pos + VectorUtils.rand_vector3_range(-0.01, 0.01);

func set_emission(val01:float):
	emission_material.set("emission_energy_multiplier", val01 * 9);

func set_attack_anim(val:bool):
	animation_tree.attack = val;

func set_suck_anim(val:bool):
	animation_tree.suck = val;

func set_dead_anim(val:bool):
	animation_tree.dead = val;

func set_really_dead_anim(val:bool):
	animation_tree.really_dead = val;

func set_eat_anim(val:bool):
	animation_tree.eat = val;

func back_to_idle():
	animation_tree.attack = false;
	animation_tree.suck = false;
	animation_tree.eat = false;


func shoot_ball_to_player(camera_node:Node3D):
	shot.visible = true;
	var t:= create_tween();
	t.tween_property(shot, "global_position", camera_node.global_position - camera_node.global_basis.z * 1, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE);
	await t.finished;

	shot_there.emit();
	shot.visible = false;
	shot.position = shot_position;

## use variables from this class for this
func start_dialogue(to_play:QuickDialogue):
	if !sidekick.visible:
		return;

	print("CACHORRO trying to talk '%s' [%s]" % [
		"<<nothing>>" if to_play==null else to_play.dialogue_id,
		Engine.get_physics_frames()
	]);
	for dialogue in dialogues:
		if to_play != dialogue:
			dialogue.stop_dialogue();
	if to_play != null:
		if !to_play.is_talking():
			to_play.start_dialogue();
