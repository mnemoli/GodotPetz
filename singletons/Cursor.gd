extends Node

@onready var player = get_tree().root.get_node("Root/CanvasLayer/Cursoranims")
@onready var raycast = get_tree().root.get_node("Root/Holder/RayCast2D")
var held_item = null

func _ready():
	player.connect("frame_changed", update_frame)

func set_normal():
	held_item = null
	player.play("pickup", -1)

func set_holding(item):
	held_item = item
	player.play("pickup")
	
func update_frame():
	Input.set_custom_mouse_cursor(player.sprite_frames.get_frame_texture(player.animation, player.frame))

func _input(event):
	if event is InputEventMouseButton and !event.pressed and held_item != null:
		if raycast.is_colliding():
			var case = raycast.get_collider().get_parent()
			case.add_item_to_shelf(held_item)
		else:
			held_item.drop()
