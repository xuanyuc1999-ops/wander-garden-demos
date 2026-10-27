extends Node3D
const Models=preload("res://art/runtime/model_visuals.gd")
const Art=preload("res://scripts/art.gd")
const Data=preload("res://scripts/data.gd")
const TREES=["meadow-tree","forest-tree","salt-rock","maple-tree","moon-tree"]
const FLORA=["grass-flower","forest-flora","salt-reeds","autumn-bush","star-flower"]
const CROPS=["carrot","forest-flora","crystal-flower","pear-crop","star-flower"]
const PETS=["rabbit","fox","otter","squirrel","firefly-beast"]
var game: Node
var sky_material: ShaderMaterial
var pet_motion=[]
var asset_counts={}
var lakes=[]
var installed=false

func available(id: String) -> bool:return ResourceLoader.exists(Models.resource_path(id))
func spawn(parent: Node3D,id: String,height: float,pos: Vector3=Vector3.ZERO,angle: float=0.0) -> Node3D:
	if not available(id):return null
	var model=Models.spawn(parent,id,height,angle)
	model.position=pos
	if id=="autumn-bush":
		recolor_foliage(model,Color("#ed8246"))
	asset_counts[id]=asset_counts.get(id,0)+1
	return model

func _ready() -> void:
	for index in range(1,5):install_region(index)
	for index in range(1,4):install_connector(index)
	var old=game.streamer
	game.remove_child(old)
	game.streamer=preload("res://art/runtime/biome_streamer.gd").new()
	game.streamer.game=game
	game.streamer.world_seed=old.world_seed
	game.streamer.collected=old.collected.duplicate()
	game.add_child(game.streamer)
	old.queue_free()
	sky_material=ShaderMaterial.new()
	sky_material.shader=preload("res://art/runtime/world_sky.gdshader")
	game.meadow_sky.sky_material=sky_material
	installed=true
	print("FIVE_BIOME_ART_INSTALLED ",asset_counts)

func install_region(index: int) -> void:
	var decor=game.world.chunks[index]
	var tree_points=[]
	var flora_points=[]
	var rock_points=[]
	for node in decor.get_children():
		if not node is Node3D:continue
		if node is MeshInstance3D:
			if node.mesh is BoxMesh and node.mesh.size.x>40:node.visible=false
			elif node.mesh is CylinderMesh and node.position.y<.1:node.visible=false
			elif node.mesh is SphereMesh and node.position.y<.7:
				rock_points.append({"pos":node.position,"size":node.scale})
				node.visible=false
		elif node.get_child_count()>0:
			var first=node.get_child(0)
			if first is MeshInstance3D and first.mesh is CylinderMesh:
				if absf(first.position.y-1.8)<.01:
					tree_points.append({"pos":node.position,"scale":node.scale.x})
					node.visible=false
				elif first.position.y<.3:
					flora_points.append(node.position)
					node.visible=false
	var ground=MeshInstance3D.new()
	ground.name=Data.REGIONS[index].id.capitalize()+"LayeredGround"
	var plane=PlaneMesh.new();plane.size=Vector2(50,56)
	ground.mesh=plane
	ground.layers=1<<6
	var material=ShaderMaterial.new()
	material.shader=preload("res://art/runtime/biome_surface.gdshader")
	material.set_shader_parameter("region_center",Vector2(0,-72*index))
	material.set_shader_parameter("biome",index)
	var palette=[
		["#91ae76","#bed294","#c6b585"],
		["#547d63","#89a276","#aaa17b"],
		["#939b93","#bdc4b1","#c1b89c"],
		["#ac895b","#cbb17b","#d7b37c"],
		["#3f4961","#61706f","#9295a5"]][index]
	material.set_shader_parameter("soil_dark",Color(palette[0]))
	material.set_shader_parameter("soil_light",Color(palette[1]))
	material.set_shader_parameter("path_tint",Color(palette[2]))
	ground.material_override=material
	decor.add_child(ground)
	if index in [3,4]:
		ground.visible=false
		preload("res://art/runtime/meshy_ground.gd").install(decor,index)
	for point in tree_points:
		spawn(decor,TREES[index],(2.5 if index==2 else 5.4)*point.scale,point.pos)
	if index!=2:
		for side in [-1,1]:
			for n in range(5):
				var pos=Vector3(side*(9.5+float(n%2)*1.8),0,-23+n*10)
				if side>0 and absf(pos.z-5)<12:continue
				spawn(decor,TREES[index],6.3+float(n%3)*.65,pos,n*1.3)
				Art.solid(game.world.chunks[index].get_parent(),pos+Vector3(0,1,0),Vector3(.6,2,.6))
	for n in range(flora_points.size()):
		var model=spawn(decor,FLORA[index],.55+float(n%3)*.15,flora_points[n],n*2.31)
		if model and index==4:emissive(model,.5)
	var rock_id="moss-rock" if index==1 else "salt-rock" if index==2 else "rock-cluster"
	for n in range(rock_points.size()):
		var point=rock_points[n]
		var height=maxf(.45,point.size.y)
		var model=spawn(decor,rock_id,height,Vector3(point.pos.x,-.03,point.pos.z),n*.73)
		if model and index==4:tint(model,Color("#7b88ac"),.22)
	var lake=preload("res://art/runtime/lake_v04.gd").new()
	lake.game=game
	lake.region_index=index
	lake.stretch=Vector2(1,1.7 if index==2 else 1)
	lake.shallow_tint=Color("#68b7b9") if index==2 else Color("#556889") if index==4 else Color("#526e5e")
	lake.deep_tint=Color("#318ba6") if index==2 else Color("#202f62") if index==4 else Color("#244953")
	lake.shore_tint=Color(palette[1])
	if index==4:
		lake.model_path="res://art/assets/runtime/star-lowpoly-lake-v091.glb"
		lake.water_shader_path="res://art/runtime/star_water_v091.gdshader"
		lake.shore_shader_path="res://art/runtime/star_shore_v09.gdshader"
		lake.shallow_tint=Color("#569da6")
		lake.deep_tint=Color("#355b80")
	decor.add_child(lake)
	lakes.append(lake)
	for sign in game.world.signs:
		if sign.region==index:
			Models.hide_old_meshes(sign.node)
			spawn(sign.node,"signpost",1.45)
	Models.hide_old_meshes(game.world.baskets[index])
	spawn(game.world.baskets[index],"basket",.72,Vector3.ZERO,PI)
	var pet=game.pets[index]
	if available(PETS[index]):
		Models.hide_old_meshes(pet.visual)
		var model=spawn(pet.visual,PETS[index],[.9,.75,.65,.72,.5][index],Vector3.ZERO,PI)
		var adapter=preload("res://art/runtime/biome_pet_motion.gd").new()
		adapter.setup(pet,model,index)
		pet_motion.append(adapter)
		if index==4:emissive(model,.55)
	if index==4:
		for node in decor.get_children():
			if node is MeshInstance3D and node.position.distance_to(Vector3(0,1.3,-24.5))<.1:node.visible=false
		var shrine=spawn(decor,"moon-shrine",3.2,Vector3(0,0,-24.5))
		if shrine:emissive(shrine,.35)
	# Keep the exact traversable core and deterministic protection masks.
	for n in range(40):
		var side=-1 if n%2==0 else 1
		var z=-25+float(n/2)*2.5
		if absf(z+10)<2.5:continue
		var x=side*(3.4+float(n%3)*.42)
		spawn(decor,FLORA[index],.25+float(n%4)*.065,Vector3(x,0,z),n*1.71)
	var random=RandomNumberGenerator.new()
	random.seed=4821+index*379
	for n in range(80):
		var x=random.randf_range(-20,20)
		var z=random.randf_range(-25,25)
		if absf(x)<3.2 or absf(z+10)<1.2 or (x>6 and x<20 and absf(z-5)<12):continue
		if Vector2(x+4,z+3).length()<3 or Vector2(x-4,z).length()<2.5:continue
		spawn(decor,FLORA[index],random.randf_range(.25,.55),Vector3(x,0,z),random.randf()*TAU)

func install_connector(index: int) -> void:
	var root=game.world.gate_bodies[index].get_parent()
	for node in root.get_children():
		if node is Node3D and not node is MeshInstance3D and not node is StaticBody3D and not node is Label3D and node!=game.world.gate_visuals[index]:
			node.visible=false
		if node is MeshInstance3D and node.mesh is BoxMesh and node.position.y<0:
			node.material_override=Art.mat(Color("#ad9c79") if index==2 else Color("#869888") if index==1 else Color("#838ca4"))
	var arch=spawn(root,"stone-arch",4.95)
	if arch:
		tint(arch,Color("#749176") if index==1 else Color("#cdb380") if index==2 else Color("#8393be"),.32)
		if index==3:emissive(arch,.12)
	for side in [-1,1]:
		for n in range(6):
			var id="moss-rock" if index==1 else "autumn-bush" if index==2 else "star-flower"
			spawn(root,id,1.0 if index==1 else .65,Vector3(side*4.4,0,-6+n*2.4))

func tint(model: Node,color: Color,amount: float) -> void:
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var original=mesh.get_active_material(surface)
			if original is StandardMaterial3D:
				var material=original.duplicate()
				material.albedo_color=Color.WHITE.lerp(color,amount)
				mesh.set_surface_override_material(surface,material)

func recolor_foliage(model: Node,color: Color) -> void:
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var original=mesh.get_active_material(surface)
			if original is StandardMaterial3D and original.albedo_texture:
				var material=ShaderMaterial.new()
				material.shader=preload("res://art/runtime/foliage_palette.gdshader")
				material.set_shader_parameter("base_texture",original.albedo_texture)
				material.set_shader_parameter("base_tint",original.albedo_color)
				material.set_shader_parameter("foliage_color",color)
				mesh.set_surface_override_material(surface,material)

func emissive(model: Node,strength: float) -> void:
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var original=mesh.get_active_material(surface)
			if original is StandardMaterial3D:
				var material=original.duplicate()
				material.emission_enabled=true
				material.emission=Color("#a1b7ce")
				material.emission_texture=material.albedo_texture
				material.emission_energy_multiplier=strength
				mesh.set_surface_override_material(surface,material)

func update(delta: float) -> void:
	if not installed:return
	for adapter in pet_motion:adapter.update(delta,game.paused)
	var coordinate=clampf(-game.player.position.z/72.,0,4)
	var lo=int(floor(coordinate))
	var hi=mini(lo+1,4)
	var blend=smoothstep(.33,.67,coordinate-lo)
	var zeniths=["#a6c9d9","#819f9b","#9bcedf","#b8c5d6","#172443"]
	var horizons=["#dce5d3","#b7cbb6","#b6d9e4","#ead3b1","#555b7d"]
	var ridges=["#7a9f82","#456a60","#9eafae","#a18b71","#333e62"]
	sky_material.set_shader_parameter("zenith",Color(zeniths[lo]).lerp(Color(zeniths[hi]),blend))
	sky_material.set_shader_parameter("horizon",Color(horizons[lo]).lerp(Color(horizons[hi]),blend))
	sky_material.set_shader_parameter("ridge_color",Color(ridges[lo]).lerp(Color(ridges[hi]),blend))
	var star=clampf((coordinate-3.3)/.4,0,1)
	sky_material.set_shader_parameter("stars",star)
	sky_material.set_shader_parameter("daylight",lerpf(1-clampf((sin(game.clock*TAU-PI/2)+.1)*.55,0,.55)*.65,1,star))
	game.env.background_mode=Environment.BG_SKY
	game.env.sky=game.meadow_sky
	game.env.fog_sky_affect=.4
	var night=clampf((sin(game.clock*TAU-PI/2)+.1)*.55,0,.55)
	game.sunlight.light_energy=lerpf(.42-night*.2,.22,star)
	game.env.ambient_light_energy=lerpf(.45-night*.12,.36,star)
	var central=1.-smoothstep(3.,8.,absf(game.player.position.x))
	var north=pow(maxf(0,(-game.player.pivot.global_basis.z).dot(Vector3.FORWARD)),4)*central
	var end=lerpf(game.streamer.fog_limit(game.player.camera),70.,north)
	game.env.fog_depth_end=end
	game.env.fog_depth_begin=lerpf(end*.48,42.,north)
	game.env.fog_light_color=Color(horizons[lo]).lerp(Color(horizons[hi]),blend).lerp(Color(ridges[lo]).lerp(Color(ridges[hi]),blend),.5)
	if game.region==1:game.sunlight.light_energy*=.85

func update_crops() -> void:
	for plot in game.plots:
		if plot.crop<1 or not available(CROPS[plot.crop]):continue
		var state=str(plot.crop)+":"+str(plot.stage)
		if plot.get_meta("biome_art_state","")==state:continue
		plot.set_meta("biome_art_state",state)
		var previous=plot.get_node_or_null("BiomeCrop")
		if previous:previous.free()
		plot.plants.visible=false
		var root=Node3D.new();root.name="BiomeCrop";plot.add_child(root)
		for x in [-.32,.32]:
			for z in [-.32,.32]:
				var model=spawn(root,CROPS[plot.crop],[.08,.18,.32,.48][clampi(plot.stage,0,3)],Vector3(x,.04,z))
				if plot.crop==4 and model:emissive(model,.7)
	for plot in game.plots:
		if plot.crop<1:
			var previous=plot.get_node_or_null("BiomeCrop")
			if previous:previous.free()
			plot.remove_meta("biome_art_state")
