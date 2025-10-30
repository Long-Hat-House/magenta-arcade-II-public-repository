extends Area3D

@export var velocity:float = 0.0;
@export var time_outside_screen:float = 2;
@export var vfx:PackedScene;

var mark_outside:int;

func _enter_tree() -> void:
	mark_outside = 0;

func _physics_process(delta: float) -> void:
	global_basis = global_basis.orthonormalized();
	position += position.normalized() * velocity * delta;
	pass

func _process(delta: float) -> void:
	global_basis = global_basis.orthonormalized();
	if mark_outside != 0:
		if (Time.get_ticks_msec() - mark_outside) > (1000 * time_outside_screen):
			#print("[COSTELLATION] Vanish by timeout!");
			vanish();


func _on_visible_notifier_screen_exited() -> void:
	mark_outside = Time.get_ticks_msec();


func _on_area_entered(area: Area3D) -> void:
	pass # Replace with function body.


func _on_body_entered(body: Node3D) -> void:
	pass # Replace with function body.


func _on_damage_node_on_damaged() -> void:
	#print("[COSTELLATION] Vanish by damage!");
	explode();
	vanish();
	
func explode():
	if vfx:
		InstantiateUtils.InstantiateInSamePlace3D(vfx, self);
		
func vanish():
	ObjectPool.repool(self);
	
