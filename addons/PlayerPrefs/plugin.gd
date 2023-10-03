@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_autoload_singleton("PlayerPrefs", "res://addons/PlayerPrefs/PlayerPrefs.tscn")

	var playerpref_popup := PopupMenu.new()

	playerpref_popup.add_item("Show All Prefs", 0)
	playerpref_popup.connect("id_pressed", _on_playerpref_popup_id_pressed)

	add_tool_submenu_item("PlayerPref", playerpref_popup)


func _on_show_all_prefs() -> void:
	var prefs = PlayerPref.new()
	prefs = prefs.get_base()
	print(prefs)


func _on_playerpref_popup_id_pressed(id: int) -> void:
	if id == 0:
		_on_show_all_prefs()


func _exit_tree() -> void:
	remove_tool_menu_item("PlayerPref")
