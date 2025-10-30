class_name ProjectileProxy extends Node

signal call_destroy;

func destroy():
	call_destroy.emit();
