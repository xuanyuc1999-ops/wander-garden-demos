extends Node3D
var camera: Camera3D
var samples=[]
func quad(title: String,pos: Vector3,mode: String) -> void:
	var color=Color("#90ad71")
	var material=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	var mesh: Mesh=QuadMesh.new()
	mesh.size=Vector2(1.3,1.0)
	if mode=="uniform":
		material.albedo_color=color
	elif mode=="linear_uniform":
		material.albedo_color=color.srgb_to_linear()
	elif mode=="texture":
		var image=Image.create(8,8,false,Image.FORMAT_RGBA8)
		image.fill(color)
		material.albedo_texture=ImageTexture.create_from_image(image)
	elif mode.begins_with("vertex"):
		var st=SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for p in [Vector3(-0.65,-0.5,0),Vector3(0.65,-0.5,0),Vector3(-0.65,0.5,0),Vector3(0.65,-0.5,0),Vector3(0.65,0.5,0),Vector3(-0.65,0.5,0)]:
			st.set_normal(Vector3(0,0,1))
			st.set_color(color)
			st.add_vertex(p)
		mesh=st.commit()
		material.vertex_color_use_as_albedo=true
		material.vertex_color_is_srgb=mode=="vertex_srgb"
	var node=MeshInstance3D.new()
	node.mesh=mesh
	node.material_override=material
	node.position=pos
	add_child(node)
	var label=Label3D.new()
	label.text=title
	label.position=pos+Vector3(0,0.7,0)
	label.font_size=22
	label.pixel_size=0.006
	label.modulate=Color("#243d32")
	label.no_depth_test=true
	add_child(label)
	samples.append({"id":mode,"position":pos,"expected_srgb":"90ad71"})

func _ready() -> void:
	var folder="user://color-calibration"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):folder=arg.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(folder)
	var we=WorldEnvironment.new()
	we.environment=Environment.new()
	we.environment.background_mode=Environment.BG_COLOR
	we.environment.background_color=Color("#e6e9e3")
	we.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	we.environment.ambient_light_color=Color.WHITE
	we.environment.ambient_light_energy=0.55
	add_child(we)
	var sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-48,-32,0)
	sun.light_color=Color("#fff5e8")
	sun.light_energy=0.8
	add_child(sun)
	camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=5.5
	camera.position=Vector3(0,1.7,8)
	camera.look_at(Vector3(0,1.7,0))
	camera.current=true
	add_child(camera)
	quad("uniform",Vector3(-3,3,0),"uniform")
	quad("linearized uniform",Vector3(-1,3,0),"linear_uniform")
	quad("sRGB image texture",Vector3(1,3,0),"texture")
	quad("vertex linear flag",Vector3(-3,1,0),"vertex")
	quad("vertex sRGB flag",Vector3(-1,1,0),"vertex_srgb")
	var sphere=MeshInstance3D.new()
	var shape=SphereMesh.new()
	shape.radius=0.5;shape.height=1
	sphere.mesh=shape
	var material=StandardMaterial3D.new()
	material.albedo_color=Color("#eeeeee")
	material.roughness=0.9
	sphere.material_override=material
	sphere.position=Vector3(1,1,0)
	add_child(sphere)
	var rabbit=load("res://art/assets/runtime/rabbit.glb").instantiate()
	add_child(rabbit)
	var raw=AABB()
	var initialized=false
	for m in rabbit.find_children("*","MeshInstance3D",true,false):
		for n in range(8):
			var p=m.global_transform*m.get_aabb().get_endpoint(n)
			if not initialized:raw=AABB(p,Vector3.ZERO);initialized=true
			else:raw=raw.expand(p)
	var scale_factor=2.0/raw.size.y
	rabbit.scale=Vector3.ONE*scale_factor
	rabbit.position=Vector3(3.2-raw.get_center().x*scale_factor,0.1-raw.position.y*scale_factor,-raw.get_center().z*scale_factor)
	var report=[]
	for i in range(3):
		if i==1:
			we.environment.ambient_light_energy=0.28
			sun.light_energy=0.42
		if i==2:
			we.environment.ambient_light_energy=0.45
			sun.light_energy=0.42
		await get_tree().create_timer(0.6).timeout
		RenderingServer.force_draw()
		await RenderingServer.frame_post_draw
		var image=get_viewport().get_texture().get_image()
		image.save_png(folder+"/lighting-"+str(i)+".png")
		var rows=[]
		for sample in samples:
			var coord=camera.unproject_position(sample.position)
			coord*=Vector2(image.get_size())/get_viewport().get_visible_rect().size
			rows.append({"id":sample.id,"expected":sample.expected_srgb,"actual":image.get_pixelv(Vector2i(coord)).to_html(false)})
		report.append({"lighting":i,"ambient":we.environment.ambient_light_energy,"sun":sun.light_energy,"pixels":rows})
	var f=FileAccess.open(folder+"/measurements.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"));f.close()
	get_tree().quit()
