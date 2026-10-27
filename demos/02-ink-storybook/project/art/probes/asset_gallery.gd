extends Node3D
# Native material/front/back calibration of actual GLBs, not game completion evidence.
const Art=preload("res://scripts/art.gd")
var camera: Camera3D
var current: Node3D
var heading: Label
var items=[
	{"id":"meadow-tree","height":5.5},
	{"id":"grass-flower","height":0.45},
	{"id":"traveler","height":1.72},
	{"id":"rabbit","height":0.9}
]
func bounds(node: Node3D) -> AABB:
	var found=false
	var result=AABB()
	for child in node.find_children("*","MeshInstance3D",true,false):
		var b=child.get_aabb()
		for n in range(8):
			var p=child.global_transform*b.get_endpoint(n)
			if not found:
				result=AABB(p,Vector3.ZERO)
				found=true
			else:
				result=result.expand(p)
	return result

func _ready() -> void:
	var folder="user://asset-gallery"
	var source="res://art/assets/raw/"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):folder=arg.trim_prefix("--capture-dir=")
		if arg=="--runtime-models":source="res://art/assets/runtime/"
		if arg=="--environment-models":
			items=[{"id":"cottage","height":5.17},{"id":"stone-arch","height":5.2},{"id":"rock-cluster","height":1.1},{"id":"wood-fence","height":1.2},{"id":"shrub","height":1.1},{"id":"basket","height":.7},{"id":"signpost","height":1.5},{"id":"carrot","height":.65}]
		if arg=="--wide-arch":items=[{"id":"stone-arch-wide-r2","height":4.95}]
		if arg.begins_with("--asset-ids="):
			items=[]
			for id in arg.trim_prefix("--asset-ids=").split(","):items.append({"id":id,"height":1.0})
	DirAccess.make_dir_recursive_absolute(folder)
	var world=WorldEnvironment.new()
	world.environment=Environment.new()
	world.environment.background_mode=Environment.BG_COLOR
	world.environment.background_color=Color("#e6e9e3")
	world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color=Color.WHITE
	world.environment.ambient_light_energy=0.45
	add_child(world)
	var sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-48,-32,0)
	sun.light_color=Color("#fff5e8")
	sun.light_energy=0.42
	sun.shadow_enabled=true
	add_child(sun)
	var floor=Art.box(self,Vector3(0,-0.07,0),Vector3(35,0.14,35),Color("#b9c4b6"))
	camera=Camera3D.new()
	camera.fov=48
	camera.current=true
	add_child(camera)
	var ui=CanvasLayer.new()
	add_child(ui)
	heading=Label.new()
	heading.position=Vector2(35,22)
	heading.add_theme_font_override("font",load("res://assets/fonts/NotoSansCJKsc-Regular.otf"))
	heading.add_theme_font_size_override("font_size",25)
	heading.add_theme_color_override("font_color",Color("#29463e"))
	ui.add_child(heading)
	var report=[]
	for item in items:
		if not FileAccess.file_exists(source+item.id+".glb"):continue
		var scene=load(source+item.id+".glb")
		assert(scene is PackedScene)
		var pivot=Node3D.new()
		add_child(pivot)
		current=scene.instantiate()
		pivot.add_child(current)
		var raw=bounds(current)
		var factor=item.height/maxf(raw.size.y,0.00001)
		current.scale=Vector3.ONE*factor
		current.position=Vector3(-raw.get_center().x*factor,-raw.position.y*factor,-raw.get_center().z*factor)
		var scaled=bounds(current)
		var distance=maxf(item.height,scaled.size.x)*1.9+0.25
		var triangles=0
		var materials=[]
		for mesh in current.find_children("*","MeshInstance3D",true,false):
			for surface in range(mesh.mesh.get_surface_count()):
				var arrays=mesh.mesh.surface_get_arrays(surface)
				triangles+=arrays[Mesh.ARRAY_INDEX].size()/3 if arrays[Mesh.ARRAY_INDEX].size()>0 else arrays[Mesh.ARRAY_VERTEX].size()/3
				var mat=mesh.get_active_material(surface)
				materials.append({"class":mat.get_class(),"albedo_texture":mat.albedo_texture!=null if mat is BaseMaterial3D else false})
		report.append({"id":item.id,"source":source+item.id+".glb","raw_bounds":str(raw),"scale":factor,"target_height":item.height,"scaled_bounds":str(scaled),"triangles":triangles,"materials":materials})
		for index in range(4):
			var angle=index*PI/2+PI/8
			camera.position=Vector3(sin(angle)*distance,item.height*0.67,cos(angle)*distance)
			camera.look_at(Vector3(0,item.height*0.48,0))
			heading.text="%s  ·  native GLB  ·  view %d  ·  %d triangles" % [item.id,index,triangles]
			await get_tree().create_timer(0.4).timeout
			RenderingServer.force_draw()
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(folder+"/"+item.id+"-"+str(index)+".png")
		pivot.queue_free()
		await get_tree().process_frame
	var f=FileAccess.open(folder+"/measurements.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"mode":"native-GLB-calibration","engine":Engine.get_version_info(),"source":source,"assets":report},"\t"))
	f.close()
	get_tree().quit()
