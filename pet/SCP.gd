extends Node

var scp: PetzScpResource = preload("res://animations/CAT.scp")
var graph: Dictionary
var actionStack = []
var processing = false
var current_scriptstack_pos = 0
var current_state = scp.get_start_state()

signal action_done

func _ready():
	for a in scp.get_actions():
		var ar = graph.get(a.startState, [])
		ar.push_back({endState = a.endState, actionId = a.id})
		graph[a.startState] = ar

func push_action(goal_action):
	actionStack = find_path(current_state, goal_action)

func find_path(start_state, goal_action):
	var action = scp.get_action(goal_action)
	var end_state = action.endState
	var explored = Dictionary()
	var q = []
	q.push_back({stateId = start_state, actionId = null, parent = null})
	explored[start_state] = true
	while !q.is_empty():
		var v = q.pop_front()
		if v.actionId == goal_action:
			var path = []
			while v.parent:
				path.push_back(v.actionId)
				v = v.parent
			path.reverse()
			return path
		var edgear = graph.get(v.stateId, []) as Array
		edgear.shuffle()
		for edge in edgear:
			if !explored.has(edge.endState) || edge.actionId == goal_action:
				explored[edge.endState] = true
				var w = {stateId = edge.endState, actionId = edge.actionId, parent = v}
				q.push_back(w)

func _process(_delta):
	if !actionStack.is_empty() and !processing:
		var curaction = scp.get_action(actionStack.front())
		var scriptelems = curaction.scripts[0] as Array
		while current_scriptstack_pos < scriptelems.size():
			if scriptelems[current_scriptstack_pos] == 0x40000033: # seq2
				processing = true
				var minframe = scriptelems[current_scriptstack_pos+1]
				var maxframe = scriptelems[current_scriptstack_pos+2]
				current_scriptstack_pos+=2
				if maxframe < minframe:
					print("uh oh backwards anim")
				#print("requesting anim from " + str(minframe))
				get_parent().play_anim(minframe, maxframe - minframe)
				await get_parent().animation_done
				processing = false
			else:
				current_scriptstack_pos+=1
		var last = actionStack.pop_front()
		current_scriptstack_pos = 0
		current_state = scp.get_action(last).endState
		get_parent().update_pos()
		if actionStack.is_empty():
			emit_signal("action_done")
