class_name DamageBody extends PhysicsBody3D

@export var amountDamage:int = 1;
@export var maxCollisions:int = 1;
@export var scores:bool = false;
@export var recover_mana:bool = false;

signal onDamaged;

var col:KinematicCollision3D;

func _ready():
	col = KinematicCollision3D.new();

func _physics_process(delta:float):
	#if self.test_move(transform, -Vector3.UP, col, 0.1, true, maxCollisions):
		#for i:int in range(col.get_collision_count()):
			#var node:Node = col.get_collider(i) as Node;
			#print("[Damage body] %s collided with %s" % [self, node]);
			#if node:
				#Health.Damage(node.get_parent(), Health.DamageData.new(amountDamage, self))
	col = self.move_and_collide(-Vector3.UP, true, 0.1, true, maxCollisions);
	if col:
		for i:int in range(col.get_collision_count()):
			var node:Node = col.get_collider(i) as Node;
			print("[Damage body] %s collided with %s" % [self, node]);
			if node:
				var dd:Health.DamageData = Health.DamageData.new(amountDamage, self, scores, recover_mana);
				if Health.Damage(node.get_parent(), dd):
					onDamaged.emit();
