extends Node

@onready var pet = get_parent()
@onready var scpinfo = get_tree().get_first_node_in_group("scpinfo")
@onready var curscpinfo = get_tree().get_first_node_in_group("curscpinfo")
@onready var lookatinfo = get_tree().get_first_node_in_group("lookatinfo")
@onready var lnz = get_tree().get_first_node_in_group("petlnz")
@onready var scp = pet.get_node("SCP")

func _ready():
	pet.apply_anim_movement = false
	
func _on_button_toggled(button_pressed):
	if !lnz.text.is_empty():
		pet.set_lnz_raw(lnz.text)
	var bhav = pet.get_node("Brain").current_bhav
	if button_pressed:
		bhav.scp_start = scpinfo.get_node("startstate").text as int
		bhav.scp_action = scpinfo.get_node("action").text as int
		bhav.pet_rotation = scpinfo.get_node("rotation").text as int + 180
		bhav.go = true
	else:
		# skip to end of script and anim
		scp.actionStack = []
		scp.script_stack = []
		if pet.frames_length >= 0:
			pet.current_frame = pet.frames_length - pet.anim_direction
		bhav.go = false

func _process(_delta):
	curscpinfo.get_node("curscpinfo/curstate").text = str(scp.current_state)
	if !scp.actionStack.is_empty():
		curscpinfo.get_node("curscpinfo/curaction").text = str(scp.actionStack.front())
	curscpinfo.get_node("curscpinfo/curscript").text = str(scp.current_script_no)
	curscpinfo.get_node("HBoxContainer/nextstate").text = str(scp.next_state)
	lookatinfo.get_node("TextEdit").text = str(pet.HEAD_TARGET_TYPE.keys()[pet.head_target_type]) + " " + str(pet.EYE_TARGET_TYPE.keys()[pet.eye_target_type])


func _on_scp_selected(index):
	if(index == 0):
		scp.breed_scp = null
		scpinfo.get_node("pickaction").disabled = true
	else:
		scpinfo.get_node("pickaction").disabled = false
		var scpname = scps[index - 1]
		var scpfile = load("res://animations/" + scpname + ".scp") as PetzScpResource
		var actions = scpfile.get_actions()
		var menu = scpinfo.get_node("pickaction").get_popup() as PopupMenu
		menu.clear()
		for k in actions:
			menu.add_item(str(k), k)
		scp.breed_scp = scpfile

const scps = ["AC", "BW", "CA", "MC", "OR", "RB", "RD", "SI", "TA"]


func _on_pickaction_item_selected(index):
	var id = scpinfo.get_node("pickaction").get_popup().get_item_id(index)
	var scpfile = scp.breed_scp
	var action = scpfile.get_action(id)
	scpinfo.get_node("startstate").text = str(action.startState)
	scpinfo.get_node("action").text = str(id)
	scpinfo.get_node("pickaction").selected = -1
