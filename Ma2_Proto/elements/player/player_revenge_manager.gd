extends Node

@onready var player: Player = $".."

@export var revenge_scene:PackedScene;
@export var time_between_revenges:float = 0.4;

func _ready() -> void:
	print("Adding revenge to finger!!");
	player.finger_took_damage.connect(_on_player_took_damage);
	print("Added revenge to finger!!");
	
func _on_player_took_damage(token:PlayerToken):
	var i:int = 0;
	print("INSIDE FINGER TOOK DAMAGE %s %s" % [i, player.currentState.revenge_level]);
	var where:Vector3 = token.global_position;
	while i < player.currentState.revenge_level:
		shoot(where);
		i += 1;
		await get_tree().create_timer(time_between_revenges).timeout;
	
func shoot(where:Vector3):
	var rev:Node3D = revenge_scene.instantiate();
	where.y = 0;
	rev.position = where;
	InstantiateUtils.get_topmost_instantiate_node().add_child(rev);
