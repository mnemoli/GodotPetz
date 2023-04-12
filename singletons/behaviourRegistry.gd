extends Node

var behaviours: Dictionary

func _ready():
	var files = DirAccess.open("res://behaviour").get_files()
	for bhav_res in files:
		var bhav = load("res://behaviour/" + bhav_res).new()
		if bhav.in_registry():
			behaviours[bhav_res.rstrip(".gd")] = bhav
