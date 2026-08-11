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
		var loaded: Variant = file.get_var()
		file.close()
		_check(loaded is Dictionary, "file content deserializes to a Dictionary")
		_check(loaded.get("file_check", "") == "present", "file content contains the latest values")
