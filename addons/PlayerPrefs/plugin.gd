@tool
extends EditorPlugin


func _enter_tree() -> void:
	if not ProjectSettings.has_setting("autoload/PlayerPrefs"):
		add_autoload_singleton("PlayerPrefs", "res://addons/PlayerPrefs/PlayerPrefs.tscn")

	var playerpref_popup := PopupMenu.new()

	playerpref_popup.add_item("Log All Prefs", 0)
	playerpref_popup.connect("id_pressed", _on_playerpref_popup_id_pressed)

	add_tool_submenu_item("PlayerPref", playerpref_popup)


func _on_show_all_prefs() -> void:
	var playerprefs := get_node_or_null("/root/PlayerPrefs")
	if playerprefs:
		print(playerprefs.get_base())
		return

	var save_path := "user://prefs.save"
	if not FileAccess.file_exists(save_path):
		push_warning("PlayerPrefs: no saved prefs found at %s" % save_path)
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("PlayerPrefs: could not open %s for reading" % save_path)
		return
	print(file.get_var())
	file.close()


func _on_playerpref_popup_id_pressed(id: int) -> void:
	if id == 0:
		_on_show_all_prefs()


func _exit_tree() -> void:
	remove_tool_menu_item("PlayerPref")
	remove_autoload_singleton("PlayerPrefs")
