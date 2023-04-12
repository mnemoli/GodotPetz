extends Toy

var locked = false

func add_item_to_shelf(item):
	item.reparent($slots/slot1)
	item.position = Vector2.ZERO
	item.rotation = 0
	(item.get_node("AnimatedSprite2D") as AnimatedSprite2D).speed_scale = 1.0
	(item.get_node("AnimatedSprite2D") as AnimatedSprite2D).play("away", 1.0)
	item.get_node("Area2D").input_pickable = true
	item.toy_state = ToyState.AWAY
	Cursor.set_normal()
		
func _on_doorarea_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and !locked:
		$bits/lock.visible = false
		$bits/door.play("open_back")

func _on_lockarea_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if locked and !$bits/lock.is_playing():
			$bits/lock.play("lock_bwd")
		elif !$bits/lock.is_playing():
			$bits/lock.play("lock_fwd")

func _on_lock_animation_finished():
	var anim = $bits/lock.animation
	if anim == "lock_bwd":
		locked = false
	elif anim == "lock_fwd":
		locked = true

func _on_door_animation_finished():
	$bits/lock.visible = true

func open_door_for_pet():
	$bits/lock.visible = false
	$bits/door.play("open_front")
