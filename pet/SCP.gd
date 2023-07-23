extends Node

@onready var pet = get_parent()
var scp: PetzScpResource = preload("res://animations/CAT.scp")
var graph: Dictionary
var actionStack = []
var processing = false
var current_state = scp.get_start_state()
var script_stack = []
var last_action = -1

signal action_done

func _ready():
	for a in scp.get_actions():
		var ar = graph.get(a.startState, [])
		ar.push_back({endState = a.endState, actionId = a.id})
		graph[a.startState] = ar

func push_action(goal_action):
	actionStack = find_path(current_state, goal_action)

func find_path(start_state, goal_action):
	var desired_state = scp.get_action(goal_action).startState
	if start_state == desired_state:
		return [goal_action]
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
		processing = true
		var curaction = scp.get_action(actionStack.front())
		get_parent().loop = last_action == curaction.id
		script_stack = curaction.scripts[0].duplicate()
		while !script_stack.is_empty():
			var currentelem = script_stack.pop_front()
			match currentelem: # seq2
				0x4000001B: #lookAtSprite1
					pet.head_target_type = pet.HEAD_TARGET_TYPE.TARGET
					script_stack.pop_front()
				0x4000001C: #lookAtSpriteEyes1
					pet.eye_target_type = pet.EYE_TARGET_TYPE.TARGET
					script_stack.pop_front()
				0x4000001D: #lookAtUser0
					pet.head_target_type = pet.HEAD_TARGET_TYPE.USER
					pet.eye_target_type = pet.EYE_TARGET_TYPE.USER
				0x4000001F: #lookForward0
					pet.head_target_type = pet.HEAD_TARGET_TYPE.FORWARD
				0x4000001F: #lookForwardEyes0
					pet.eyes_target_type = pet.EYES_TARGET_TYPE.FORWARD
				0x40000033:
					var minframe = script_stack.pop_front()
					var maxframe = script_stack.pop_front()
					var direction = 1
					if maxframe < minframe:
						print("uh oh backwards anim")
						direction = -1
					#print("requesting anim from " + str(minframe))
					get_parent().play_anim(minframe, abs(maxframe - minframe) + 1, direction)
					await get_parent().animation_done
				0x40000027: #playaction2
					var actionid = script_stack.pop_front()
					var times = script_stack.pop_front()
					print("playing " + str(actionid) + " " + str(times) + " times")
					if times == 0x4000002F: #rand2
						var rand1 = script_stack.pop_front()
						var rand2 = script_stack.pop_front()
						times = randi_range(rand1, rand2)
					var newelems = scp.get_action(actionid).scripts[0].duplicate()
					var cop = newelems.duplicate()
					newelems.push_back(0x40000014)
					for i in range(0, times):
						newelems.append_array(cop)
					newelems.append_array(script_stack)
					script_stack = newelems
				0x4000000F: #enablefudgeaim1
					script_stack.pop_front()
				0x40000009: #cuecode1
					script_stack.pop_front()
				0x40000014: #gluescriptsball1
					get_parent().update_pos()
				0x40000057: #startBlockChance1
					var chance = script_stack.pop_front()
					if chance == 0x4000002F:
						chance = randi_range(script_stack.pop_front(), script_stack.pop_front())
					var random = randi_range(0, 100)
					if random > chance: # we don't run to run the block
						var elem
						while elem != 0x40000011:
							elem = script_stack.pop_front()
					# otherwise just continue processing
				_: 
					if currentelem < 0x40000000: #frame number
						if currentelem < 0 or currentelem > 16040:
							print("BIG MISTAKE")
						else:
							get_parent().play_anim(currentelem, 1, 1)
							await get_parent().animation_done
					else:
						var verbname = scpVerbs[currentelem] as String
						var argcount = verbname.right(1)
						if argcount.is_valid_int():
							argcount = argcount as int
						else:
							argcount = 0
						for n in range(argcount):
							var top = script_stack.pop_front()
							if top == 0x4000002F: #rand2
								script_stack.pop_front()
								script_stack.pop_front()
		processing = false
		last_action = actionStack.pop_front()
		current_state = scp.get_action(last_action).endState
		get_parent().update_pos()
		if actionStack.is_empty():
			emit_signal("action_done")

var scpVerbs = {
	0x40000000 : "startPos",

0x40000001 : "actionDone0",

0x40000002 : "actionStart1",

0x40000003 : "alignScripts0",

0x40000004 : "alignBallToPtSetup3",

0x40000005 : "alignBallToPtGo0",

0x40000006 : "alignBallToPtStop0",

0x40000007 : "alignFudgeBallToPtSetup2",

0x40000008 : "blendToFrame3",

0x40000009 : "cueCode1",

0x4000000A : "debugCode1",

0x4000000B : "disableFudgeAim1",

0x4000000C : "disableSwing0",

0x4000000D : "doneTalking0",

0x4000000E : "doneTalking1",

0x4000000F : "enableFudgeAim1",

0x40000010 : "enableSwing1",

0x40000011 : "endBlock0",

0x40000012 : "endBlockAlign0",

0x40000013 : "glueScripts0",

0x40000014 : "glueScriptsBall1",

0x40000015 : "interruptionsDisable0",

0x40000016 : "interruptionsEnable0",

0x40000017 : "lookAtLocation2",

0x40000018 : "lookAtLocationEyes2",

0x40000019 : "lookAtRandomPt0",

0x4000001A : "lookAtRandomPtEyes0",

0x4000001B : "lookAtSprite1",

0x4000001C : "lookAtSpriteEyes1",

0x4000001D : "lookAtUser0",

0x4000001E : "lookForward0",

0x4000001F : "lookForwardEyes0",

0x40000020 : "null0",

0x40000021 : "null1",

0x40000022 : "null2",

 

0x40000023 : "null3",

 

0x40000024 : "null4",

 

0x40000025 : "null5",

 

0x40000026 : "null6",

 

0x40000027 : "playAction2",

 

0x40000028 : "playActionRecall2",

 

0x40000029 : "playActionStore2",

 

0x4000002A : "playLayeredAction3",

 

0x4000002B : "playLayeredAction4",

 

0x4000002C : "playLayeredActionCallback5",

 

0x4000002D : "playLayeredActionCallback6",

 

0x4000002E : "playTransitionToAction1",

 

0x4000002F : "rand2",

 

0x40000030 : "resetFudger1",

 

0x40000031 : "resumeFudging1",

 

0x40000032 : "resumeLayerRotation1",

 

0x40000033 : "sequence2",

0x40000034 : "sequenceToEnd1",

0x40000035 : "sequenceToStart1",

0x40000036 : "setBlendOffset3",

0x40000037 : "setFudgeAimDefaults5",

0x40000038 : "setFudgerDrift2",

0x40000039 : "setFudgerRate2",

0x4000003A : "setFudgerTarget2",

0x4000003B : "setFudgerNow2",

0x4000003C : "setHeadTrackAcuteness",

0x4000003D : "setHeadTrackMode1",

0x4000003E : "setLayeredBaseFrame2",

0x4000003F : "setMotionScale1",

0x40000040 : "setMotionScale2",

0x40000041 : "setReverseHeadTrack1",

0x40000042 : "setRotationPivotBall1",

 

0x40000043 : "soundEmptyQueue0",

 

0x40000044 : "soundLoop1",

 

0x40000045 : "soundSetPan1",

 

0x40000046 : "soundPlay1",

 

0x40000047 : "soundPlay2",

 

0x40000048 : "soundPlay3",

 

0x40000049 : "soundPlay4",

 

0x4000004A : "soundPlay5",

 

0x4000004B : "soundQueue1",

 

0x4000004C : "soundQueue2",

 

0x4000004D : "soundQueue3",

 

0x4000004E : "soundQueue4",

 

0x4000004F : "soundQueue5",

 

0x40000050 : "soundSetDefltVocPitch1",

 

0x40000051 : "soundSetPitch1",

 

0x40000052 : "soundSetVolume1",

 

0x40000053 : "soundStop0",

 

0x40000054 : "startListening0",

 

0x40000055 : "startBlockLoop1",

 

0x40000056 : "startBlockCallback2",

 

0x40000057 : "startBlockChance1",

 

0x40000058 : "startBlockDialogSynch0",

 

0x40000059 : "startBlockElse0",

 

0x4000005A : "startBlockListen0",

 

0x4000005B : "stopFudging1",

 

0x4000005C : "suspendFudging1",

 

0x4000005D : "suspendLayerRotation1",

 

0x4000005E : "tailSetNeutral1",

 

0x4000005F : "tailSetRestoreNeutral1",

 

0x40000060 : "tailSetWag1",

 

0x40000061 : "targetSprite4",

 

0x40000062 : "throwMe0",

 

0x40000063 : "endPos",
}
