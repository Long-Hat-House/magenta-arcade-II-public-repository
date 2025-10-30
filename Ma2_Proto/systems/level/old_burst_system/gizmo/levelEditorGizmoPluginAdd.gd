# levelEditorGizmoPlugin.gd
@tool
extends EditorPlugin

const LevelEditorGizmoPlugin = preload("res://elements/levels/gizmo/level_editor_gizmo_plugin.gd")

#var gizmo_plugin = LevelEditorGizmoPlugin.new()

func _enter_tree():
	add_node_3d_gizmo_plugin(gizmo_plugin)

func _exit_tree():
	remove_node_3d_gizmo_plugin(gizmo_plugin)
