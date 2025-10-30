@tool
extends Node3D

@export_range(0, 1) var screen_brightness:float:
	get:
		if screen_material:
			return screen_material.emission_energy_multiplier / brightness_multiplier
		return screen_brightness
	set(val):
		if screen_material:
			screen_brightness = val
			screen_material.emission_energy_multiplier = val * brightness_multiplier

@export var brightness_multiplier:float = 8

@export var screen_material:StandardMaterial3D
