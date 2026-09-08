@tool
extends EditorPlugin

const DOCK_SCRIPT := preload("res://addons/PlayerPrefs/editor/playerprefs_dock.gd")

var _dock: Control


func _enter_tree() -> void:
	if not ProjectSettings.has_setting("autoload/PlayerPrefs"):
		add_autoload_singleton("PlayerPrefs", "res://addons/PlayerPrefs/PlayerPrefs.tscn")

	var playerpref_popup := PopupMenu.new()

	playerpref_popup.add_item("Log All Prefs", 0)
	playerpref_popup.connect("id_pressed", _on_playerpref_popup_id_pressed)

	add_tool_submenu_item("PlayerPref", playerpref_popup)

	_dock = DOCK_SCRIPT.new()
	_dock.name = "PlayerPrefs"
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UL, _dock)


func _on_show_all_prefs() -> void:
	var playerprefs := get_node_or_null("/root/PlayerPrefs")
	if playerprefs:
		playerprefs.user_dir = DOCK_SCRIPT.runtime_user_dir()
		playerprefs.path = playerprefs.user_dir + playerprefs.filename
		if FileAccess.file_exists(playerprefs.path):
			playerprefs.load_data()
		else:
			playerprefs.delete_all()
		print(playerprefs.get_base())
		return

	var prefs_node = load("res://addons/PlayerPrefs/PlayerPrefs.gd").new()
	prefs_node.user_dir = DOCK_SCRIPT.runtime_user_dir()
	prefs_node.path = prefs_node.user_dir + prefs_node.filename
	if FileAccess.file_exists(prefs_node.path):
		if prefs_node.load_data():
			print(prefs_node.get_base())
		prefs_node.free()
	else:
		push_warning("PlayerPrefs: no saved prefs found at %s" % prefs_node.path)
		prefs_node.free()


func _on_playerpref_popup_id_pressed(id: int) -> void:
	if id == 0:
		_on_show_all_prefs()


func _exit_tree() -> void:
	remove_tool_menu_item("PlayerPref")
	remove_autoload_singleton("PlayerPrefs")
	if _dock:
		remove_control_from_docks(_dock)
		_dock.free()
