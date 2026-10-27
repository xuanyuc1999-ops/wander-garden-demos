extends Node3D
# Stable terrain and resource identities, disposable detail meshes.
# Hand-authored core geometry/collisions and save-state nodes never belong to chunks.
const Data=preload("res://scripts/data.gd")
const SIZE=32.0
const RADIUS=1
const FRAME_BUDGET_US=1800
var game: Node
var world_seed=348802
var chunks: Dictionary={}
var jobs: Array=[]
var wanted: Dictionary={}
var current_cell=Vector2i(99999,99999)
var noise=FastNoiseLite.new()
var families: Dictionary={}
var materials: Dictionary={}
var pickup_nodes: Dictionary={}
var collected: Dictionary={}
var generated_count=0
var unloaded_count=0
var peak_chunks=0
var peak_work_us=0
var visit_palette=0
var wind_shader=preload("res://assets/meadow_wind.gdshader")

func _ready() -> void:
	noise.seed=world_seed
	noise.frequency=0.035
	noise.fractal_octaves=2
	make_families()
	visit_palette=int(Time.get_unix_time_from_system())%7

func biome(pos: Vector3) -> int:
	if pos.z>28 or pos.z< -316:
		return -1
	var i=Data.region_at(pos)
	if absf(pos.z+72*i)>28:
		return -1
	return i

func height_at(pos: Vector3) -> float:
	var blend=smoothstep(25.0,42.0,absf(pos.x))
	var terrain=noise.get_noise_2d(pos.x,pos.z)*1.4
	return terrain*blend-0.035

func cell_at(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x/SIZE),floori(pos.z/SIZE))

func has_surface(pos: Vector3) -> bool:
	if absf(pos.x)<25:
		return true
	var key=cell_at(pos)
	return chunks.has(key) and chunks[key].get_meta("terrain_ready",false)

func _process(_delta: float) -> void:
	if not is_instance_valid(game.player):
		return
	var cell=cell_at(game.player.position)
	if cell!=current_cell:
		request_neighborhood(cell)
	var start=Time.get_ticks_usec()
	while not jobs.is_empty() and Time.get_ticks_usec()-start<FRAME_BUDGET_US:
		var job: Dictionary=jobs[0]
		if not wanted.has(job.cell) or not is_instance_valid(job.node):
			jobs.pop_front()
			continue
		match int(job.phase):
			0: build_terrain(job)
			1: scatter(job,0,180)
			2: scatter(job,180,360)
			3: assemble(job)
		job.phase+=1
		if job.phase>3:
			jobs.pop_front()
			generated_count+=1
	peak_work_us=maxi(peak_work_us,Time.get_ticks_usec()-start)
	for key in pickup_nodes:
		var entry: Dictionary=pickup_nodes[key]
		if is_instance_valid(entry.node):
			entry.node.visible=game.elapsed-float(collected.get(key,-100000.0))>=90

func request_neighborhood(cell: Vector2i) -> void:
	current_cell=cell
	wanted.clear()
	var ordered: Array[Vector2i]=[]
	for x in range(-RADIUS,RADIUS+1):
		for z in range(-RADIUS,RADIUS+1):
			var key=cell+Vector2i(x,z)
			wanted[key]=true
			ordered.append(key)
	for key in chunks.keys():
		if not wanted.has(key):
			chunks[key].queue_free()
			chunks.erase(key)
			unloaded_count+=1
	for key in pickup_nodes.keys():
		if not wanted.has(pickup_nodes[key].cell):
			pickup_nodes.erase(key)
	ordered.sort_custom(func(a,b): return a.distance_squared_to(cell)<b.distance_squared_to(cell))
	for key in ordered:
		if chunks.has(key):
			continue
		var root=Node3D.new()
		root.name="Chunk_%s_%s"%[key.x,key.y]
		root.position=Vector3(key.x*SIZE,0,key.y*SIZE)
		add_child(root)
		chunks[key]=root
		jobs.append({"cell":key,"node":root,"phase":0,"batches":{},"resource":null})
	peak_chunks=maxi(peak_chunks,chunks.size())

func build_terrain(job: Dictionary) -> void:
	var root: Node3D=job.node
	var tool=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tri_count=0
	for x in range(8):
		for z in range(8):
			var corner=root.position+Vector3(x*4,0,z*4)
			var i=biome(corner+Vector3(2,0,2))
			if i<0:
				continue
			var color=ground_color(i)
			var points=[Vector3(x*4,0,z*4),Vector3((x+1)*4,0,z*4),Vector3(x*4,0,(z+1)*4),Vector3((x+1)*4,0,(z+1)*4)]
			for order in [0,1,2,1,3,2]:
				var p: Vector3=points[order]
				var wp=root.position+p
				p.y=height_at(wp)
				var slope_x=(height_at(wp+Vector3(0.2,0,0))-height_at(wp-Vector3(0.2,0,0)))/0.4
				var slope_z=(height_at(wp+Vector3(0,0,0.2))-height_at(wp-Vector3(0,0,0.2)))/0.4
				tool.set_normal(Vector3(-slope_x,1,-slope_z).normalized())
				var path=absf(wp.z+72*i-(sin(wp.x*0.055+i)*8.0))
				var tint=color.lerp(Color("#bfc7a4"),0.23) if path<1.1 and absf(wp.x)>25 else color
				tool.set_color(tint.lightened(noise.get_noise_2d(wp.x*3,wp.z*3)*0.035))
				tool.add_vertex(p)
			tri_count+=2
	if tri_count>0:
		var mesh=tool.commit()
		var visual=MeshInstance3D.new()
		visual.mesh=mesh
		var mat=StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo=true
		mat.roughness=1.0
		mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		visual.material_override=mat
		root.add_child(visual)
		var body=StaticBody3D.new()
		var shape=CollisionShape3D.new()
		shape.shape=mesh.create_trimesh_shape()
		body.add_child(shape)
		root.add_child(body)
	# Continuous canyon edges prevent bypassing locked bridges via the outskirts.
	for i in range(5):
		for edge in [28.0,-28.0]:
			var z=-72.0*i+edge
			if z<root.position.z or z>=root.position.z+SIZE:
				continue
			var segment_start=root.position.x
			var segment_end=segment_start+SIZE
			for side in [-1,1]:
				var lo=maxf(segment_start,25.0) if side==1 else segment_start
				var hi=segment_end if side==1 else minf(segment_end,-25.0)
				if hi<=lo:
					continue
				var body=StaticBody3D.new()
				var shape=CollisionShape3D.new()
				var box=BoxShape3D.new()
				box.size=Vector3(hi-lo,5,0.8)
				shape.shape=box
				body.position=Vector3((lo+hi)/2-root.position.x,1.3,z-root.position.z)
				body.add_child(shape)
				root.add_child(body)
				# Match each invisible guard with visible layered escarpment rocks.
				var transforms=[]
				var x=lo+1
				while x<hi:
					var p=Vector3(x-root.position.x,0.5,z-root.position.z)
					transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(4,2.6,3)),p))
					x+=3.2
				batch(root,"rock",transforms,ground_color(i).darkened(0.16),0)
	root.set_meta("terrain_ready",true)

func scatter(job: Dictionary,first: int,last: int) -> void:
	var rng=RandomNumberGenerator.new()
	rng.seed=stable_seed(job.cell)
	for n in range(last):
		var local=Vector3(rng.randf_range(0.3,31.7),0,rng.randf_range(0.3,31.7))
		var wp: Vector3=job.node.position+local
		var scale_factor=rng.randf_range(0.65,1.35)
		var angle=rng.randf()*TAU
		var choice=rng.randf()
		if n<first:
			continue
		var i=biome(wp)
		if i<0 or reserved(wp):
			continue
		var kind="grass"
		if choice<0.20:
			kind="flower"
		elif choice<0.245:
			kind="rock"
		elif choice<0.27 and absf(wp.x)>27:
			kind="tree" if i!=2 else "rock"
		elif choice<0.36 and i==1:
			kind="mushroom"
		var zz=wp.z+72*i
		if absf(zz)>25:
			continue
		var key=str(i)+":"+kind
		if not job.batches.has(key):
			job.batches[key]=[]
		local.y=height_at(wp)+0.045
		job.batches[key].append(Transform3D(Basis(Vector3.UP,angle).scaled(Vector3.ONE*scale_factor),local))
	# One material point per cell, stable identity, independent saved cooldown.
	if first==0:
		var wp: Vector3=job.node.position+Vector3(16,0,16)
		var i=biome(wp)
		if i>=0:
			wp.z=clampf(-72.0*i-10.0,job.node.position.z+3.0,job.node.position.z+29.0)
		if i>=0 and absf(wp.x)>28 and absf(wp.z+72*i)<25:
			wp.y=height_at(wp)+0.05
			job.resource={"id":"%d:%d:%d"%[world_seed,job.cell.x,job.cell.y],"position":wp,"region":i}

func reserved(pos: Vector3) -> bool:
	var i=Data.region_at(pos)
	var local=pos-Data.center(i)
	# Protect the authored path, farm demo space, pet spawn, signs, pond and home.
	if absf(pos.x)<3.1:
		return true
	if absf(local.z+10)<2.5:
		return true
	if absf(local.x+4)<3.0 and absf(local.z)<8:
		return true
	if Vector2(local.x-4,local.z).length()<3.3:
		return true
	if local.x>5.5 and local.x<20.5 and absf(local.z-5)<12:
		return true
	if i==0 and local.x> -19.0 and local.x< -6 and local.z>4 and local.z<18:
		return true
	if i==4 and absf(local.x)<5.5 and local.z< -18:
		return true
	for sign in game.world.signs:
		if sign.node.global_position.distance_to(pos)<1.8:
			return true
	for plot in game.plots:
		if Vector2(plot.position.x-pos.x,plot.position.z-pos.z).length()<1.5:
			return true
	return false

func assemble(job: Dictionary) -> void:
	var detail=Node3D.new()
	detail.name="Details"
	job.node.add_child(detail)
	for key in job.batches:
		var parts=key.split(":")
		var i=int(parts[0])
		var kind=parts[1]
		var color=Color(Data.REGIONS[i].leaf)
		if kind=="grass":
			color=ground_color(i).darkened(0.15)
		elif kind=="flower":
			color=Color(Data.REGIONS[i].accent).lerp(Color("#d9adc3"),0.08*visit_palette)
		elif kind=="rock":
			color=ground_color(i).lerp(Color("#9caa9c"),0.3).darkened(0.1)
		elif kind=="mushroom":
			color=Color("#bda28c")
		elif kind=="tree" and i==2:
			color=Color("#91b2a0")
		if kind=="tree" and i==3:
			color=Color("#bb684b")
		batch(detail,"pine" if kind=="tree" and i==1 else kind,job.batches[key],color,0.28 if i==4 and kind=="flower" else 0)
		if kind=="tree":
			batch(detail,"trunk",job.batches[key],Color("#7c7564"),0)
		if kind in ["tree","rock"]:
			for transform in job.batches[key]:
				var body=StaticBody3D.new()
				body.transform=transform
				var shape=CollisionShape3D.new()
				if kind=="tree":
					var capsule=CapsuleShape3D.new()
					capsule.radius=0.18
					capsule.height=2.8
					shape.shape=capsule
					shape.position.y=1.4
				else:
					var sphere=SphereShape3D.new()
					sphere.radius=0.45
					shape.shape=sphere
					shape.position.y=0.3
				body.add_child(shape)
				detail.add_child(body)
	if job.resource!=null:
		var rec: Dictionary=job.resource
		var node=Node3D.new()
		node.position=rec.position-job.node.position
		detail.add_child(node)
		var tf=[Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*1.4),Vector3.ZERO)]
		batch(node,"flower",tf,Color(Data.REGIONS[rec.region].accent),0.25)
		pickup_nodes[rec.id]={"node":node,"cell":job.cell,"region":rec.region,"position":rec.position}
	job.node.set_meta("details_ready",true)

func batch(parent: Node3D,kind: String,transforms: Array,color: Color,glow: float) -> void:
	if transforms.is_empty():
		return
	var mm=MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.mesh=families[kind]
	mm.instance_count=transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i,transforms[i])
	var node=MultiMeshInstance3D.new()
	node.multimesh=mm
	var key=kind+str(color)+str(glow)
	if not materials.has(key):
		if kind=="grass":
			var wind=ShaderMaterial.new()
			wind.shader=wind_shader
			wind.set_shader_parameter("tint",color)
			materials[key]=wind
		else:
			materials[key]=surface_material(color,glow)
	node.material_override=materials[key]
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if kind in ["grass","flower"] else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(node)

func surface_material(color: Color,glow: float) -> StandardMaterial3D:
	var mat=StandardMaterial3D.new()
	mat.albedo_color=color
	mat.roughness=1
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	if glow>0:
		mat.emission_enabled=true
		mat.emission=color
		mat.emission_energy_multiplier=glow
	return mat

func fog_limit(camera: Camera3D) -> float:
	var origin=camera.global_position
	var heading=-camera.global_basis.z
	heading.y=0
	heading=heading.normalized()
	var bounds_min=Vector2((current_cell.x-1)*SIZE,(current_cell.y-1)*SIZE)
	var bounds_max=bounds_min+Vector2.ONE*SIZE*3
	var distance=64.0
	for angle in [-0.62,0.0,0.62]:
		var direction=heading.rotated(Vector3.UP,angle)
		var tx=1000.0
		var tz=1000.0
		if absf(direction.x)>0.001:
			tx=((bounds_max.x if direction.x>0 else bounds_min.x)-origin.x)/direction.x
		if absf(direction.z)>0.001:
			tz=((bounds_max.y if direction.z>0 else bounds_min.y)-origin.z)/direction.z
		distance=minf(distance,minf(tx,tz)-4)
	return clampf(distance,22,64)

func stable_seed(cell: Vector2i) -> int:
	return world_seed ^ (cell.x*73856093) ^ (cell.y*19349663)

func ground_color(i: int) -> Color:
	return Color("#aaa894") if i==2 else Color(Data.REGIONS[i].ground)

func make_families() -> void:
	var grass=SurfaceTool.new()
	grass.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(3):
		var a=j*PI/3
		var left=Vector3(cos(a)*0.13,0,sin(a)*0.13)
		var right=-left
		var tip=Vector3(sin(a)*0.1,0.35+j*0.07,cos(a)*0.1)
		for vertex in [left,right,tip]:
			grass.set_normal(Vector3.UP)
			grass.add_vertex(vertex)
	families.grass=grass.commit()
	var sphere=SphereMesh.new()
	sphere.radius=0.5
	sphere.height=1
	sphere.radial_segments=8
	sphere.rings=4
	families.rock=scaled_mesh(sphere,Vector3(1.4,0.8,1.1),Vector3(0,0.30,0))
	var tree=SurfaceTool.new()
	tree.begin(Mesh.PRIMITIVE_TRIANGLES)
	for spec in [[Vector3(0,3.1,0),Vector3(2.7,2.6,2.5)],[Vector3(-0.8,2.7,0),Vector3(1.9,1.7,1.9)],[Vector3(0.7,2.6,0.2),Vector3(1.7,1.8,1.8)]]:
		tree.append_from(sphere,0,Transform3D(Basis.IDENTITY.scaled(spec[1]),spec[0]))
	families.tree=tree.commit()
	var pine=SurfaceTool.new()
	pine.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(3):
		var cone=CylinderMesh.new()
		cone.bottom_radius=1.3-j*0.25
		cone.top_radius=0.02
		cone.height=1.7
		cone.radial_segments=7
		pine.append_from(cone,0,Transform3D(Basis.IDENTITY,Vector3(0,2.0+j*0.7,0)))
	families.pine=pine.commit()
	var trunk=CylinderMesh.new()
	trunk.height=3.0
	trunk.bottom_radius=0.16
	trunk.top_radius=0.10
	trunk.radial_segments=6
	families.trunk=scaled_mesh(trunk,Vector3.ONE,Vector3(0,1.5,0))
	var flower=SurfaceTool.new()
	flower.begin(Mesh.PRIMITIVE_TRIANGLES)
	flower.append_from(trunk,0,Transform3D(Basis.IDENTITY.scaled(Vector3(0.13,0.15,0.13)),Vector3(0,0.22,0)))
	for j in range(5):
		var a=j*TAU/5
		flower.append_from(sphere,0,Transform3D(Basis.IDENTITY.scaled(Vector3(0.18,0.07,0.18)),Vector3(cos(a)*0.12,0.46,sin(a)*0.12)))
	families.flower=flower.commit()
	var mushroom=SurfaceTool.new()
	mushroom.begin(Mesh.PRIMITIVE_TRIANGLES)
	mushroom.append_from(trunk,0,Transform3D(Basis.IDENTITY.scaled(Vector3(0.45,0.13,0.45)),Vector3(0,0.19,0)))
	mushroom.append_from(sphere,0,Transform3D(Basis.IDENTITY.scaled(Vector3(0.66,0.24,0.66)),Vector3(0,0.42,0)))
	families.mushroom=mushroom.commit()

func scaled_mesh(mesh: Mesh,scale_value: Vector3,offset: Vector3) -> Mesh:
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(mesh,0,Transform3D(Basis.IDENTITY.scaled(scale_value),offset))
	return st.commit()

func refresh_at(pos: Vector3) -> void:
	# Rebuild visual details to exclude a newly planted stable patch.
	var key=cell_at(pos)
	if not chunks.has(key):
		return
	var root: Node3D=chunks[key]
	var details=root.get_node_or_null("Details")
	if details:
		root.remove_child(details)
		details.queue_free()
	for id in pickup_nodes.keys():
		if pickup_nodes[id].cell==key:
			pickup_nodes.erase(id)
	for job in jobs:
		if job.cell==key:
			if int(job.phase)>0:
				job.phase=1
				job.batches={}
				job.resource=null
			return
	jobs.append({"cell":key,"node":root,"phase":1,"batches":{},"resource":null})

func signature(cell: Vector2i) -> Dictionary:
	var values=[]
	for x in range(3):
		for z in range(3):
			values.append(snappedf(height_at(Vector3(cell.x*SIZE+x*11,0,cell.y*SIZE+z*11)),0.00001))
	return {"seed":stable_seed(cell),"heights":values}

func stats() -> Dictionary:
	return {"chunk_size_m":32,"radius":1,"loaded":chunks.size(),"queued":jobs.size(),"generated":generated_count,"unloaded":unloaded_count,"peak_chunks":peak_chunks,"peak_work_us":peak_work_us,"pickups":pickup_nodes.size()}
