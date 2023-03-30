extends Node2D

func _ready():
	for res in ContentLoader.resources:
		var obj = res.instantiate() as Node2D
		add_child(obj)
		obj.global_position = Vector2(200, 200)
