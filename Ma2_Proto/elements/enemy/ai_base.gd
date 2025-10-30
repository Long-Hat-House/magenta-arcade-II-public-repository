class_name AI_Base extends GameElement

var parent:Node3D;

var ai_started_yet:bool;
signal ai_started;

func _ready():
	parent = self.get_parent() as Node3D;
	ai_ready();
	pass

func ai_ready():
	pass;

func ai_start():
	ai_started.emit();
	pass;


func _physics_process(delta:float):
	if not ai_started_yet:
		ai_started_yet = true;
		ai_start();
	ai_physics_process(delta);
	pass;


func ai_physics_process(delta:float):
	pass

### Useful functions ###
