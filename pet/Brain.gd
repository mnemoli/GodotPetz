extends Node

var pet: Node2D
var scp: Node

@export var processing = true

func _ready():
	if processing:
		var bhav = load("res://behaviour/chaseCursor.gd").new()
		add_child(bhav)
		bhav.behaviour_done.connect(create_new_goal)
		pet = get_parent()
		scp = get_parent().get_node("SCP")
		bhav.call_deferred("execute", pet, null, null)

func create_new_goal():
	print("generating new goal")
	var rated: Dictionary
	for bhav in BehaviourRegistry.behaviours.values():
		var rating = bhav.advertise(pet, Cursor, null)
		rated[rating] = bhav
	var new_goal = (rated[rated.keys().max()] as Behaviour).duplicate()
	add_child(new_goal)
	new_goal.behaviour_done.connect(create_new_goal)
	new_goal.execute(pet, null, null)
		
