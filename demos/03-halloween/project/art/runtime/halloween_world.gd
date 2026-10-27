extends Node3D
const Models=preload("res://art/runtime/model_visuals.gd")
const Art=preload("res://scripts/art.gd")
var game: Node
var ghosts=[]
var decorations=[]
var lamps=[]
var bats=[]
var elapsed=0.0
var refresh=0.0
var prop_counts={}
const ORANGE=Color("#ffad42")
const MINT=Color("#9af0d2")
const PURPLE=Color("#794aa9")

func place(id: String,height: float,pos: Vector3,angle: float=0.0) -> Node3D:
	var node=Models.spawn(self,id,height,angle)
	node.position=pos
	node.set_meta("halloween_prop",true)
	decorations.append(node)
	prop_counts[id]=prop_counts.get(id,0)+1
	return node

func lantern(pos: Vector3,height: float,region: int,light: bool=false) -> void:
	var node=place("hw-pumpkin",height,pos,sin(pos.z)*.2)
	if light:
		var lamp=OmniLight3D.new()
		lamp.light_color=ORANGE
		lamp.light_energy=.8
		lamp.omni_range=5.0
		lamp.shadow_enabled=false
		lamp.position=Vector3(0,height*.6,0)
		node.add_child(lamp)
		lamps.append({"node":lamp,"region":region})

func triangle(points: PackedVector3Array,color: Color,parent: Node3D) -> MeshInstance3D:
	var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=points
	var normals=PackedVector3Array()
	for p in points:normals.append(Vector3.FORWARD)
	arrays[Mesh.ARRAY_NORMAL]=normals
	var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var node=MeshInstance3D.new();node.mesh=mesh
	var material=Art.mat(color).duplicate()
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	node.material_override=material;parent.add_child(node)
	return node

func garland(z: float) -> void:
	for side in [-1,1]:
		Art.cylinder(self,Vector3(side*5.6,1.9,z),.09,.11,3.8,Color("#563c68"))
		Art.ball(self,Vector3(side*5.6,3.84,z),Vector3(.17,.17,.17),ORANGE,.2)
	var colors=[ORANGE,PURPLE,MINT]
	for n in range(18):
		var x=-5.4+n*.6
		var y=3.7-.65*(1-pow(x/5.4,2))
		triangle(PackedVector3Array([Vector3(x,y,z),Vector3(x+.5,y,z),Vector3(x+.25,y-.52,z)]),colors[n%3],self)
		var string_mesh=Art.cylinder(self,Vector3(x+.3,y+.03,z),.018,.018,.65,Color("#d9b884"))
		string_mesh.rotation.z=PI/2

func bat(pos: Vector3,index: int) -> void:
	var root=Node3D.new();root.position=pos;add_child(root)
	var body=Art.ball(root,Vector3.ZERO,Vector3(.12,.2,.11),Color("#48345e"))
	var wings=[]
	for side in [-1,1]:
		var wing=triangle(PackedVector3Array([Vector3(0,0,0),Vector3(side*.62,.23,0),Vector3(side*.43,-.12,0),
			Vector3(0,0,0),Vector3(side*.43,-.12,0),Vector3(side*.22,-.20,0)]),Color("#59416f"),root)
		wings.append(wing)
	bats.append({"node":root,"wings":wings,"base":pos,"phase":index*.9})

func _ready() -> void:
	name="HalloweenDecor"
	for i in range(5):
		var center=game.data.center(i)
		for side in [-1,1]:
			for n in range(4):
				var pos=center+Vector3(side*(4.0+float(n%2)*.5),0,-20+n*12)
				lantern(pos,.63+float(n%3)*.16,i,n in [0,2])
		# Small vignettes outside pet points, starting beds, main road and shoreline.
		var corner=center+Vector3(-8.0,0,7.0)
		place("hw-cauldron",1.22,corner,PI*.8)
		place("hw-candy",.92,corner+Vector3(1.6,0,-1.1))
		place("hw-candy",.85,center+Vector3(-7,0,-17),.2)
		for n in range(2):
			var pos=center+Vector3(-7.5-n*2.6,1.35,1-n*13)
			var ghost=place("hw-ghost",.92,pos)
			ghosts.append({"node":ghost,"base":pos,"phase":i+n*.8})
		garland(center.z-20)
		for n in range(3):bat(center+Vector3(-6+n*3,4.1,-15-n*2),i*3+n)
	# A welcoming focal cluster next to the original cottage, with a clear path.
	lantern(Vector3(-10.5,0,-14.3),1.45,0,true)
	lantern(Vector3(-12.5,0,-13.8),.9,0)
	# The cottage wears a removable witch-hat roof; its collider is unchanged.
	var roof=Node3D.new()
	roof.position=game.cottage.global_position+Vector3(0,3.55,0)
	add_child(roof)
	Art.cylinder(roof,Vector3.ZERO,2.45,2.45,.16,Color("#49315f"))
	Art.cylinder(roof,Vector3(0,.92,0),1.65,.10,1.85,Color("#65427e"))
	Art.cylinder(roof,Vector3(0,.18,0),1.62,1.48,.25,ORANGE)
	var tip=Art.cylinder(roof,Vector3(.25,1.97,0),.28,.01,.85,Color("#65427e"))
	tip.rotation.z=-.7
	for i in range(4):
		var pos=game.data.gate_pos(i)
		lantern(pos+Vector3(-3.0,0,1.1),.9,i,true)
		lantern(pos+Vector3(3.0,0,1.1),.9,i)
	for label in game.hud.start_screen.find_children("*","Label",true,false):
		if "墨线童话" in label.text:label.text="南瓜月夜 · 和小骷髅一起散步"
	preload("res://art/runtime/ink_style.gd").apply_node(self)
	if game.lake_visual:
		game.lake_visual.shallow_tint=Color("#ab93bf")
		game.lake_visual.deep_tint=Color("#594675")
		game.lake_visual.material.set_shader_parameter("shallow_tint",game.lake_visual.shallow_tint)
		game.lake_visual.material.set_shader_parameter("deep_tint",game.lake_visual.deep_tint)
	print("HALLOWEEN_READY ",prop_counts)

func update(delta: float) -> void:
	if not game.paused:elapsed+=delta
	for row in ghosts:
		row.node.position=row.base+Vector3(0,sin(elapsed*1.3+row.phase)*.15,0)
		row.node.rotation.y=sin(elapsed*.6+row.phase)*.2
	for row in bats:
		row.node.position=row.base+Vector3(sin(elapsed*.5+row.phase)*.4,sin(elapsed*1.1+row.phase)*.1,0)
		for j in range(2):row.wings[j].rotation.y=sin(elapsed*3.8+row.phase)*.3*(-1 if j==0 else 1)
	for row in lamps:row.node.visible=absi(game.region-row.region)<=1
	refresh+=delta
	if refresh>.7:
		refresh=0
		for node in decorations:
			var clear=true
			for plot in game.plots:
				if Vector2(node.global_position.x-plot.global_position.x,node.global_position.z-plot.global_position.z).length()<1.35:
					clear=false;break
			node.visible=clear
