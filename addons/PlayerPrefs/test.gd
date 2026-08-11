extends Node


func _ready():
	print("PlayerPrefs test: ", PlayerPrefs)
	if PlayerPrefs:
		test()


func save_player():
	PlayerPrefs.set_pref("no", 1)
	PlayerPrefs.set_pref("name", "godot")
	PlayerPrefs.set_pref("crosshair_position", Vector2(1, 2))
	PlayerPrefs.set_pref("player_position", Vector3(1, 2, 3))
	PlayerPrefs.set_pref("random_info", Vector4(1, 2, 3, 4))
	PlayerPrefs.set_pref("color", Color(1, 2, 3, 4))
	PlayerPrefs.set_pref("item_rect", Rect2(1, 2, 3, 4))


func get_player():
	assert(PlayerPrefs.get_pref("no", 0) == 1)
	assert(PlayerPrefs.get_pref("name", "") == "godot")
	assert(PlayerPrefs.get_pref("crosshair_position", Vector2(0, 0)) == Vector2(1, 2))
	assert(PlayerPrefs.get_pref("player_position", Vector3(0, 0, 0)) == Vector3(1, 2, 3))
	assert(PlayerPrefs.get_pref("random_info", Vector4(0, 0, 0, 0)) == Vector4(1, 2, 3, 4))
	assert(PlayerPrefs.get_pref("color", Color(0, 0, 0, 0)) == Color(1, 2, 3, 4))
	assert(PlayerPrefs.get_pref("item_rect", Rect2(0, 0, 0, 0)) == Rect2(1, 2, 3, 4))


func set_player_base():
	var player = {
		"no": 1,
		"score": 0,
		"crosshair_position": Vector2(1, 2),
		"player_position": Vector3(1, 2, 3),
		"random_info": Vector4(1, 2, 3, 4),
		"color": Color(1, 2, 3, 4),
		"item_rect": Rect2(1, 2, 3, 4)
	}

	PlayerPrefs.set_base(player)


func get_player_base():
	var base = PlayerPrefs.get_base()
	assert(base.get("no") == 1)
	assert(base.get("score") == 0)
	assert(base.get("crosshair_position") == Vector2(1, 2))
	assert(base.get("player_position") == Vector3(1, 2, 3))
	assert(base.get("random_info") == Vector4(1, 2, 3, 4))
	assert(base.get("color") == Color(1, 2, 3, 4))
	assert(base.get("item_rect") == Rect2(1, 2, 3, 4))
	assert(PlayerPrefs.get_pref("no", -1) == 1)
	assert(PlayerPrefs.get_pref("score", -1) == 0)
	assert(PlayerPrefs.get_pref("crosshair_position", Vector2(0, 0)) == Vector2(1, 2))
	assert(PlayerPrefs.get_pref("player_position", Vector3(0, 0, 0)) == Vector3(1, 2, 3))
	assert(PlayerPrefs.get_pref("random_info", Vector4(0, 0, 0, 0)) == Vector4(1, 2, 3, 4))
	assert(PlayerPrefs.get_pref("color", Color(0, 0, 0, 0)) == Color(1, 2, 3, 4))
	assert(PlayerPrefs.get_pref("item_rect", Rect2(0, 0, 0, 0)) == Rect2(1, 2, 3, 4))

	print("All tests passed!")


func test():
	save_player()
	#get_player()
	#set_player_base()
	#get_player_base()
