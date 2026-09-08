extends Node
class_name PlayerPref
## Responsible for saving Player preferences in your game.
##
## This script is the base for the implementation and holds functions responsible for storing and retrieving the data.
##
## Data is written synchronously to [member path] as a header-prefixed Variant stream
## (PPFS magic + format byte + [code]var_to_bytes()[/code] payload).

signal prefs_changed(key: String, value)
## Emitted after a single preference key is deleted.
signal pref_deleted(key: String)
## Emitted after all preferences are cleared.
signal prefs_cleared()
## Emitted when writing to disk fails.
signal save_failed(path: String)
## Emitted after data is successfully loaded from disk.
signal prefs_loaded()
## Emitted after switching to another save slot.
signal slot_changed(slot_name: String)

## Holds player preferences
var prefs: Dictionary = {}
var filename: String = "prefs.save"
var path: String = "user://"
## Base directory for save files. Defaults to "user://". Set it to an absolute
## path to store saves elsewhere (e.g. an editor tool pointing at the game's
## runtime user directory).
var user_dir: String = "user://"
## When true (default), every mutation is written to disk immediately.
## When false, mutations are only marked as pending and written on quit,
## autosave tick or an explicit [method save_data] call.
var save_on_write: bool = true
## Seconds between automatic saves while data is dirty. 0.0 disables autosave.
var autosave_interval: float = 0.0
## When true, pending changes are written when the app is closed or paused.
var autosave_on_quit: bool = true
## Version of the save data. Bump this when the meaning of stored keys changes,
## and set [member migration_callback] to update older saves after loading.
var save_version: int = 1
## Called as [code]callback(prefs: Dictionary, from_version: int)[/code] after loading
## a save older than [member save_version]. Should return the migrated prefs dictionary.
var migration_callback: Callable = Callable()
## Version of the save file that was last loaded (1 for legacy files).
var last_loaded_version: int = 1
## When true, a .bak copy of the previous save is kept and used as a load fallback.
var create_backup: bool = true
var _dirty: bool = false
var _slot: String = ""

const MAGIC := "PPFS"
const FORMAT_PLAIN := 0


func _init() -> void:
	path = _build_path(_slot)


func _ready() -> void:
	if autosave_interval > 0.0:
		var timer := Timer.new()
		timer.wait_time = autosave_interval
		timer.autostart = true
		timer.timeout.connect(_on_autosave_timeout)
		add_child(timer)
	if FileAccess.file_exists(path):
		load_data()
	else:
		save_data()


func _notification(what: int) -> void:
	if not autosave_on_quit:
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if _dirty:
			save_data()


func _on_autosave_timeout() -> void:
	if _dirty:
		save_data()


func _mark_dirty() -> void:
	_dirty = true
	if save_on_write:
		save_data()


## For setting base values for player prefs
## Usage:
## [codeblock]
## PlayerPrefs.set_base({"health": 100, "score": 0})
## [/codeblock]
func set_base(value: Dictionary) -> void:
	prefs = value
	prefs_changed.emit("base", value)
	_mark_dirty()


## For getting base values of player prefs
## Usage:
## [codeblock]
## PlayerPrefs.get_base()
## [/codeblock]
func get_base() -> Dictionary:
	return prefs


## To set a preference with "key"
## Usage:
## [codeblock]
## PlayerPrefs.set_pref("health", 0)
## [/codeblock]
func set_pref(key: String, value) -> void:
	prefs[key] = value
	prefs_changed.emit(key, value)
	_mark_dirty()


## To get a preference provided "key"
## Usage:
## [codeblock]
## PlayerPrefs.get_pref("health", 0)
## [/codeblock]
func get_pref(key: String, default_value):
	if prefs.has(key):
		return prefs[key]
	else:
		return default_value


## Returns true if a preference with "key" exists
## Usage:
## [codeblock]
## PlayerPrefs.has_pref("health")
## [/codeblock]
func has_pref(key: String) -> bool:
	return prefs.has(key)


## Returns a list of all preference keys
## Usage:
## [codeblock]
## PlayerPrefs.get_keys()
## [/codeblock]
func get_keys() -> Array:
	return prefs.keys()


## Returns a deep copy of all preferences
## Usage:
## [codeblock]
## PlayerPrefs.get_all()
## [/codeblock]
func get_all() -> Dictionary:
	return prefs.duplicate(true)


## Typed getter for int, returns [param default_value] if missing or not an int
func get_int(key: String, default_value: int = 0) -> int:
	var value = get_pref(key, default_value)
	return value if value is int else default_value


## Typed getter for float, returns [param default_value] if missing or not a float
func get_float(key: String, default_value: float = 0.0) -> float:
	var value = get_pref(key, default_value)
	return value if value is float else default_value


## Typed getter for String, returns [param default_value] if missing or not a String
func get_string(key: String, default_value: String = "") -> String:
	var value = get_pref(key, default_value)
	return value if value is String else default_value


## Typed getter for bool, returns [param default_value] if missing or not a bool
func get_bool(key: String, default_value: bool = false) -> bool:
	var value = get_pref(key, default_value)
	return value if value is bool else default_value


## Typed getter for Vector2, returns [param default_value] if missing or not a Vector2
func get_vec2(key: String, default_value: Vector2 = Vector2.ZERO) -> Vector2:
	var value = get_pref(key, default_value)
	return value if value is Vector2 else default_value


## Typed getter for Vector3, returns [param default_value] if missing or not a Vector3
func get_vec3(key: String, default_value: Vector3 = Vector3.ZERO) -> Vector3:
	var value = get_pref(key, default_value)
	return value if value is Vector3 else default_value


## Typed getter for Vector4, returns [param default_value] if missing or not a Vector4
func get_vec4(key: String, default_value: Vector4 = Vector4.ZERO) -> Vector4:
	var value = get_pref(key, default_value)
	return value if value is Vector4 else default_value


## Typed getter for Color, returns [param default_value] if missing or not a Color
func get_color(key: String, default_value: Color = Color.WHITE) -> Color:
	var value = get_pref(key, default_value)
	return value if value is Color else default_value


## Typed getter for Rect2, returns [param default_value] if missing or not a Rect2
func get_rect2(key: String, default_value: Rect2 = Rect2()) -> Rect2:
	var value = get_pref(key, default_value)
	return value if value is Rect2 else default_value


## Typed getter for Array, returns [param default_value] if missing or not an Array
func get_array(key: String, default_value: Array = []) -> Array:
	var value = get_pref(key, default_value)
	return value if value is Array else default_value


## Typed getter for Dictionary, returns [param default_value] if missing or not a Dictionary
func get_dictionary(key: String, default_value: Dictionary = {}) -> Dictionary:
	var value = get_pref(key, default_value)
	return value if value is Dictionary else default_value


## Deletes a preference provided "key"
func delete_pref(key: String) -> void:
	if prefs.has(key):
		prefs.erase(key)
		pref_deleted.emit(key)
		_mark_dirty()


## Deletes all preferences
func delete_all() -> void:
	prefs.clear()
	prefs_cleared.emit()
	_mark_dirty()


## Switches to another save slot. The default slot "" uses "prefs.save",
## named slots use "prefs_<name>.save". Uncommitted changes are saved first,
## then the slot's data is loaded (empty if the slot has no file yet).
func set_slot(slot_name: String) -> void:
	if slot_name == _slot:
		return
	if _dirty:
		save_data()
	_slot = slot_name
	path = _build_path(_slot)
	prefs.clear()
	slot_changed.emit(_slot)
	if FileAccess.file_exists(path):
		load_data()
	else:
		save_data()


## Returns the name of the currently active slot.
func get_active_slot() -> String:
	return _slot


## Returns all available slot names, including the default slot "".
func list_slots() -> Array:
	var slots: Array = [""]
	var dir := DirAccess.open(user_dir)
	if dir:
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if not dir.current_is_dir() and fname.begins_with(filename.get_basename() + "_") and fname.ends_with("." + filename.get_extension()):
				slots.append(fname.trim_suffix("." + filename.get_extension()).trim_prefix(filename.get_basename() + "_"))
			fname = dir.get_next()
		dir.list_dir_end()
	slots.sort()
	return slots


## Deletes a slot's save files. If it is the active slot, preferences are cleared.
func delete_slot(slot_name: String) -> void:
	var slot_path := _build_path(slot_name)
	if FileAccess.file_exists(slot_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path))
	if FileAccess.file_exists(slot_path + ".bak"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path + ".bak"))
	if slot_name == _slot:
		prefs.clear()
		_dirty = false


func _build_path(slot_name: String) -> String:
	if slot_name == "":
		return user_dir + filename
	return user_dir + filename.get_basename() + "_" + _sanitize_slot(slot_name) + "." + filename.get_extension()


func _sanitize_slot(slot_name: String) -> String:
	var safe := ""
	for i in slot_name.length():
		var c := slot_name[i]
		var alnum := (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9")
		safe += c if alnum else "_"
	return safe


## Exports the current preferences to a human-readable JSON file.
## Godot-only types (Vector2, Color, ...) are stored as string literals
## that [method import_json] can restore. Returns true on success.
func export_json(file_path: String) -> bool:
	var payload := {"version": save_version, "data": _to_json_safe(prefs)}
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("PlayerPrefs: Could not open %s for writing" % file_path)
		return false
	file.store_string(JSON.stringify(payload, "  "))
	file.close()
	return true


## Loads preferences from a JSON file previously created by [method export_json].
## Returns true on success.
func import_json(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		push_error("PlayerPrefs: JSON file not found: %s" % file_path)
		return false
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("PlayerPrefs: Could not open %s for reading" % file_path)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary and parsed.has("data"):
		prefs = _from_json_safe(parsed["data"])
		_mark_dirty()
		return true
	push_error("PlayerPrefs: %s does not contain valid PlayerPrefs JSON" % file_path)
	return false


func _to_json_safe(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			var out := {}
			for key in value:
				out[key] = _to_json_safe(value[key])
			return out
		TYPE_ARRAY:
			var out := []
			for item in value:
				out.append(_to_json_safe(item))
			return out
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return value
		_:
			return var_to_str(value)


func _from_json_safe(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			if value == int(value):
				return int(value)
			return value
		TYPE_DICTIONARY:
			var out := {}
			for key in value:
				out[key] = _from_json_safe(value[key])
			return out
		TYPE_ARRAY:
			var out := []
			for item in value:
				out.append(_from_json_safe(item))
			return out
		TYPE_STRING:
			var literal: Variant = str_to_var(value)
			if literal != null and _is_json_converted_type(literal):
				return literal
			return value
		_:
			return value


func _is_json_converted_type(value: Variant) -> bool:
	match typeof(value):
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4, TYPE_COLOR, TYPE_RECT2, TYPE_PLANE, TYPE_QUATERNION, TYPE_AABB, TYPE_BASIS, TYPE_TRANSFORM2D, TYPE_TRANSFORM3D, TYPE_NODE_PATH:
			return true
	return false


## Saves [member prefs] to [member path] synchronously.
## Writes atomically via a temp file and keeps a .bak backup when [member create_backup] is true.
## Returns true on success.
func save_data() -> bool:
	var tmp_path := path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("PlayerPrefs: Could not open file for writing: %s" % tmp_path)
		save_failed.emit(path)
		return false
	file.store_buffer(MAGIC.to_ascii_buffer())
	file.store_8(FORMAT_PLAIN)
	file.store_var({"version": save_version, "data": prefs})
	file.close()
	if not _replace_file(tmp_path, path):
		save_failed.emit(path)
		return false
	_dirty = false
	return true


## Loads [member prefs] from [member path].
## Falls back to the .bak backup if the main file is missing or corrupt.
## Returns true on success.
func load_data() -> bool:
	if FileAccess.file_exists(path):
		var data := _read_data_from(path)
		if data != null:
			_apply_loaded_data(data)
			prefs_loaded.emit()
			return true
		push_warning("PlayerPrefs: save file corrupt, trying backup: %s" % path)
	if create_backup and FileAccess.file_exists(path + ".bak"):
		var data := _read_data_from(path + ".bak")
		if data != null:
			_apply_loaded_data(data)
			save_data()
			prefs_loaded.emit()
			return true
	push_error("PlayerPrefs: Could not load save data from %s" % path)
	return false


func _replace_file(tmp_path: String, target_path: String) -> bool:
	var bak_path := target_path + ".bak"
	if create_backup:
		if FileAccess.file_exists(bak_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(bak_path))
		if FileAccess.file_exists(target_path):
			if DirAccess.rename_absolute(ProjectSettings.globalize_path(target_path), ProjectSettings.globalize_path(bak_path)) != OK:
				push_error("PlayerPrefs: Could not create backup of %s" % target_path)
				return false
	elif FileAccess.file_exists(target_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(target_path))
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp_path), ProjectSettings.globalize_path(target_path)) != OK:
		push_error("PlayerPrefs: Could not replace file %s" % target_path)
		return false
	return true


func _read_data_from(file_path: String) -> Variant:
	var bytes := FileAccess.get_file_as_bytes(file_path)
	if bytes.size() < 5:
		return null
	if bytes.slice(0, 4).get_string_from_ascii() != MAGIC:
		var legacy: Variant = _parse_variant_stream(bytes)
		if legacy == null:
			push_warning("PlayerPrefs: could not parse %s (not a PlayerPrefs save file?)" % file_path)
			return null
		return {"version": 1, "data": legacy}
	var format := bytes[4]
	if format != FORMAT_PLAIN:
		push_error("PlayerPrefs: unsupported format marker %d in %s" % [format, file_path])
		return null
	var wrapper: Variant = _parse_variant_stream(bytes.slice(5))
	if wrapper == null:
		push_warning("PlayerPrefs: could not parse %s" % file_path)
		return null
	return wrapper


## Decodes a [code]FileAccess.store_var()[/code]-style stream (4-byte length prefix
## followed by the encoded variant) written anywhere inside a file.
func _parse_variant_stream(stream: PackedByteArray) -> Variant:
	if stream.size() < 4:
		return null
	var payload_len := stream.decode_u32(0)
	if payload_len > stream.size() - 4:
		return null
	return bytes_to_var(stream.slice(4, 4 + payload_len))


func _apply_loaded_data(data: Variant) -> void:
	var version := 1
	if data is Dictionary and data.get("data", null) is Dictionary:
		prefs = data["data"]
		version = int(data.get("version", 1))
	else:
		prefs = data
	last_loaded_version = version
	_dirty = false
	if version < save_version and migration_callback.is_valid():
		var migrated: Variant = migration_callback.call(prefs, version)
		if migrated is Dictionary:
			prefs = migrated
			_dirty = true
