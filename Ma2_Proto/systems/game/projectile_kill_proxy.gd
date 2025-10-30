class_name ProjectileKillProxy extends Node

signal killed_projectile

func projectile_kill():
	killed_projectile.emit();
