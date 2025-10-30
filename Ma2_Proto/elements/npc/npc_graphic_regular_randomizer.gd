class_name GraphicNPC_RegularRandomizer extends Node

enum Type
{
	None,
	Believer,
	Magenta,
	BelieverFanatic
}
@onready var graphic: Graphic_NPC = $".."

@export var believers_sprite_frames:Array[SpriteFrames]
@export var followers_sprite_frames:Array[SpriteFrames]
@export var fanatic_sprite_frames:Array[SpriteFrames]

@export var type_on_ready:Type = Type.None;
var _type:Type;

var made:bool = false;

func _ready():
	make_type(type_on_ready);

func make_type(type:Type):
	_type = type
	if made:
		return;
	match type:
		Type.None:
			pass;
		Type.Believer:
			make_believer();
			made = true;
		Type.Magenta:
			make_follower();
			made = true;
		Type.BelieverFanatic:
			make_fanatic();
			made = true;

func make_custom(type:Type, spriteframes:SpriteFrames):
	_type = type
	graphic.sprite_frames = spriteframes

func make_believer():
	_type = Type.Believer
	graphic.sprite_frames = believers_sprite_frames.pick_random()

func make_follower():
	_type = Type.Magenta
	graphic.sprite_frames = followers_sprite_frames.pick_random()

func make_fanatic():
	_type = Type.BelieverFanatic
	graphic.sprite_frames = fanatic_sprite_frames.pick_random()

func get_type() -> Type:
	return _type
