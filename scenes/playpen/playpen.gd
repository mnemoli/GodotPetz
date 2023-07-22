extends Node2D

func _ready():
	for res in ContentLoader.resources:
		var obj = res.instantiate() as Node2D
		add_child(obj)
		obj.global_position = Vector2(200, 200)

func _process(_delta):
	$CanvasLayer/TextEdit.text = str(Engine.get_frames_per_second())
