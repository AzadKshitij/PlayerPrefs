extends Node
## Responsible for saving Player preferences in your game.
##
## THis script is the base for the implementation and holds functions responsible for storing and retriing the data.
##

## Holds player preferenceses
var prefs: Dictionary = {}
var filename: String = "prefs.save"
var path: String = "user://"


func _init() -> void:
	print("Initializing PlayerPrefs")
	path = path + filename
	if not FileAccess.file_exists(path):
		save_data()
	else:
		load_data()


## For setting base values for player prefs
## Usage:
## [codeblock]
## PlayerPrefs.set_pref({"health": 100, "score": 0})
## [/codeblock]
func set_base(value: Dictionary):
	prefs = value


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
func set_pref(key: String, value):
	prefs[key] = value
	await save_data()


## To get a preference provided "key"
## Usage:
## [codeblock]
## PlayerPrefs.get_prefs("health", 0)
## [/codeblock]
func get_pref(key: String, default_value):
	if prefs.has(key):
		return prefs[key]
	else:
		return default_value


func delete_pref(key: String):
	if prefs.has(key):
		prefs.erase(key)
		await save_data()

func delete_all():
	prefs.clear()
	await save_data()


func save_data():
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_var(prefs)
	file.close()


func load_data():
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		prefs = file.get_var()
	else:
		save_data()
	file.close()
