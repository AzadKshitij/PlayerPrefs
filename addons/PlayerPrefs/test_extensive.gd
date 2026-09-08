extends Node

var _checks: int = 0
var _failures: int = 0
var _signal_log: Array = []


func _ready() -> void:
	print("")
	print("=================== PlayerPrefs extensive tests ===================")
	if not PlayerPrefs:
		push_error("PlayerPrefs autoload is not available; tests cannot run.")
		return
	_run_all_tests()
	PlayerPrefs.delete_all()
	print("")
	if _failures == 0:
		print("RESULT: ALL %d CHECKS PASSED" % _checks)
	else:
		push_error("RESULT: %d/%d CHECKS FAILED" % [_failures, _checks])


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  PASS: ", label)
	else:
		_failures += 1
		push_error("  FAIL: " + label)


func _section(title: String) -> void:
	print("")
	print("## ", title)


func _run_all_tests() -> void:
	PlayerPrefs.delete_all()
	_test_initial_state()
	_test_set_get_scalars()
	_test_get_pref_default()
	_test_set_get_compound_types()
	_test_overwrite_keys()
	_test_set_base()
	_test_delete_pref()
	_test_delete_all()
	_test_prefs_changed_signal()
	_test_typed_getters()
	_test_save_on_write_off()
	_test_json_roundtrip()
	_test_slots()
	_test_version_migration()
	_test_signals()
	_test_persistence_across_instances()
	_test_save_file_on_disk()


func _test_initial_state() -> void:
	_section("Initial state")
	_check(PlayerPrefs.prefs is Dictionary, "prefs is a Dictionary")
	_check(PlayerPrefs.get_base() is Dictionary, "get_base() returns a Dictionary")
	_check(PlayerPrefs.filename == "prefs.save", "default filename is 'prefs.save'")
	_check(PlayerPrefs.path == "user://prefs.save", "default path is 'user://prefs.save'")
	_check(PlayerPrefs.prefs.is_empty(), "prefs are empty after delete_all")


func _test_set_get_scalars() -> void:
	_section("set_pref / get_pref with scalar types")
	PlayerPrefs.set_pref("int_value", 42)
	_check(PlayerPrefs.get_pref("int_value", -1) == 42, "integer roundtrip")

	PlayerPrefs.set_pref("float_value", 3.14)
	_check(absf(PlayerPrefs.get_pref("float_value", -1.0) - 3.14) < 0.00001, "float roundtrip")

	PlayerPrefs.set_pref("string_value", "hello godot")
	_check(PlayerPrefs.get_pref("string_value", "") == "hello godot", "string roundtrip")

	PlayerPrefs.set_pref("bool_value", true)
	_check(PlayerPrefs.get_pref("bool_value", false), "bool roundtrip")

	PlayerPrefs.set_pref("unicode_value", "héllo → 🌟")
	_check(PlayerPrefs.get_pref("unicode_value", "") == "héllo → 🌟", "unicode string roundtrip")


func _test_get_pref_default() -> void:
	_section("get_pref default values")
	_check(PlayerPrefs.get_pref("missing_int", 99) == 99, "missing int key returns default")
	_check(PlayerPrefs.get_pref("missing_string", "fallback") == "fallback", "missing string key returns default")
	_check(PlayerPrefs.get_pref("missing_vec", Vector2.ZERO) == Vector2.ZERO, "missing vector key returns default")
	_check(PlayerPrefs.get_pref("missing", null) == null, "missing key with null default returns null")


func _test_set_get_compound_types() -> void:
	_section("set_pref / get_pref with compound types")
	PlayerPrefs.set_pref("vec2", Vector2(1, 2))
	_check(PlayerPrefs.get_pref("vec2", Vector2.ZERO) == Vector2(1, 2), "Vector2 roundtrip")

	PlayerPrefs.set_pref("vec3", Vector3(1, 2, 3))
	_check(PlayerPrefs.get_pref("vec3", Vector3.ZERO) == Vector3(1, 2, 3), "Vector3 roundtrip")

	PlayerPrefs.set_pref("vec4", Vector4(1, 2, 3, 4))
	_check(PlayerPrefs.get_pref("vec4", Vector4.ZERO) == Vector4(1, 2, 3, 4), "Vector4 roundtrip")

	PlayerPrefs.set_pref("color", Color(1, 2, 3, 4))
	_check(PlayerPrefs.get_pref("color", Color.BLACK) == Color(1, 2, 3, 4), "Color roundtrip")

	PlayerPrefs.set_pref("rect2", Rect2(1, 2, 3, 4))
	_check(PlayerPrefs.get_pref("rect2", Rect2()) == Rect2(1, 2, 3, 4), "Rect2 roundtrip")

	var array_value: Array = [1, "two", 3.0, true, Vector2(1, 2)]
	PlayerPrefs.set_pref("array_value", array_value)
	_check(PlayerPrefs.get_pref("array_value", []) == array_value, "Array roundtrip")

	var dict_value: Dictionary = {"nested": {"deep": 1}, "list": [1, 2], "flag": false}
	PlayerPrefs.set_pref("dict_value", dict_value)
	_check(PlayerPrefs.get_pref("dict_value", {}) == dict_value, "nested Dictionary roundtrip")


func _test_overwrite_keys() -> void:
	_section("Overwriting keys")
	PlayerPrefs.set_pref("overwrite_me", "first")
	PlayerPrefs.set_pref("overwrite_me", "second")
	_check(PlayerPrefs.get_pref("overwrite_me", "") == "second", "overwriting a key updates its value")

	PlayerPrefs.set_pref("type_change", 1)
	PlayerPrefs.set_pref("type_change", "now a string")
	_check(PlayerPrefs.get_pref("type_change", 0) == "now a string", "a key can change type")

	PlayerPrefs.set_pref("", "empty key")
	_check(PlayerPrefs.get_pref("", "missing") == "empty key", "empty string key is stored and retrieved")


func _test_set_base() -> void:
	_section("set_base / get_base")
	var base_value := {
		"health": 100,
		"score": 0,
		"position": Vector3(1, 2, 3),
	}
	PlayerPrefs.set_base(base_value)
	_check(PlayerPrefs.get_base() == base_value, "get_base() returns the base dictionary")
	_check(PlayerPrefs.get_pref("health", -1) == 100, "base int value accessible via get_pref")
	_check(PlayerPrefs.get_pref("position", Vector3.ZERO) == Vector3(1, 2, 3), "base compound value accessible via get_pref")
	_check(PlayerPrefs.get_pref("leftover_from_earlier", "gone") == "gone", "set_base replaces previous keys")


func _test_delete_pref() -> void:
	_section("delete_pref")
	PlayerPrefs.set_pref("keep_me", 7)
	PlayerPrefs.set_pref("delete_me", 123)
	PlayerPrefs.delete_pref("delete_me")
	_check(PlayerPrefs.get_pref("delete_me", -1) == -1, "deleted key returns its default")
	_check(not PlayerPrefs.prefs.has("delete_me"), "deleted key is removed from prefs")
	_check(PlayerPrefs.get_pref("keep_me", -1) == 7, "unrelated keys are preserved")

	var before: Dictionary = PlayerPrefs.get_base()
	PlayerPrefs.delete_pref("never_existed")
	_check(PlayerPrefs.get_base() == before, "deleting a missing key leaves prefs unchanged")


func _test_delete_all() -> void:
	_section("delete_all")
	PlayerPrefs.set_pref("a", 1)
	PlayerPrefs.set_pref("b", 2)
	PlayerPrefs.delete_all()
	_check(PlayerPrefs.get_base().is_empty(), "delete_all clears the prefs dictionary")
	_check(PlayerPrefs.get_pref("a", -1) == -1, "cleared keys return their defaults")


func _test_prefs_changed_signal() -> void:
	_section("prefs_changed signal")
	_signal_log.clear()
	PlayerPrefs.prefs_changed.connect(_on_prefs_changed)

	PlayerPrefs.set_pref("signal_key", 5)
	_check(_signal_log.size() == 1, "set_pref emits the signal once")
	_check(_signal_log.size() >= 1 and _signal_log[0][0] == "signal_key", "signal carries the key")
	_check(_signal_log.size() >= 1 and _signal_log[0][1] == 5, "signal carries the value")

	PlayerPrefs.set_base({"base_key": 1})
	_check(_signal_log.size() == 2, "set_base emits the signal once")
	_check(_signal_log.size() >= 2 and _signal_log[1][0] == "base", "set_base signal key is 'base'")
	_check(_signal_log.size() >= 2 and _signal_log[1][1] == {"base_key": 1}, "set_base signal value is the base dictionary")

	PlayerPrefs.delete_pref("signal_key")
	_check(_signal_log.size() == 2, "delete_pref does not emit the signal")

	PlayerPrefs.delete_all()
	_check(_signal_log.size() == 2, "delete_all does not emit the signal")

	PlayerPrefs.prefs_changed.disconnect(_on_prefs_changed)


func _on_prefs_changed(key: String, value) -> void:
	_signal_log.append([key, value])


func _test_typed_getters() -> void:
	_section("Typed getters")
	PlayerPrefs.set_pref("gi", 42)
	PlayerPrefs.set_pref("gf", 2.5)
	PlayerPrefs.set_pref("gs", "text")
	PlayerPrefs.set_pref("gb", true)
	PlayerPrefs.set_pref("gv2", Vector2(1, 2))
	PlayerPrefs.set_pref("gv3", Vector3(1, 2, 3))
	PlayerPrefs.set_pref("gv4", Vector4(1, 2, 3, 4))
	PlayerPrefs.set_pref("gc", Color(0.1, 0.2, 0.3, 1))
	PlayerPrefs.set_pref("gr", Rect2(1, 2, 3, 4))
	PlayerPrefs.set_pref("ga", [1, "two"])
	PlayerPrefs.set_pref("gd", {"k": 1})
	_check(PlayerPrefs.get_int("gi", 0) == 42, "get_int returns the stored int")
	_check(PlayerPrefs.get_float("gf", 0) == 2.5, "get_float returns the stored float")
	_check(PlayerPrefs.get_string("gs", "") == "text", "get_string returns the stored string")
	_check(PlayerPrefs.get_bool("gb", false), "get_bool returns the stored bool")
	_check(PlayerPrefs.get_vec2("gv2", Vector2.ZERO) == Vector2(1, 2), "get_vec2 returns the stored Vector2")
	_check(PlayerPrefs.get_vec3("gv3", Vector3.ZERO) == Vector3(1, 2, 3), "get_vec3 returns the stored Vector3")
	_check(PlayerPrefs.get_vec4("gv4", Vector4.ZERO) == Vector4(1, 2, 3, 4), "get_vec4 returns the stored Vector4")
	_check(PlayerPrefs.get_color("gc", Color.WHITE) == Color(0.1, 0.2, 0.3, 1), "get_color returns the stored Color")
	_check(PlayerPrefs.get_rect2("gr", Rect2()) == Rect2(1, 2, 3, 4), "get_rect2 returns the stored Rect2")
	_check(PlayerPrefs.get_array("ga", []) == [1, "two"], "get_array returns the stored Array")
	_check(PlayerPrefs.get_dictionary("gd", {}) == {"k": 1}, "get_dictionary returns the stored Dictionary")
	_check(PlayerPrefs.get_int("gs", -1) == -1, "get_int falls back for a non-int value")
	_check(PlayerPrefs.get_vec2("missing", Vector2(9, 9)) == Vector2(9, 9), "get_vec2 falls back for a missing key")
	_check(PlayerPrefs.get_bool("missing", true), "get_bool falls back for a missing key")


func _raw_saved_data() -> Dictionary:
	var file = FileAccess.open(PlayerPrefs.path, FileAccess.READ)
	if file == null:
		return {}
	var loaded: Variant
	if file.get_buffer(4).get_string_from_ascii() == "PPFS":
		file.get_8()
		loaded = file.get_var()
	else:
		file.seek(0)
		loaded = file.get_var()
	file.close()
	if loaded is Dictionary and loaded.get("data", null) is Dictionary:
		return loaded["data"]
	return {}


func _test_save_on_write_off() -> void:
	_section("save_on_write = false")
	PlayerPrefs.save_on_write = false
	PlayerPrefs.set_pref("deferred", 123)
	_check(not _raw_saved_data().has("deferred"), "mutation is not saved while save_on_write is false")
	_check(PlayerPrefs.save_data(), "explicit save_data returns true")
	_check(_raw_saved_data().get("deferred", 0) == 123, "explicit save_data persists the pending change")
	PlayerPrefs.save_on_write = true
	PlayerPrefs.delete_pref("deferred")


func _test_json_roundtrip() -> void:
	_section("JSON export / import")
	PlayerPrefs.set_pref("json_int", 42)
	PlayerPrefs.set_pref("json_float", 1.5)
	PlayerPrefs.set_pref("json_string", "hello world")
	PlayerPrefs.set_pref("json_bool", false)
	PlayerPrefs.set_pref("json_vec2", Vector2(3, 4))
	PlayerPrefs.set_pref("json_color", Color(0.1, 0.2, 0.3, 0.4))
	PlayerPrefs.set_pref("json_dict", {"nested": [1, 2]})
	var json_path := "user://test_prefs_export.json"
	_check(PlayerPrefs.export_json(json_path), "export_json returns true")
	_check(FileAccess.file_exists(json_path), "exported JSON file exists")
	PlayerPrefs.delete_all()
	_check(PlayerPrefs.import_json(json_path), "import_json returns true")
	_check(PlayerPrefs.get_pref("json_int", 0) == 42, "JSON roundtrip int")
	_check(PlayerPrefs.get_pref("json_float", 0.0) == 1.5, "JSON roundtrip float")
	_check(PlayerPrefs.get_pref("json_string", "") == "hello world", "JSON roundtrip string")
	_check(PlayerPrefs.get_pref("json_bool", true) == false, "JSON roundtrip bool")
	_check(PlayerPrefs.get_pref("json_vec2", Vector2.ZERO) == Vector2(3, 4), "JSON roundtrip Vector2")
	_check(PlayerPrefs.get_pref("json_color", Color.WHITE).is_equal_approx(Color(0.1, 0.2, 0.3, 0.4)), "JSON roundtrip Color")
	_check(PlayerPrefs.get_pref("json_dict", {}) == {"nested": [1, 2]}, "JSON roundtrip nested Dictionary/Array")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(json_path))
	_check(not FileAccess.file_exists(json_path), "test JSON file is cleaned up")


func _test_slots() -> void:
	_section("Save slots")
	PlayerPrefs.set_pref("slot_base_marker", 1)
	PlayerPrefs.set_slot("profile_a")
	_check(PlayerPrefs.get_active_slot() == "profile_a", "active slot switches to the new slot")
	_check(PlayerPrefs.path == "user://prefs_profile_a.save", "slot path follows the slot name")
	_check(PlayerPrefs.get_pref("slot_base_marker", -1) == -1, "new slot starts empty, isolated from the default slot")
	PlayerPrefs.set_pref("slot_only", "a")
	PlayerPrefs.set_slot("")
	_check(PlayerPrefs.get_pref("slot_only", "") == "", "default slot does not see slot data")
	_check(PlayerPrefs.get_pref("slot_base_marker", -1) == 1, "default slot data is restored after switching back")
	PlayerPrefs.set_slot("profile_a")
	_check(PlayerPrefs.get_pref("slot_only", "") == "a", "slot data persists across switches")
	_check(PlayerPrefs.list_slots().has("profile_a"), "list_slots reports the new slot")
	PlayerPrefs.delete_slot("profile_a")
	_check(not PlayerPrefs.list_slots().has("profile_a"), "delete_slot removes the slot file")
	PlayerPrefs.set_slot("")
	_check(PlayerPrefs.list_slots().has(""), "list_slots always reports the default slot")


func _test_version_migration() -> void:
	_section("Version migration")
	PlayerPrefs.save_version = 1
	PlayerPrefs.set_pref("mig_marker", "v1")
	PlayerPrefs.migration_callback = Callable(self, "_on_migrate")
	PlayerPrefs.save_version = 2
	PlayerPrefs.load_data()
	_check(PlayerPrefs.last_loaded_version == 1, "last_loaded_version reports the loaded file version")
	_check(PlayerPrefs.get_pref("mig_added", false), "migration callback result is applied to prefs")
	_check(PlayerPrefs.get_pref("mig_marker", "") == "v1", "original data survives migration")
	PlayerPrefs.save_version = 1
	PlayerPrefs.migration_callback = Callable()


func _on_migrate(from_prefs: Dictionary, from_version: int) -> Dictionary:
	from_prefs["mig_added"] = true
	return from_prefs


func _test_signals() -> void:
	_section("New signals")
	_signal_log.clear()
	PlayerPrefs.pref_deleted.connect(_on_pref_deleted)
	PlayerPrefs.prefs_cleared.connect(_on_prefs_cleared)
	PlayerPrefs.prefs_loaded.connect(_on_prefs_loaded)
	PlayerPrefs.slot_changed.connect(_on_slot_changed)

	PlayerPrefs.set_pref("sig_keep", 1)
	PlayerPrefs.set_pref("sig_delete", 2)
	PlayerPrefs.delete_pref("sig_delete")
	_check(_signal_log.has("pref_deleted:sig_delete"), "pref_deleted fires with the deleted key")

	PlayerPrefs.delete_all()
	_check(_signal_log.has("prefs_cleared"), "prefs_cleared fires on delete_all")

	PlayerPrefs.load_data()
	_check(_signal_log.has("prefs_loaded"), "prefs_loaded fires after load_data")

	PlayerPrefs.set_slot("sig_slot")
	_check(_signal_log.has("slot_changed:sig_slot"), "slot_changed fires with the slot name")
	PlayerPrefs.set_slot("")
	PlayerPrefs.delete_slot("sig_slot")

	PlayerPrefs.pref_deleted.disconnect(_on_pref_deleted)
	PlayerPrefs.prefs_cleared.disconnect(_on_prefs_cleared)
	PlayerPrefs.prefs_loaded.disconnect(_on_prefs_loaded)
	PlayerPrefs.slot_changed.disconnect(_on_slot_changed)


func _on_pref_deleted(key: String) -> void:
	_signal_log.append("pref_deleted:" + key)


func _on_prefs_cleared() -> void:
	_signal_log.append("prefs_cleared")


func _on_prefs_loaded() -> void:
	_signal_log.append("prefs_loaded")


func _on_slot_changed(slot_name: String) -> void:
	_signal_log.append("slot_changed:" + slot_name)


func _test_persistence_across_instances() -> void:
	_section("Persistence across instances")
	PlayerPrefs.set_pref("persist_int", 777)
	PlayerPrefs.set_pref("persist_string", "kept")
	PlayerPrefs.set_pref("persist_vec", Vector2(9, 8))
	PlayerPrefs.save_data()

	var fresh = load("res://addons/PlayerPrefs/PlayerPrefs.gd").new()
	add_child(fresh)
	_check(fresh.get_pref("persist_int", -1) == 777, "fresh instance loads persisted int")
	_check(fresh.get_pref("persist_string", "") == "kept", "fresh instance loads persisted string")
	_check(fresh.get_pref("persist_vec", Vector2.ZERO) == Vector2(9, 8), "fresh instance loads persisted Vector2")
	_check(fresh.get_base() == PlayerPrefs.get_base(), "fresh instance matches the autoload state")
	remove_child(fresh)
	fresh.free()


func _test_save_file_on_disk() -> void:
	_section("Save file on disk")
	PlayerPrefs.set_pref("file_check", "present")
	_check(FileAccess.file_exists(PlayerPrefs.path), "save file exists on disk")

	var file = FileAccess.open(PlayerPrefs.path, FileAccess.READ)
	_check(file != null, "save file is readable")
	if file:
		var magic: String = file.get_buffer(4).get_string_from_ascii()
		var format: int = file.get_8()
		var loaded: Variant = file.get_var()
		file.close()
		_check(magic == "PPFS", "file starts with the PPFS magic header")
		_check(format == 0, "file uses the plaintext format marker")
		_check(loaded is Dictionary, "file content deserializes to a Dictionary")
		_check(loaded.get("data", {}).get("file_check", "") == "present", "file content contains the latest values")
	_check(FileAccess.file_exists(PlayerPrefs.path + ".bak"), "backup file is created after the first save")
