class_name Boss_Final_Ivo_Scenery extends LHH3D

@export var anim_before:Array[AnimationPlayer];
@export var animation_before:Array[StringName];

@export var anim_during:Array[AnimationPlayer];
@export var animation_during:Array[StringName];

@export var anim_after:Array[AnimationPlayer];
@export var animation_after:Array[StringName];


var before_animation_speed_scale:float:
	get:
		return anim_before[0].speed_scale;
	set(value):
		for anim in anim_before:
			anim.speed_scale = value;

func _ready() -> void:
	play(anim_during, animation_during);
	do_before();
		
func play(players:Array[AnimationPlayer], anims:Array[StringName]):
	for i:int in range(mini(players.size(), anims.size())):
		players[i].play(anims[i]);
		
func stop(players:Array[AnimationPlayer]):
	for player in players:
		player.play(&"RESET");
		
func do_before():
	play(anim_before, animation_before);
	stop(anim_after);
	
func do_after():
	play(anim_after, animation_after);
	stop(anim_before);
	
	
