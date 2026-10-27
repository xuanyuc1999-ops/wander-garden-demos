extends "res://scripts/game.gd"
# Isolated reversible H2 proposal. Default main.tscn and original gameplay scripts
# are unchanged; this scene never reads or writes the player's saved game.
var proposal=false
var cottage: Node3D
var cottage_body: StaticBody3D
var changes: Array=[]
var old_cottage=Vector3(-12,0,11)
var new_cottage=Vector3(-11,0,-18)
var cottage_scale=1.1

func load_game() -> void:
	pass

func save_game() -> void:
	pass

func _ready() -> void:
	await super._ready()
	qa=true
	proposal=not "--h2-baseline" in OS.get_cmdline_user_args()
	var decor=world.get_node("meadow/ColorAndVolumeProbe")
	for node in decor.get_children():
		if node is Node3D and node.position.distance_to(old_cottage)<0.01:
			cottage=node
	for node in world.get_node("meadow").get_children():
		if node is StaticBody3D and node.position.distance_to(Vector3(-12,1.5,11))<0.01:
			cottage_body=node
	assert(cottage!=null and cottage_body!=null)
	if proposal:
		apply_proposal()
	var badge=Label.new()
	badge.text="H2 空间体量提案 · 非最终美术" if proposal else "H2 对照 · 当前灰盒"
	badge.position=Vector2(930,92)
	badge.add_theme_font_override("font",load("res://assets/fonts/NotoSansCJKsc-Regular.otf"))
	badge.add_theme_font_size_override("font_size",18)
	badge.add_theme_color_override("font_color",Color("#234e43"))
	hud.main.add_child(badge)
	if "--h2-test" in OS.get_cmdline_user_args():
		var runner=load("res://art/probes/h2_test.gd").new()
		runner.game=self
		add_child(runner)
	elif "--h2-capture" in OS.get_cmdline_user_args():
		var capture=load("res://art/probes/h2_capture.gd").new()
		capture.game=self
		add_child(capture)

func apply_proposal() -> void:
	cottage.position=new_cottage
	cottage.rotation.y=PI
	cottage.scale=Vector3.ONE*cottage_scale
	cottage_body.position=new_cottage+Vector3(0,1.5*cottage_scale,0)
	cottage_body.scale=Vector3.ONE*cottage_scale
	# Same temporary volume, just a roof-color cue; not a second art production pass.
	for node in cottage.get_children():
		if node is MeshInstance3D and node.position.y>3:
			node.material_override=Art.mat(Color("#c58b68"))
	var decor=world.get_node("meadow/ColorAndVolumeProbe")
	for node in decor.get_children():
		if not node is Node3D:
			continue
		if node.position.distance_to(Vector3(-15,0,15))<0.01:
			node.position=Vector3(-16,0,-22)
			Art.solid(world.get_node("meadow"),Vector3(-16,1.3,-22),Vector3(0.65,2.6,0.65))
		elif node.position.distance_to(Vector3(-9,0,15))<0.01:
			node.position=Vector3(-6,0,-22)
			Art.solid(world.get_node("meadow"),Vector3(-6,1.3,-22),Vector3(0.65,2.6,0.65))
		elif absf(node.position.z-6.5)<0.01 and node.position.x>= -17 and node.position.x<= -7:
			node.queue_free()
	# Two short fence segments with a 2.6m opening in front of the cottage.
	for span in [[-15.0,-12.3],[-9.7,-7.0]]:
		var middle=(span[0]+span[1])/2.0
		Art.box(decor,Vector3(middle,0.75,-13.5),Vector3(span[1]-span[0],0.10,0.10),Color("#d8c5a2"))
		Art.solid(world.get_node("meadow"),Vector3(middle,0.65,-13.5),Vector3(span[1]-span[0],1.3,0.16))
		for x in span:
			Art.cylinder(decor,Vector3(x,0.6,-13.5),0.09,0.08,1.2,Color("#d8c5a2"))
	# The existing arch was visual-only above the gate. Make its authoritative
	# envelope available to the camera sweep as well as to walking bodies.
	var gate_parent=world.gate_bodies[0].get_parent()
	for side in [-1,1]:
		Art.solid(gate_parent,Vector3(side*3.8,2.1,0),Vector3(1.2,4.2,1.2))
	Art.solid(gate_parent,Vector3(0,4.5,0),Vector3(7.2,0.7,1.0))
	var previous=streamer
	remove_child(previous)
	previous.queue_free()
	streamer=load("res://art/probes/h2_streamer.gd").new()
	streamer.game=self
	add_child(streamer)
	player.arm.spring_length=9.0
	player.orbit_pitch=-0.38
	player.arm.rotation.x=player.orbit_pitch
	player.pivot.rotation.y=0.0
	changes=[
		{"id":"cottage","from":[-12,0,11],"to":[-11,0,-18],"uniform_scale":1.1,"rotation_y_degrees":180,"footprint_m":[4.95,4.18],"volume_peak_m":5.17},
		{"id":"porch","fence_z":-13.5,"opening_x":[-12.3,-9.7],"clear_width_m":2.6},
		{"id":"camera","spring_length_m":9.0,"pitch_radians":-0.38,"fov":55},
		{"id":"meadow_fog","depth_begin_m":44,"depth_end_m":70,"scope":"northward central composition only; camera-aware chunk fade preserved elsewhere"},
		{"id":"arch_camera_envelope","clear_width_m":6.4,"clear_height_m":4.15,"purpose":"avoid visual beam intersecting orbit camera"},
		{"id":"preserved","player_start":[0,0,9],"seed_basket":[-4,0,4],"pet_spawn":[4,0,0],"lake_center":[13,0,5],"gate":[0,0,-36],"main_path_exclusion_width_m":6.2,"peripheral_path_z":-10,"chunk_size_m":32,"chunk_count":9}
	]

func _process(delta: float) -> void:
	super._process(delta)
	if world_ready and proposal and region==0:
		var north_weight=pow(maxf(0,(-player.pivot.global_basis.z).dot(Vector3.FORWARD)),4)
		north_weight*=1.0-smoothstep(3.0,7.0,absf(player.position.x))
		var base=streamer.fog_limit(player.camera)
		env.fog_depth_begin=lerpf(base*0.48,44,north_weight)
		env.fog_depth_end=lerpf(base,70,north_weight)

func can_farm(pos: Vector3) -> bool:
	if not proposal:
		return super.can_farm(pos)
	if data.region_at(pos)==0 and absf(pos.x-new_cottage.x)<3.7 and absf(pos.z-new_cottage.z)<3.4:
		return false
	# Remove the old fixed cottage exclusion only in this isolated proposal.
	if data.region_at(pos)==0 and absf(pos.x+12)<3.4 and absf(pos.z-11)<3:
		for p in plots:
			if pos.distance_to(p.position)<1.65:
				return false
		var query=PhysicsShapeQueryParameters3D.new()
		var shape=SphereShape3D.new()
		shape.radius=0.86
		query.shape=shape
		query.transform=Transform3D(Basis.IDENTITY,pos+Vector3(0,1,0))
		query.collision_mask=1
		query.exclude=[player.get_rid()]
		return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
	return super.can_farm(pos)

func projected_cottage() -> Dictionary:
	var bounds=Rect2()
	var initialized=false
	var behind=false
	for mesh in cottage.get_children():
		if not mesh is MeshInstance3D:
			continue
		var box=mesh.get_aabb()
		for n in range(8):
			var point=mesh.global_transform*box.get_endpoint(n)
			behind=behind or player.camera.is_position_behind(point)
			var projected=player.camera.unproject_position(point)
			if not initialized:
				bounds=Rect2(projected,Vector2.ZERO)
				initialized=true
			else:
				bounds=bounds.expand(projected)
	var viewport=get_viewport().get_visible_rect()
	return {"rect":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],"viewport":[viewport.size.x,viewport.size.y],"within_frame":not behind and viewport.encloses(bounds),"behind":behind}
