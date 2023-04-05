extends Node

var resources = []
var enabled = false

func _ready():
	if enabled:
		var contentdir = DirAccess.open("user://content")
		if contentdir:
			contentdir.list_dir_begin()
			var file = contentdir.get_next()
			while file != "":
				var _success = ProjectSettings.load_resource_pack("user://content/"+file)
				var toyname = file.replace(".pck", "")
				var txt = ConfigFile.new()
				txt.load("res://toys/" + toyname + "/" + toyname + ".cfg")
				var scene = txt.get_value("Config", "scene")
				var scn = load("res://toys/" + toyname + "/" + scene)
				if scn:
					resources.push_back(scn)
				file = contentdir.get_next()
		else:
			var dir = DirAccess.open("user://")
			dir.make_dir("content")
