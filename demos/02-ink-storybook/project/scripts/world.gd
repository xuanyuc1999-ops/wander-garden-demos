extends Node3D
const Art=preload("res://scripts/art.gd")
const Data=preload("res://scripts/data.gd")
var chunks: Array[Node3D]=[]
var gate_bodies: Array[StaticBody3D]=[]
var gate_visuals: Array[Node3D]=[]
var baskets: Array[Node3D]=[]
var signs: Array[Dictionary]=[]
var rng=RandomNumberGenerator.new()

func build_region(index: int) -> void:
	var root=Node3D.new()
	root.name=Data.REGIONS[index].id
	root.position=Data.center(index)
	add_child(root)
	var ground=Color(Data.REGIONS[index].ground)
	if index==2:
		ground=Color("#aaa894")
	var leaf=Color(Data.REGIONS[index].leaf)
	var accent=Color(Data.REGIONS[index].accent)
	rng.seed=441+index*19
	# Flat traversable footprint and collision remain independent of all visuals.
	Art.solid(root,Vector3(0,-0.35,0),Vector3(50,0.7,56))
	for z in [-28,28]:
		Art.solid(root,Vector3(-15,1,z),Vector3(20,3,0.5))
		Art.solid(root,Vector3(15,1,z),Vector3(20,3,0.5))
	if index==0:
		Art.solid(root,Vector3(0,1,28),Vector3(10,3,0.5))
	if index==4:
		Art.solid(root,Vector3(0,1,-28),Vector3(10,3,0.5))
	var decor=Node3D.new()
	decor.name="ColorAndVolumeProbe"
	root.add_child(decor)
	chunks.append(decor)
	Art.box(decor,Vector3(0,-0.4,0),Vector3(50,0.8,56),ground)
	# Broad edges, layered distant volumes, a continuous readable walking ribbon.
	for j in range(2):
		for side in [-1,1]:
			var p=Vector3(side*21,0.15,-27+j*54)
			Art.ball(decor,p,Vector3(8,2.7,4),ground.darkened(rng.randf_range(0.02,0.12)))
			Art.solid(root,p+Vector3(0,0.5,0),Vector3(6,1.6,3))
	for j in range(19):
		var z=-27+j*3.0
		var x=sin(z*0.12)*0.5
		var path_color=ground.lerp(accent,0.48)
		if index==2:
			path_color=Color("#8caaa9")
		var stone=Art.cylinder(decor,Vector3(x,0.015,z),2.0,2.0,0.03,path_color)
		stone.scale.z=1.1
		for side in [-1,1]:
			if j%3==0:
				Art.ball(decor,Vector3(side*2.1,0.16,z),Vector3(0.17,0.20,0.17),accent,0.6)
	for x in range(-24,25,3):
		Art.cylinder(decor,Vector3(x,0.016,-10),1.3,1.3,0.025,ground.lerp(accent,0.25))
	# Shallow visual pond outside interaction land; collision floor remains safe.
	var water=Art.cylinder(decor,Vector3(13,0.023,5),6.0,6.0,0.025,Color("#99c8c5") if index!=4 else Color("#69799b"))
	water.scale.z=1.7 if index==2 else 1.0
	for j in range(18):
		var a=j*TAU/18
		Art.ball(decor,Vector3(13+cos(a)*6.2,0.1,5+sin(a)*(10.3 if index==2 else 6.2)),Vector3(1.3,0.45,0.9),ground.darkened(0.18) if index==2 else ground.lightened(0.10))
	# Solid stems occupy a clear peripheral band, never the farm or connector.
	for j in range(24 if index!=2 else 8):
		var side=-1 if j%2==0 else 1
		var p=Vector3(side*rng.randf_range(16,23),0,rng.randf_range(-25,25))
		if absf(p.z+10)<3.2:
			continue
		if index==0 and p.x> -19 and p.x< -6 and p.z>4 and p.z<18:
			continue
		if p.x>0 and absf(p.z-5)<12:
			continue
		Art.tree(decor,p,leaf.lightened(rng.randf_range(-0.07,0.12)),rng.randf_range(0.8,1.4),1 if index==1 else index)
		Art.solid(root,p+Vector3(0,1.3,0),Vector3(0.65,2.6,0.65))
	for j in range(45):
		var p=Vector3(rng.randf_range(-24,24),0,rng.randf_range(-26,26))
		if absf(p.x)<3 or (p.x>6 and p.x<20 and absf(p.z-5)<11):
			continue
		if j%4==0:
			Art.ball(decor,p+Vector3(0,0.18,0),Vector3(1.1,0.55,0.9),ground.lerp(Color("#adae9c"),0.45))
		elif index==1:
			Art.mushroom(decor,p,Color("#cfbfa0"),rng.randf_range(0.7,1.3))
		else:
			Art.flower(decor,p,accent.lerp(Color("#e9c2b8"),rng.randf()*0.45),rng.randf_range(0.7,1.3),0.7 if index==4 else 0)
	# Original hut volume defines a home landmark in the lead meadow.
	if index==0:
		var hut=Node3D.new()
		hut.position=Vector3(-12,0,11)
		decor.add_child(hut)
		Art.box(hut,Vector3(0,1.5,0),Vector3(4.5,3,3.8),Color("#d8c5a2"))
		var roof=Art.cylinder(hut,Vector3(0,3.7,0),3.5,0,2.0,Color("#7c9c85"))
		roof.rotation.y=PI/4
		Art.box(hut,Vector3(0,1,-1.94),Vector3(1.1,2.0,0.12),Color("#7c715b"))
		for x in [-1.35,1.35]:
			Art.box(hut,Vector3(x,1.7,-1.97),Vector3(0.65,0.8,0.1),Color("#e9dba7"))
		Art.solid(root,Vector3(-12,1.5,11),Vector3(4.5,3,3.8))
		for x in [-15,-9]:
			Art.tree(decor,Vector3(x,0,15),leaf.lightened(0.1),1.2,0)
		for j in range(6):
			var x=-16+j*1.55
			Art.cylinder(decor,Vector3(x,0.6,6.5),0.09,0.08,1.2,Color("#d8c5a2"))
		Art.box(decor,Vector3(-12,0.75,6.5),Vector3(8,0.10,0.10),Color("#d8c5a2"))
	# Renewable local seeds are separate from decorative flowers.
	var basket=Node3D.new()
	basket.position=Vector3(-4,0,4)
	root.add_child(basket)
	baskets.append(basket)
	Art.cylinder(basket,Vector3(0,0.3,0),0.45,0.57,0.6,Color("#b99870"))
	for j in range(5):
		Art.ball(basket,Vector3(rng.randf_range(-0.3,0.3),0.65,rng.randf_range(-0.25,0.25)),Vector3(0.20,0.13,0.20),accent)
	label(basket,"种子篮",Vector3(0,1.2,0),accent)
	for j in range(2):
		var p=Vector3(3.5 if j==0 else -4.5,0,15.0 if j==0 else -18.0)
		var sign=Node3D.new()
		sign.position=p
		root.add_child(sign)
		Art.cylinder(sign,Vector3(0,0.5,0),0.08,0.06,1,Color("#a29477"))
		Art.box(sign,Vector3(0,1.05,0),Vector3(1.05,0.55,0.13),Color("#d7cfac"))
		signs.append({"node":sign,"region":index,"text":Data.REGIONS[index].signs[j],"id":index*2+j})
	if index==4:
		# A visible resting place terminates the walk before the world's collision.
		Art.cylinder(decor,Vector3(0,0.04,-23),4.5,4.5,0.08,Color("#68718e"))
		Art.cylinder(decor,Vector3(0,0.35,-24.5),1.0,0.8,0.7,Color("#8992a8"))
		Art.solid(root,Vector3(0,0.45,-24.5),Vector3(1.7,0.9,1.7))
		Art.ball(decor,Vector3(0,1.3,-24.5),Vector3(1.1,1.4,1.1),Color("#a8d3d9"),0.35)
		for j in range(7):
			Art.ball(decor,Vector3(-9+j*3,0.65,-27),Vector3(3.1,1.5,2),Color("#626f86"))
		label(decor,"在这里，看一会儿星星",Vector3(0,3.3,-24.5),accent)
		for j in range(65):
			var pos=Vector3(rng.randf_range(-24,24),rng.randf_range(0.8,4.0) if j<45 else rng.randf_range(6,24),rng.randf_range(-27,27))
			Art.ball(decor,pos,Vector3.ONE*rng.randf_range(0.04,0.11),accent,1)

func build_connector(index: int) -> void:
	var n=Node3D.new()
	n.position=Data.gate_pos(index)
	add_child(n)
	var accent=Color(Data.REGIONS[index+1].accent)
	Art.solid(n,Vector3(0,-0.22,0),Vector3(10,0.44,16))
	Art.box(n,Vector3(0,-0.22,0),Vector3(10,0.44,16),Color("#a49f88"))
	for side in [-1,1]:
		Art.solid(n,Vector3(side*5,1,0),Vector3(0.35,2.7,16))
		for j in range(9):
			Art.cylinder(n,Vector3(side*4.8,0.6,-8+j*2),0.13,0.10,1.2,Color("#aca48b"))
			if j%2==0:
				Art.ball(n,Vector3(side*4.8,1.25,-8+j*2),Vector3.ONE*0.20,accent,1)
		Art.box(n,Vector3(side*4.8,0.9,0),Vector3(0.15,0.15,16),Color("#c9c0a3"))
	for j in range(17):
		Art.box(n,Vector3(0,0.012,-8+j),Vector3(9.5,0.025,0.045),Color("#c9bea0"))
	var frame=Node3D.new()
	n.add_child(frame)
	for side in [-1,1]:
		Art.cylinder(frame,Vector3(side*3.8,2.1,0),0.6,0.45,4.2,Color("#aaa99a"))
		Art.ball(frame,Vector3(side*3.6,4.15,0),Vector3(1.6,1.2,1.6),accent.darkened(0.15))
	Art.box(frame,Vector3(0,4.5,0),Vector3(7.2,0.7,1.0),Color("#b9b6a5"))
	var lockvisual=Node3D.new()
	n.add_child(lockvisual)
	for j in range(13):
		Art.cylinder(lockvisual,Vector3(-3.6+j*0.6,1.45,0),0.018,0.018,2.9,accent,0.6)
	gate_visuals.append(lockvisual)
	gate_bodies.append(Art.solid(n,Vector3(0,1.5,0),Vector3(9.8,3,0.5)))
	label(n,Data.REGIONS[index+1].name,Vector3(0,5.4,0),accent)

func label(parent: Node3D,text: String,pos: Vector3,color: Color) -> void:
	var l=Label3D.new()
	l.text=text
	l.position=pos
	l.font=load("res://assets/fonts/NotoSansCJKsc-Regular.otf")
	l.font_size=36
	l.pixel_size=0.012
	l.modulate=color
	l.outline_modulate=Color("#414c43")
	l.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(l)

func open_gate(index: int) -> void:
	gate_bodies[index].collision_layer=0
	gate_visuals[index].visible=false

func update_visibility(pos: Vector3) -> void:
	for i in range(chunks.size()):
		chunks[i].visible=absf(pos.z+72*i)<115
