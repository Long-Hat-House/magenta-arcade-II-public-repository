class_name PlayerWeaponLevel extends Node3D

@export var holdInterval:float = 0.25;

func shoot(from:Player.TouchData, advanced_time:float):
	_shoot(from, advanced_time);

func _shoot(from:Player.TouchData, advanced_time:float)->void:
	pass;
