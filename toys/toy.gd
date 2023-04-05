extends RigidBody2D

class_name Toy

enum ToyState {
	DEFAULT,
	HELD,
	AWAY
}

var toy_state: ToyState = ToyState.DEFAULT
@onready var holder = get_tree().root.get_node("Root/Holder") as Node2D
var last_pos = Vector2.ZERO
var over_case = false
@export_category("Toy")
@export var center_when_picked_up = true
@export var screen_force_multiplier = 1.0

func _process(_delta):
	var bounds = get_viewport_rect().size
	if toy_state == ToyState.HELD:
		var mp = get_global_mouse_position()
		if mp.x > 0 and mp.x < bounds.x and mp.y > 0 and mp.y < bounds.y:
			last_pos = mp
			holder.global_position = last_pos
	elif toy_state == ToyState.DEFAULT:
		if !Rect2(Vector2.ZERO, bounds).has_point(global_position):
			var vec_back_to_screen = (bounds/2.0 - global_position)
			apply_central_impulse((vec_back_to_screen / 100.0) * screen_force_multiplier)

func _on_sleeping_state_changed():
	if sleeping and toy_state != ToyState.AWAY:
		$AnimatedSprite2D.pause()

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and Cursor.held_item == null:
		freeze = true
		if has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.animation = "rest"
		holder.global_position = get_global_mouse_position()
		reparent(holder)
		if center_when_picked_up:
			position = Vector2(10,10)
		toy_state = ToyState.HELD
		Cursor.set_holding(self)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and !event.pressed and !over_case and Cursor.held_item == self:
		drop()
		
func drop():
	freeze = false
	toy_state = ToyState.DEFAULT
	reparent(holder.get_parent())
	var vec = get_global_mouse_position() - last_pos
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.animation = "used1"
		$AnimatedSprite2D.play()
	vec.clamp(Vector2(200,200), Vector2(300,300))
	apply_central_impulse(vec)
	Cursor.set_normal()
	get_viewport().set_input_as_handled()
