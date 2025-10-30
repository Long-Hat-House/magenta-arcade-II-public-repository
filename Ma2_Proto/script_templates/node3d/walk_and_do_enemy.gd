# meta-name: Enemy that walks then stop
# meta-description: Pre-made enemy so you don't have to research very time
# meta-default: true

extends AI_WalkAndDo

@export var vfx_die:PackedScene;

func ai_before_walk():
	pass;

func ai_after_walk():
	pass;
	
func get_body()->CharacterBody3D:
	## TODO solve this
	return null;
	
func ai_physics_process(delta:float):
	## find the character body here
	ai_physics_walk_and_do(get_body(), delta);	

func vanish():
	queue_free();
	
func destroy():
	if vfx_die:
		InstantiateUtils.InstantiateInTree(vfx_die, get_body());
