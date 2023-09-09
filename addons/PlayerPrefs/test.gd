extends Node


func _ready():
	print("PlayerPrefs test: ", PlayerPrefs)
	if PlayerPrefs:
		test()


func test():
	PlayerPrefs.set_pref("test", 1)
	assert(PlayerPrefs.get_pref("test", 0) == 1)
	PlayerPrefs.set_pref("test2", "test")
	assert(PlayerPrefs.get_pref("test2", 0) == "test")
	PlayerPrefs.set_pref("test3", Vector2(1, 2))
	assert(PlayerPrefs.get_pref("test3", 0) == Vector2(1, 2))
	PlayerPrefs.set_pref("test4", Vector3(1, 2, 3))
	assert(PlayerPrefs.get_pref("test4", 0) == Vector3(1, 2, 3))
	PlayerPrefs.set_pref("test5", Vector4(1, 2, 3, 4))
	assert(PlayerPrefs.get_pref("test5", 0) == Vector4(1, 2, 3, 4))
	PlayerPrefs.set_pref("test6", Color(1, 2, 3, 4))
	assert(PlayerPrefs.get_pref("test6", 0) == Color(1, 2, 3, 4))
	PlayerPrefs.set_pref("test7", Rect2(1, 2, 3, 4))
	assert(PlayerPrefs.get_pref("test7", 0) == Rect2(1, 2, 3, 4))

	print("All tests passed!")
