class_name EnemyPosition extends Resource

@export var grid_position:Vector2 = Vector2.ZERO;
@export var forward:Vector3 = Vector3.BACK;

func setup(enemy:Node3D):
	enemy.position = LevelStageController.instance.get_grid(grid_position.x, grid_position.y);
	var y:Vector3 = Vector3.UP;
	var z:Vector3 = forward.normalized();
	var x:Vector3 = z.cross(y);
	enemy.basis = Basis(x, y, z);
