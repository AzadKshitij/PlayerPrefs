@tool
extends VBoxContainer

const DEFAULT_SLOT_TEXT := "(default)"

var _prefs_node: PlayerPref
var _owns_node: bool = false
var _slot_option: OptionButton
var _tree: Tree
var _key_edit: LineEdit
var _value_edit: LineEdit
var _export_dialog: FileDialog
var _import_dialog: FileDialog
var _last_modified: Dictionary = {}


## Returns the absolute directory the running game writes its save files to
## (the runtime [code]user://[/code] directory). In the editor, [code]user://[/code]
## resolves to the editor's own data folder, so the last path component is
## swapped with the project name. At runtime the path is already correct.
static func runtime_user_dir() -> String:
	var project_name := str(ProjectSettings.get_setting("application/config/name", "")).strip_edges()
	var current_dir := ProjectSettings.globalize_path("user://").trim_suffix("/")
	if project_name.is_empty() or current_dir.get_file() == project_name:
		return current_dir + "/"
	return current_dir.get_base_dir().path_join(project_name) + "/"


func _ready() -> void:
	_prefs_node = get_node_or_null("/root/PlayerPrefs")
	_owns_node = _prefs_node == null
	if _owns_node:
		_prefs_node = load("res://addons/PlayerPrefs/PlayerPrefs.gd").new()
		_prefs_node.name = "PlayerPrefsDock"
	_prefs_node.user_dir = runtime_user_dir()
	_prefs_node.path = _prefs_node.user_dir + _prefs_node.filename
	if _owns_node:
		add_child(_prefs_node)
	elif FileAccess.file_exists(_prefs_node.path):
		_prefs_node.load_data()
	else:
		_prefs_node.delete_all()
	_build_ui()
	refresh()
	_setup_autorefresh()


func _setup_autorefresh() -> void:
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_autorefresh_timeout)
	add_child(timer)


func _on_autorefresh_timeout() -> void:
	if not is_visible_in_tree():
		return
	var stamp := FileAccess.get_modified_time(_prefs_node.path)
	if _last_modified.get(_prefs_node.path, -1.0) != stamp:
		_last_modified[_prefs_node.path] = stamp
		refresh()


func _build_ui() -> void:
	var path_label := Label.new()
	path_label.text = _prefs_node.path
	path_label.tooltip_text = "Save file edited by this dock (game runtime user dir)"
	path_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	path_label.add_theme_font_size_override("font_size", 10)
	add_child(path_label)

	var top := HBoxContainer.new()
	top.add_child(Label.new())

	_slot_option = OptionButton.new()
	_slot_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slot_option.item_selected.connect(_on_slot_selected)
	top.add_child(_slot_option)

	var refresh_btn := Button.new()
	refresh_btn.text = "Refresh"
	refresh_btn.pressed.connect(refresh)
	top.add_child(refresh_btn)
	add_child(top)

	_tree = Tree.new()
	_tree.columns = 2
	_tree.set_column_title(0, "Key")
	_tree.set_column_title(1, "Value")
	_tree.set_column_expand(0, false)
	_tree.set_column_custom_minimum_width(0, 160)
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.cell_selected.connect(_on_tree_cell_selected)
	add_child(_tree)

	var edit_row := HBoxContainer.new()
	_key_edit = LineEdit.new()
	_key_edit.placeholder_text = "key"
	_key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit_row.add_child(_key_edit)
	_value_edit = LineEdit.new()
	_value_edit.placeholder_text = "value (Godot literal or text)"
	_value_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit_row.add_child(_value_edit)
	var set_btn := Button.new()
	set_btn.text = "Set"
	set_btn.pressed.connect(_on_set_pressed)
	edit_row.add_child(set_btn)
	add_child(edit_row)

	var action_row := HBoxContainer.new()
	var delete_btn := Button.new()
	delete_btn.text = "Delete Selected"
	delete_btn.pressed.connect(_on_delete_pressed)
	action_row.add_child(delete_btn)
	var clear_btn := Button.new()
	clear_btn.text = "Clear All"
	clear_btn.pressed.connect(_on_clear_pressed)
	action_row.add_child(clear_btn)
	var export_btn := Button.new()
	export_btn.text = "Export JSON"
	export_btn.pressed.connect(_on_export_pressed)
	action_row.add_child(export_btn)
	var import_btn := Button.new()
	import_btn.text = "Import JSON"
	import_btn.pressed.connect(_on_import_pressed)
	action_row.add_child(import_btn)
	add_child(action_row)

	_export_dialog = FileDialog.new()
	_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_export_dialog.current_dir = _prefs_node.user_dir
	_export_dialog.file_selected.connect(_on_export_file_selected)
	add_child(_export_dialog)

	_import_dialog = FileDialog.new()
	_import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_import_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_import_dialog.current_dir = _prefs_node.user_dir
	_import_dialog.file_selected.connect(_on_import_file_selected)
	add_child(_import_dialog)


func refresh() -> void:
	_last_modified[_prefs_node.path] = FileAccess.get_modified_time(_prefs_node.path)

	_slot_option.clear()
	for slot in _prefs_node.list_slots():
		_slot_option.add_item(_slot_text(slot))
	var active := _slot_text(_prefs_node.get_active_slot())
	for i in _slot_option.item_count:
		if _slot_option.get_item_text(i) == active:
			_slot_option.select(i)
			break

	_tree.clear()
	var root := _tree.create_item()
	root.set_text(0, "PlayerPrefs")
	for key in _prefs_node.get_all():
		var item := _tree.create_item(root)
		item.set_text(0, key)
		item.set_text(1, var_to_str(_prefs_node.get_pref(key, null)))


func _slot_text(slot: String) -> String:
	return slot if slot != "" else DEFAULT_SLOT_TEXT


func _on_slot_selected(index: int) -> void:
	var text: String = _slot_option.get_item_text(index)
	var slot := "" if text == DEFAULT_SLOT_TEXT else text
	_prefs_node.set_slot(slot)
	refresh()


func _on_tree_cell_selected() -> void:
	var selected := _tree.get_selected()
	if selected == null or selected.get_parent() == null:
		return
	_key_edit.text = selected.get_text(0)
	_value_edit.text = var_to_str(_prefs_node.get_pref(selected.get_text(0), null))


func _on_set_pressed() -> void:
	var key := _key_edit.text.strip_edges()
	if key == "":
		return
	var value: Variant = str_to_var(_value_edit.text.strip_edges())
	if value == null:
		value = _value_edit.text
	_prefs_node.set_pref(key, value)
	refresh()


func _on_delete_pressed() -> void:
	var key := ""
	var selected := _tree.get_selected()
	if selected and selected.get_parent() != null:
		key = selected.get_text(0)
	if key == "":
		key = _key_edit.text.strip_edges()
	if key != "":
		_prefs_node.delete_pref(key)
		refresh()


func _on_clear_pressed() -> void:
	_prefs_node.delete_all()
	refresh()


func _on_export_pressed() -> void:
	_export_dialog.current_file = "prefs_export.json"
	_export_dialog.popup_centered_ratio(0.4)


func _on_export_file_selected(path: String) -> void:
	_prefs_node.export_json(path)


func _on_import_pressed() -> void:
	_import_dialog.popup_centered_ratio(0.4)


func _on_import_file_selected(path: String) -> void:
	if _prefs_node.import_json(path):
		refresh()
