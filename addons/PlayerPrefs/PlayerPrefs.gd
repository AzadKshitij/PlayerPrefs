extends Node
class_name PlayerPref
## Responsible for saving Player preferences in your game.
##
## This script is the base for the implementation and holds functions responsible for storing and retrieving the data.
##
## Data is written synchronously to [member path] as an unencrypted Variant stream
## via [code]FileAccess.store_var()[/code].

signal prefs_changed(key: String, value)

## Holds player preferences
var prefs: Dictionary = {}
var filename: String = "prefs.save"
var path: String = "user://"


func _init() -> void:
	path = path + filename


func _ready() -> void:
	if FileAccess.file_exists(path):
		load_data()
	else:
		save_data()


## For setting base values for player prefs
## Usage:
## [codeblock]
## PlayerPrefs.set_base({"health": 100, "score": 0})
## [/codeblock]
func set_base(value: Dictionary) -> void:
	prefs = value
	prefs_changed.emit("base", value)
	save_data()


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
	save_data()


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


## Deletes a preference provided "key"
func delete_pref(key: String) -> void:
	if prefs.has(key):
		prefs.erase(key)
		save_data()


## Deletes all preferences
func delete_all() -> void:
	prefs.clear()
	save_data()


## Saves [member prefs] to [member path] synchronously
func save_data() -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("PlayerPrefs: Could not open file for writing: %s" % path)
		return
	file.store_var(prefs)
	file.close()


## Loads [member prefs] from [member path]
func load_data() -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("PlayerPrefs: Could not open file for reading: %s" % path)
		return
	prefs = file.get_var()
	file.close()
