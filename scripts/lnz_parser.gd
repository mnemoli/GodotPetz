extends Node
class_name LnzParser

var r = RegEx.new()
var str_r = RegEx.new()

var species = 0
var scales = Vector2(255, 255)
var leg_extensions = Vector2(0, 0)
var body_extension = 0
var face_extension = 0
var ear_extension = 0
var head_enlargement = Vector2(100, 0)
var foot_enlargement = Vector2(100, 0)
var moves = []
var balls = {}
var lines = []
var addballs = {}
var paintballs = {}
var omissions = {}
var project_ball = []
var texture_list = []
var whiskers = []

var file_path

func get_next_section(file, section_name: String):
	file.seek(0)
	var this_line = ""
	while !this_line.begins_with("[" + section_name + "]") and !file.eof_reached():
		this_line = file.get_line()
	if file.eof_reached():
		return false
	return true
	
func get_parsed_lines(file, keys: Array):
	var return_array = []
	while true:
		var line = file.get_line().dedent()
		if line.is_empty() or line.begins_with("[") or file.eof_reached() or line.begins_with("#2"):
			break
		if line.begins_with(";") or line.begins_with("#"):
			continue
		var parsed = r.search_all(line)
		var dict = {}
		var i = 0
		for key in keys:
			dict[key] = int(parsed[i].get_string())
			i += 1
		return_array.append(dict)
	return return_array
	
func get_parsed_line_strings(file, keys: Array):
	var return_array = []
	while true:
		var line = file.get_line().dedent()
		if line.is_empty() or line.begins_with("[") or file.eof_reached() or line.begins_with("#2"):
			break
		if line.begins_with(";") or line.begins_with("#"):
			continue
		var parsed = str_r.search_all(line)
		var dict = {}
		var i = 0
		for key in keys:
			dict[key] = parsed[i].get_string()
			i += 1
		return_array.append(dict)
	return return_array

func _init(init_file_path):
	self.file_path = init_file_path
	r.compile("[-.\\d]+")
	str_r.compile("[\\S]+")
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	var this_line = ""
	
	get_texture_list(file)
	get_species(file)
	get_default_scales(file)
	get_leg_extensions(file)
	get_body_extension(file)
	get_face_extension(file)
	get_ear_extension(file)
	get_head_enlargement(file)
	get_feet_enlargement(file)
	get_omissions(file)
	get_lines(file)
	get_balls(file)
	
	file.seek(0)
	
	get_addballs(file)
	get_project_balls(file)
	
	get_whiskers(file)
		
	## Get paintballz
	while this_line != "[Paint Ballz]" and !file.eof_reached():
		this_line = file.get_line()
	while(true):
		this_line = file.get_line()
		if this_line.is_empty() or this_line.begins_with("[") or file.eof_reached() or this_line.begins_with("#2"):
			break
		if this_line.begins_with(";") or this_line.begins_with('#'):
			continue
		var split_line = r.search_all(this_line)
		var base = int(split_line[0].get_string())
		var diameter_percent = int(split_line[1].get_string())
		var x = float(split_line[2].get_string())
		var y = float(split_line[3].get_string())
		var z = float(split_line[4].get_string())
		var color = int(split_line[5].get_string())
		var outline_color = int(split_line[6].get_string())
		if (outline_color == -1):
			outline_color = 0
		var fuzz = int(split_line[7].get_string())
		var outline = int(split_line[8].get_string())
		var texture = int(split_line[10].get_string())
		var anchored = 0
		if split_line.size() > 11:
			anchored = int(split_line[11].get_string())
		var paintball = PaintBallData.new(base, diameter_percent, Vector3(x,y,z), color, outline_color, outline, fuzz, 0, texture, anchored)
		var pb_array = self.paintballs.get(base, [])
		pb_array.append(paintball)
		self.paintballs[base] = pb_array
		
	## Get move data
	file.seek(0)
	while !this_line.begins_with("[Move]") and !file.eof_reached():
		this_line = file.get_line()
	while(true):
		this_line = file.get_line()
		if this_line.is_empty() or this_line.begins_with("[") or file.eof_reached() or this_line.begins_with("#2"):
			break
		if this_line.begins_with(";") or this_line.begins_with('#'):
			continue
		var split_line = r.search_all(this_line)
		var base = int(split_line[0].get_string())
		var x = int(split_line[1].get_string())
		var y = int(split_line[2].get_string())
		var z = int(split_line[3].get_string())
		var relative_ball = base
		if split_line.size() > 4:
			relative_ball = int(split_line[4].get_string())
		var pos = Vector3(x, y, z)
		moves.push_back({base = base, position = pos, relative_to = relative_ball})
		
	file.close()
	
func get_default_scales(file):
	get_next_section(file, "Default Scales")
	var parsed_lines = get_parsed_lines(file, ["scale"])
	if parsed_lines.size() > 0:
		scales = Vector2(parsed_lines[0].scale / 255.0, parsed_lines[1].scale / 255.0)
	
func get_leg_extensions(file):
	get_next_section(file, "Leg Extension")
	var parsed_lines = get_parsed_lines(file, ["extension"])
	if parsed_lines.size() > 0:
		leg_extensions = Vector2(parsed_lines[0].extension, parsed_lines[1].extension)
	
func get_body_extension(file):
	get_next_section(file, "Body Extension")
	var parsed_lines = get_parsed_lines(file, ["extension"])
	if parsed_lines.size() > 0:
		body_extension = parsed_lines[0].extension
	
func get_face_extension(file):
	get_next_section(file, "Face Extension")
	var parsed_lines = get_parsed_lines(file, ["extension"])
	if parsed_lines.size() > 0:
		face_extension = parsed_lines[0].extension

func get_ear_extension(file):
	get_next_section(file, "Ear Extension")
	var parsed_lines = get_parsed_lines(file, ["extension"])
	if parsed_lines.size() > 0:
		ear_extension = parsed_lines[0].extension
	
func get_head_enlargement(file):
	get_next_section(file, "Head Enlargement")
	var parsed_lines = get_parsed_lines(file, ["scale"])
	if parsed_lines.size() > 0:
		head_enlargement = Vector2(parsed_lines[0].scale, parsed_lines[1].scale)
	
func get_feet_enlargement(file):
	get_next_section(file, "Feet Enlargement")
	var parsed_lines = get_parsed_lines(file, ["scale"])
	if parsed_lines.size() > 0:
		foot_enlargement = Vector2(parsed_lines[0].scale, parsed_lines[1].scale)
	
func get_omissions(file):
	get_next_section(file, "Omissions")
	var parsed_lines = get_parsed_lines(file, ["ball_no"])
	omissions = {}
	for line in parsed_lines:
		omissions[line.ball_no] = true
		
func get_lines(file):
	get_next_section(file, "Linez")
	var parsed_lines = get_parsed_lines(file, ["start", "end", "fuzz", "color", "l_color", "r_color", "start_thickness", "end_thickness"])
	for line in parsed_lines:
		var line_data = LineData.new(line.start, line.end, line.start_thickness, line.end_thickness, line.fuzz, line.color, line.l_color, line.r_color)
		lines.append(line_data)
		
func get_balls(file):
	get_next_section(file, "Ballz Info")
	var parsed_lines = get_parsed_lines(file, ["color", "outline_color", "speckle", "fuzz", "outline", "size", "group", "texture"])
	var i = 0
	for line in parsed_lines:
		var bd = BallData.new(
			line.size, 
			Vector3.ZERO, 
			i, 
			Vector3.ZERO,
			line.color,
			line.outline_color, 
			line.outline, 
			line.fuzz, 
			0.0, 
			line.group, 
			line.texture)
		self.balls[i] = bd
		i += 1

func get_addballs(file):
	get_next_section(file, "Add Ball")
	var parsed_lines = get_parsed_lines(file, ["base", "x", "y", "z", "color", "outline_color", "speckle", "fuzz", "group", "outline", "size", "body_area", "add_group", "texture"])
	var max_ball_num = balls.keys().max() + 1
	for line in parsed_lines:
		var pos = Vector3(line.x, line.y, line.z)
		var ball = AddBallData.new(
			line.base,
			max_ball_num, 
		line.size, 
		pos,
		line.color, 
		line.outline_color, 
		line.outline, 
		line.fuzz,
		0, 
		line.group, 
		line.body_area, 
		line.texture)
		addballs[max_ball_num] = ball
		max_ball_num += 1
		
func get_project_balls(file):
	get_next_section(file, "Project Ball")
	var parsed_lines = get_parsed_lines(file, ["base", "projected", "amount"])
	for line in parsed_lines:
		project_ball.append({ball = line.projected, base = line.base, amount = line.amount})
		
func get_whiskers(file):
	get_next_section(file, "Whiskers")
	var parsed_lines = get_parsed_lines(file, ["start", "end"])
	for line in parsed_lines:
		whiskers.push_back({start = line.start, end = line.end})

func get_species(file):
	get_next_section(file, "Species")
	var parsed_lines = get_parsed_lines(file, ["species"])
	if parsed_lines.size() == 0:
		species = 2
	else:
		species = parsed_lines[0].species

func get_texture_list(file):
	get_next_section(file, "Texture List")
	var parsed_lines = get_parsed_line_strings(file, ["filepath", "transparent_color"])
	for line in parsed_lines:
		var filename = line.filepath.get_file()
		texture_list.append({filename = filename, transparent_color = line.transparent_color})

var cat_ball_names = [
	"ankleL", 
"ankleR", 
"belly", 
"butt", 
"cheekL", 
"cheekR", 
"chest", 
"chin", 
"earL1", 
"earL2", 
"earR1", 
"earR2", 
"elbowL", 
"elbowR", 
"eyeL", 
"eyeR", 
"fingerL1", 
"fingerL2", 
"fingerL3", 
"fingerR1", 
"fingerR2", 
"fingerR3", 
"handL", 
"handR", 
"head", 
"hipL", 
"hipR", 
"irisL", 
"irisR", 
"jaw", 
"jowlL",
"jowlR", 
"kneeL", 
"kneeR",
"knuckleL", 
"knuckleR", 
"neck", 
"nose", 
"shoulderL", 
"shoulderR", 
"snout",
"soleL", 
"soleR", 
"tail1", 
"tail2", 
"tail3", 
"tail4", 
"tail5", 
"tail6", 
"toeL1", 
"toeL2", 
"toeL3", 
"toeR1", 
"toeR2", 
"toeR3", 
"tongue1", 
"tongue2", 
"whiskerL1",
"whiskerL2", 
"whiskerL3", 
"whiskerR1",
"whiskerR2", 
"whiskerR3", 
"wristL", 
"wristR", 
"zorient",
"ztrans",
"mountalign",
"capturedtoy",
"digalign",
"fillhole",
"pillow",
"drop",
"util74",
"util75",
"util76",
"nose1",
"nose2",
"nose3",
"ear80",
"ear81",
"ear82",
"ear83",
"ear84",
"ear85",
"ear86",
"ear87",
"ear88",
"ear89",
"ear90",
"ear91"]

var colors = [
	"000000",
"800000",
"008000",
"808000",
"000080",
"800080",
"008080",
"C0C0C0",
"C8C8C8",
"F8D8D8",
"E7E2DD",
"E3DED8",
"DFDAD4",
"DBD6D0",
"D7D2CC",
"D3CEC7",
"CFCAC3",
"CBC6BF",
"C7C2BB",
"C3BEB6",
"757575",
"6F6F6F",
"6A6A6A",
"656565",
"606060",
"5B5B5B",
"565656",
"515151",
"4C4C4C",
"464646",
"424242",
"3A3A3A",
"333333",
"2C2C2C",
"242424",
"1D1D1D",
"161616",
"0E0E0E",
"070707",
"000000",
"DCC296",
"D5BB90",
"CFB58A",
"C8AF85",
"C2A97F",
"BBA27A",
"B59C74",
"AE966F",
"A89069",
"A28963",
"874122",
"7F3D20",
"77391E",
"70351C",
"68311A",
"612D18",
"592916",
"522514",
"4A2112",
"421D10",
"B47316",
"AF6D13",
"AA6811",
"A5630E",
"A15E0C",
"9C5809",
"975307",
"934E04",
"8E4902",
"894400",
"F09EB7",
"E999B2",
"E395AD",
"DD91A8",
"D68DA3",
"D0889E",
"CA8499",
"C38094",
"BD7C8F",
"B7778B",
"A82901",
"A42801",
"9F2701",
"9B2601",
"972501",
"922401",
"8E2301",
"8A2201",
"852101",
"812001",
"6B4A0C",
"65440B",
"603E0B",
"5B390B",
"56330B",
"512D0A",
"4C270A",
"47220A",
"421C0A",
"3C1609",
"A68A38",
"A28537",
"9E8137",
"9A7D37",
"967836",
"937436",
"8F7036",
"8B6B35",
"876735",
"846235",
"62707D",
"5D6976",
"586370",
"535D69",
"4E5763",
"49505D",
"444A56",
"3F4450",
"3A3E4A",
"363843",
"9A8E73",
"968A70",
"93876D",
"90846B",
"8C8168",
"897E66",
"867B63",
"827861",
"7F755E",
"7C715B",
"55AB57",
"3CA147",
"159917",
"358336",
"307B1C",
"107919",
"276217",
"2F5E2B",
"135C14",
"104111",
"2B61C3",
"3846E3",
"333BFF",
"3343CE",
"161AD7",
"2E3CB6",
"161CA9",
"2A4290",
"192277",
"111953",
"D8F0FF",
"ACE0FF",
"99D6FF",
"82CAFF",
"75B6E8",
"68C0FF",
"5196DC",
"189CCE",
"568BB9",
"1E89A9",
"EBEDA7",
"EAEB90",
"D1CC77",
"F7F400",
"EDE832",
"C3C40B",
"C3C334",
"9FA217",
"9F9F43",
"6E7A2E",
"FFFFFF",
"C0E4E7",
"ACC6D5",
"A7A7B1",
"A0A0A8",
"74A0B6",
"8399B1",
"8399B1",
"8098B0",
"8098B0",
"E2BEAC",
"D59390",
"D7766E",
"B87367",
"9F7773",
"A26A5D",
"896458",
"98574D",
"6A4542",
"5A3C31",
"729E8C",
"008080",
"427A75",
"008080",
"397860",
"3D5A63",
"265847",
"21412B",
"123930",
"FFFFFF",
"FFFFFF",
"F4F6D8",
"E9D8C2",
"2C5F59",
"D3F4C5",
"C4D39F",
"FFC71A",
"B0B89B",
"AFB177",
"A5948E",
"ACA98F",
"D7A014",
"C67F08",
"CA6E46",
"798E61",
"997E4D",
"808080",
"659B2A",
"00CB16",
"A76C39",
"FF4200",
"976442",
"99652A",
"DD346A",
"294475",
"5869B5",
"426B84",
"506480",
"75594A",
"99B4D1",
"BFCDDB",
"F0F0F0",
"FFFFFF",
"646464",
"000000",
"000000",
"000000",
"B4B4B4",
"F4F7FC",
"ABABAB",
"0078D7",
"FFFFFF",
"F0F0F0",
"0078D7",
"000000",
"FFFFFF",
"6D6D6D",
"000000",
"808080",
"FF0000",
"00FF00",
"FFFF00",
"0000FF",
"FF00FF",
"00FFFF",
"000000"
]
