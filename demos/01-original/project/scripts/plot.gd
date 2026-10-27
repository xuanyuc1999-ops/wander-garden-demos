extends Node3D
const Art = preload("res://scripts/art.gd")
const Data = preload("res://scripts/data.gd")
var crop = -1
var growth = 0.0
var water = 0.0
var stage = -2
var loosened = false
var plants: Node3D
var soil: MeshInstance3D
var game: Node

func _ready() -> void:
	soil = Art.cylinder(self,Vector3(0,0.025,0),0.85,0.85,0.05,Color("#8d7158"))
	for i in range(4):
		Art.box(self,Vector3(-0.52+i*0.35,0.06,0),Vector3(0.055,0.025,1.15),Color("#a18667"))
	plants = Node3D.new()
	add_child(plants)
	refresh()

func _process(delta: float) -> void:
	if crop >= 0 and growth < 1.0 and water > 0.0 and not game.paused:
		growth = minf(1.0,growth+delta/Data.GROW_SECONDS[game.speed_index]*(1.2 if loosened else 1.0))
		water = maxf(0.0,water-delta/100.0)
		refresh()

func refresh() -> void:
	var current = -1 if crop < 0 else mini(3,int(growth*4))
	soil.material_override = Art.mat(Color("#705746") if water>0 else Color("#97795c"))
	if current == stage:
		return
	stage = current
	for child in plants.get_children():
		child.free()
	if crop < 0:
		return
	var s = [0.13,0.35,0.65,1.0][stage]
	for x in [-0.37,0.37]:
		for z in [-0.35,0.35]:
			var p = Vector3(x,0.06,z)
			if crop==1:
				Art.mushroom(plants,p,Color("#cdb59b"),s)
			elif crop==0:
				Art.cylinder(plants,p+Vector3(0,0.15*s,0),0.05*s,0.14*s,0.27*s,Color("#e8a065"))
				for j in range(3):
					var leaf = Art.ball(plants,p+Vector3((j-1)*0.08*s,0.32*s,0),Vector3(0.12,0.43,0.12)*s,Color("#84ad72"))
					leaf.rotation.z = (j-1)*0.4
			elif crop==3:
				Art.cylinder(plants,p+Vector3(0,0.3*s,0),0.04,0.025,0.6*s,Color("#7d8e5d"))
				Art.ball(plants,p+Vector3(0,0.6*s,0),Vector3(0.40,0.48,0.4)*s,Color("#e7c36e"))
			else:
				Art.flower(plants,p,Color("#b8e8e8") if crop==2 else Color("#b8b0ed"),s*1.25,0.65 if crop==4 else 0)

func prompt() -> String:
	if crop<0:
		return "E  播种 · " + Data.REGIONS[game.selected_seed].crop
	if growth>=1:
		return "E  收获 · " + Data.REGIONS[crop].crop
	if water<=0:
		return "E  浇水 · 生长暂停，种子在安心等你"
	return "%s  %d%%  ·  L 松土" % [Data.REGIONS[crop].crop,int(growth*100)]

func interact() -> void:
	if crop<0:
		if game.seeds[game.selected_seed]<=0:
			game.toast("种子篮里总会留着一些种子。")
			return
		crop = game.selected_seed
		game.seeds[crop]-=1
		game.event("sow",{"crop":crop})
		game.toast("种子已经安家。再按 E 浇一点水。")
	elif growth>=1:
		game.harvest[crop]+=3
		game.seeds[crop]+=2
		game.discovered_crops[crop]=true
		game.event("harvest",{"crop":crop,"count":3})
		game.toast(Data.REGIONS[crop].crop+" +3 · 种子 +2")
		crop=-1
		growth=0
		water=0
		loosened=false
	elif water<=0:
		water=1
		game.event("water",{"crop":crop})
		game.toast("浇好了。可以散散步，也可以陪它长大。")
	else:
		game.toast("它正慢慢长大，不用再浇水。")
	refresh()
	game.chime()

func record() -> Dictionary:
	return {"x":position.x,"y":position.y,"z":position.z,"crop":crop,"growth":growth,"water":water,"loosened":loosened}
