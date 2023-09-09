@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_autoload_singleton("PlayerPrefs", "res://addons/PlayerPrefs/PlayerPrefs.tscn")
