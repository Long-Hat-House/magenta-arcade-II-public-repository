class_name HUBWelcome extends Node3D

@export var letter:HUBLetter
@export var npcs:Array[NPC]
var _destroying:bool



func set_npc_max_count(count:int):
	var n_to_remove = npcs.size() - count

	if n_to_remove <= 0:
		return

	if randf() < 0.5:
		n_to_remove += 1

	npcs.shuffle()
	while n_to_remove > 0 && npcs.size() > 0:
		n_to_remove -= 1
		var npc:NPC = npcs.pop_back()
		npc.queue_free()

func set_to_destroy() -> void:
	if _destroying: return
	_destroying = true
	await get_tree().create_timer(3).timeout
	if _destroying:
		queue_free()

func cancel_destroy() -> void:
	_destroying = false
