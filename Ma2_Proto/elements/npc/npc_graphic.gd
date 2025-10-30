class_name Graphic_NPC extends AnimatedSprite3D

@onready var shadow:MeshInstance3D = $Shadow
@onready var randomize_sprite_frames: GraphicNPC_RegularRandomizer = $RandomizeSpriteFrames
@onready var high_contrast: AccessibilityHighContrastSprite = $NPC_HighContrastSprite/NPC_HighContrastSprite

enum NPCAnimation
{
	Idle,
	Hit,
	Press_Idle,
	Press_Walk,
	Talk,
	Walk
}

@export var anim_idle:StringName = &"idle";
@export var anim_hit:StringName = &"hit";
@export var anim_talk:StringName = &"talk";
@export var anim_walk:StringName = &"walk";
@export var anim_press_idle:StringName = &"press_idle";
@export var anim_press_walk:StringName = &"press_walk";
@export var high_contrast_dead:StringName = &"scenery";

@onready var _hide_shadow_animations:Array[StringName] = [
	anim_press_idle,
	anim_press_walk,
	anim_hit
]

func set_animation_npc(npc_animation:NPCAnimation):
	match(npc_animation):
		NPCAnimation.Idle:
			play_animation(anim_idle);
		NPCAnimation.Hit:
			high_contrast.change_group(high_contrast_dead);
			play_animation(anim_hit);
		NPCAnimation.Talk:
			play_animation(anim_talk);
		NPCAnimation.Walk:
			play_animation(anim_walk);
		NPCAnimation.Press_Idle:
			play_animation(anim_press_idle);
		NPCAnimation.Press_Walk:
			play_animation(anim_press_walk);

func play_animation(npc_animation:StringName):
	play(npc_animation);
	if npc_animation in _hide_shadow_animations:
		shadow.visible = false
	else:
		shadow.visible = true
