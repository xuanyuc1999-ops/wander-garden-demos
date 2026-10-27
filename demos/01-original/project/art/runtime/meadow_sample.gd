extends "res://art/probes/h2_probe.gd"
const Models=preload("res://art/runtime/model_visuals.gd")
var live_assets: Dictionary={}
var animation_player: AnimationPlayer
var animation_map: Dictionary={}
var last_event_count=0
var interaction_until=0.0
var current_clip=""
var meadow_sky: Sky
var character_skeleton: Skeleton3D
var hand_bone=-1
var watering_can: Node3D
var water_drops: Array=[]
var watering_target=Vector3.ZERO
var crop_asset_metrics: Dictionary={}
var manual_plot_camera=false
var rabbit_motion
var lux_avatar
var lake_visual
var biome_art

func _ready() -> void:
	await super._ready()
	replace_player_for_motion()
	var decor=world.get_node("meadow/ColorAndVolumeProbe")
	install_meadow_surfaces(decor)
	var tree_count=0
	var flower_count=0
	for node in decor.get_children():
		if not node is Node3D or node==cottage or node.get_child_count()==0:
			continue
		var first=node.get_child(0)
		if first is MeshInstance3D and first.mesh is CylinderMesh:
			if absf(first.position.y-1.8)<0.01:
				Models.hide_old_meshes(node)
				var tree=Models.spawn(node,"meadow-tree",5.5)
				if not live_assets.has("meadow-tree"):live_assets["meadow-tree"]=tree
				tree_count+=1
			elif absf(first.position.y-0.25)<0.01:
				Models.hide_old_meshes(node)
				var flower=Models.spawn(node,"grass-flower",0.45)
				if not live_assets.has("grass-flower"):live_assets["grass-flower"]=flower
				flower_count+=1
	var rabbit=pets[0]
	Models.hide_old_meshes(rabbit.visual)
	live_assets["rabbit"]=Models.spawn(rabbit.visual,"rabbit",0.9,PI)
	rabbit_motion=load("res://art/runtime/rabbit_presentation.gd").new()
	rabbit_motion.setup(rabbit,live_assets["rabbit"])
	# Keep original transform markers required by the protected controller.
	if asset_exists("traveler-animated"):
		Models.hide_old_meshes(player.visual)
		var traveler=Models.spawn(player.visual,"traveler-animated",1.72,PI)
		live_assets["traveler"]=traveler
		animation_player=traveler.find_children("*","AnimationPlayer",true,false)[0]
		character_skeleton=traveler.find_children("*","Skeleton3D",true,false)[0]
		lux_avatar=preload("res://art/runtime/lux_preset_avatar.gd").new()
		animation_map=lux_avatar.setup(animation_player,character_skeleton)
		player.walk_speed=1.8
		player.run_speed=5.4
		animation_player.play(animation_map["Idle_Loop"])
		animation_player.advance(0)
		current_clip=animation_map["Idle_Loop"]
		hand_bone=character_skeleton.find_bone("mixamorig_RightHand")
		make_watering_visual()
		hud.help_label.text=hud.help_label.text.replace("Shift 轻跑","Shift 慢跑")
	install_environment_props(decor)
	biome_art=preload("res://art/runtime/biome_art.gd").new()
	biome_art.game=self
	add_child(biome_art)
	for child in hud.main.get_children():
		if child is Label and child.text.begins_with("H2 "):child.visible=false
	for label in hud.start_screen.find_children("*","Label",true,false):
		if "v0.2" in label.text:label.text="漫游、种植与陪伴"
	print("MEADOW_SAMPLE_READY trees=",tree_count," flowers=",flower_count," animations=",animation_map)
	if "--locomotion-check" in OS.get_cmdline_user_args():
		var test=preload("res://art/runtime/locomotion_check.gd").new()
		test.game=self
		add_child(test)
	elif "--meshy-check" in OS.get_cmdline_user_args():
		var test=preload("res://art/runtime/meshy_check.gd").new()
		test.game=self
		add_child(test)
	elif "--biome-check" in OS.get_cmdline_user_args():
		var test=preload("res://art/runtime/biome_check.gd").new()
		test.game=self
		add_child(test)
	elif "--biome-capture" in OS.get_cmdline_user_args():
		var test=preload("res://art/runtime/biome_capture.gd").new()
		test.game=self
		add_child(test)
	elif "--lux-check" in OS.get_cmdline_user_args():
		var test=load("res://art/runtime/lux_avatar_check.gd").new()
		test.game=self
		add_child(test)
	elif "--lux-qa" in OS.get_cmdline_user_args():
		var test=load("res://art/runtime/lux_playthrough.gd").new()
		test.game=self
		add_child(test)
	elif "--motion-water-check" in OS.get_cmdline_user_args():
		var test=load("res://art/runtime/motion_water_check.gd").new()
		test.game=self
		add_child(test)
	elif "--motion-water-demo" in OS.get_cmdline_user_args():
		var test=load("res://art/runtime/motion_water_demo.gd").new()
		test.game=self
		add_child(test)
	elif "--sample-benchmark" in OS.get_cmdline_user_args():
		var test=load("res://art/runtime/sample_benchmark.gd").new()
		test.game=self
		add_child(test)
	elif "--pilot-proof" in OS.get_cmdline_user_args():
		var test=load("res://art/runtime/pilot_proof.gd").new()
		test.game=self
		add_child(test)
	elif "--sample-test" in OS.get_cmdline_user_args():
		var test=load("res://art/runtime/lux_layout.gd").new()
		test.game=self
		add_child(test)
	elif "--sample-capture" in OS.get_cmdline_user_args():
		var capture=load("res://art/runtime/sample_capture.gd").new()
		capture.game=self
		add_child(capture)

func replace_player_for_motion() -> void:
	var old=player
	var start=old.position
	var yaw=old.pivot.rotation.y
	var pitch=old.orbit_pitch
	var distance=old.arm.spring_length
	var was_enabled=old.enabled
	remove_child(old)
	player=load("res://art/runtime/cozy_player.gd").new()
	player.name="Traveler"
	add_child(player)
	player.position=start
	player.pivot.rotation.y=yaw
	player.orbit_pitch=pitch
	player.arm.rotation.x=pitch
	player.arm.spring_length=distance
	player.enabled=was_enabled
	old.queue_free()

func asset_exists(id: String) -> bool:
	return ResourceLoader.exists(Models.resource_path(id))

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and current_target.get("type","")=="plot":
		manual_plot_camera=true

func install_environment_props(decor: Node3D) -> void:
	if asset_exists("cottage"):
		Models.hide_old_meshes(cottage)
		live_assets["cottage"]=Models.spawn(cottage,"cottage",3.98,PI)
	if asset_exists("basket"):
		Models.hide_old_meshes(world.baskets[0])
		live_assets["basket"]=Models.spawn(world.baskets[0],"basket",.72)
	if asset_exists("signpost"):
		for sign in world.signs:
			if sign.region!=0:continue
			Models.hide_old_meshes(sign.node)
			var model=Models.spawn(sign.node,"signpost",1.45)
			live_assets["signpost"]=model
	if asset_exists("rock-cluster"):
		for node in decor.get_children():
			if not node is MeshInstance3D or not node.mesh is SphereMesh:continue
			if node.scale.x<.8:continue
			var height=.5 if node.scale.x<2 else 2.0
			var rock=Models.spawn(decor,"rock-cluster",height)
			rock.position=Vector3(node.position.x,-.03,node.position.z)
			rock.rotation.y=fmod(node.position.x*2.13+node.position.z,TAU)
			node.visible=false
			live_assets["rock-cluster"]=rock
	if asset_exists("wood-fence"):
		for node in decor.get_children():
			if node is MeshInstance3D and absf(node.position.z+13.5)<.01:
				node.visible=false
		for x in [-13.65,-8.35]:
			var fence=Models.spawn(decor,"wood-fence",1.15)
			fence.position=Vector3(x,0,-13.5)
			live_assets["wood-fence"]=fence
	if asset_exists("shrub"):
		for point in [Vector3(-15.5,0,-17),Vector3(-6.2,0,-19),Vector3(-16,0,-12),Vector3(19.5,0,12),Vector3(18,0,-3),Vector3(-19,0,2)]:
			var shrub=Models.spawn(decor,"shrub",.95)
			shrub.position=point
			live_assets["shrub"]=shrub
	if asset_exists("stone-arch"):
		var parent=world.gate_bodies[0].get_parent()
		for node in parent.get_children():
			if node is StaticBody3D:
				if node.position.y>2 and (absf(node.position.x)>3 or node.position.y>4):
					node.collision_layer=0
			elif node is Node3D and not node is MeshInstance3D and node!=world.gate_visuals[0] and node.get_child_count()==5:
				node.visible=false
		var arch=Models.spawn(parent,"stone-arch",4.95)
		live_assets["stone-arch"]=arch
		for mesh in arch.find_children("*","MeshInstance3D",true,false):
			mesh.create_trimesh_collision()

func make_watering_visual() -> void:
	watering_can=Node3D.new()
	add_child(watering_can)
	Art.cylinder(watering_can,Vector3(0,-.15,0),.13,.15,.22,Color("#85b8b3"))
	var spout=Art.cylinder(watering_can,Vector3(0,-.08,-.24),.034,.045,.30,Color("#a4ccc2"))
	spout.rotation.x=PI/2+.2
	var handle=MeshInstance3D.new()
	var torus=TorusMesh.new();torus.inner_radius=.075;torus.outer_radius=.1
	torus.rings=12;torus.ring_segments=6
	handle.mesh=torus;handle.material_override=Art.mat(Color("#badbd0"))
	handle.position=Vector3(0,-.04,.07);handle.rotation.x=PI/2
	watering_can.add_child(handle)
	for n in range(9):
		var drop=Art.ball(self,Vector3.ZERO,Vector3(.035,.07,.035),Color("#b7e3e1"),.1)
		drop.visible=false
		water_drops.append(drop)
	watering_can.visible=false

func update_crop_visuals() -> void:
	if not asset_exists("carrot"):return
	for plot in plots:
		var state=str(plot.crop)+":"+str(plot.stage)
		if plot.get_meta("art_state","")==state:continue
		plot.set_meta("art_state",state)
		var old=plot.get_node_or_null("GeneratedCrop")
		if old!=null:old.free()
		plot.plants.visible=plot.crop!=0
		if plot.crop!=0:continue
		var root=Node3D.new();root.name="GeneratedCrop";plot.add_child(root)
		var size=[.11,.23,.39,.55][clampi(plot.stage,0,3)]
		for x in [-.35,.35]:
			for z in [-.33,.33]:
				var carrot=Models.spawn(root,"carrot",size)
				carrot.position=Vector3(x,.05,z)
				if crop_asset_metrics.is_empty():
					crop_asset_metrics={"triangles":Models.triangles(carrot),"source":carrot.get_meta("source")}

func update_watering_visual() -> void:
	if watering_can==null:return
	var active=current_clip==animation_map.get("Farm_Watering","") and elapsed<interaction_until
	watering_can.visible=active
	for drop in water_drops:drop.visible=active
	if not active or hand_bone<0:return
	var hand=character_skeleton.global_transform*character_skeleton.get_bone_global_pose(hand_bone)
	var phase=clampf(animation_player.current_animation_position/animation_player.current_animation_length,0,1)
	watering_can.global_rotation=Vector3(-.18*sin(phase*PI),player.visual.global_rotation.y,0)
	var palm=hand.origin+hand.basis.y.normalized()*.035
	watering_can.global_position=palm-watering_can.global_basis*Vector3(0,.06,.07)
	var start=watering_can.to_global(Vector3(0,-.10,-.38))
	for n in range(water_drops.size()):
		var t=fmod(elapsed*1.5+float(n)/water_drops.size(),1.0)
		water_drops[n].global_position=start.lerp(watering_target+Vector3(0,.12,0),t)+Vector3.UP*sin(t*PI)*.15

func install_meadow_surfaces(decor: Node3D) -> void:
	for node in decor.get_children():
		if not node is MeshInstance3D:continue
		if node.mesh is BoxMesh and node.position.y<-.3 and node.mesh.size.x>40:
			node.visible=false
		elif node.mesh is CylinderMesh and node.position.y<.02 and node.mesh.height<.05:
			node.visible=false
		elif node.mesh is CylinderMesh and node.position.distance_to(Vector3(13,.023,5))<.01:
			node.visible=false
	var ground=MeshInstance3D.new()
	ground.name="MeadowLayeredGround"
	var plane=PlaneMesh.new();plane.size=Vector2(50,56)
	ground.mesh=plane
	var material=ShaderMaterial.new()
	material.shader=preload("res://art/runtime/meadow_surface.gdshader")
	ground.material_override=material
	decor.add_child(ground)
	var previous=streamer
	remove_child(previous)
	streamer=load("res://art/runtime/art_streamer.gd").new()
	streamer.game=self
	streamer.world_seed=previous.world_seed
	streamer.collected=previous.collected.duplicate()
	add_child(streamer)
	previous.queue_free()
	meadow_sky=Sky.new()
	var sky_material=ShaderMaterial.new()
	sky_material.shader=preload("res://art/runtime/meadow_sky.gdshader")
	meadow_sky.sky_material=sky_material
	lake_visual=load("res://art/runtime/lake_v04.gd").new()
	lake_visual.game=self
	decor.add_child(lake_visual)

func _process(delta: float) -> void:
	super._process(delta)
	if not world_ready:return
	var still=Vector2(player.velocity.x,player.velocity.z).length()<.2
	if current_target.get("type","")!="plot" or not still:manual_plot_camera=false
	var viewing_plot=current_target.get("type","")=="plot" and still and not photo and not manual_plot_camera
	var camera_pitch=minf(player.orbit_pitch,-.85) if viewing_plot else player.orbit_pitch
	player.arm.rotation.x=lerpf(player.arm.rotation.x,camera_pitch,1.0-exp(-delta*4.0))
	update_crop_visuals()
	if biome_art:
		biome_art.update_crops()
		biome_art.update(delta)
	update_watering_visual()
	if rabbit_motion!=null:rabbit_motion.update(delta,paused)
	if region==0 and biome_art==null:
		var night=clampf((sin(clock*TAU-PI/2)+0.1)*0.55,0,0.55)
		sunlight.light_energy=0.42-night*0.20
		env.ambient_light_energy=0.45-night*0.12
		env.background_mode=Environment.BG_SKY
		env.sky=meadow_sky
		meadow_sky.sky_material.set_shader_parameter("daylight",1.0-night*1.25)
		env.fog_sky_affect=.2
	elif biome_art==null:
		env.background_mode=Environment.BG_COLOR
		env.fog_sky_affect=1
	if animation_player==null:return
	if paused:
		animation_player.speed_scale=0
		return
	animation_player.speed_scale=1
	if events.size()>last_event_count:
		for i in range(last_event_count,events.size()):
			var type=events[i].type
			var action="Farm_Watering" if type=="water" else "Interact" if type in ["sow","harvest","feed","cultivate","seed_pickup","gate_unlock"] else ""
			if animation_map.has(action):
				var clip=animation_map[action]
				var destination=farm_position()
				if current_target.has("node"):
					destination=current_target.node.global_position
				elif type=="cultivate":
					destination=Vector3(events[i].details.x,0,events[i].details.z)
				var facing=destination-player.global_position
				if Vector2(facing.x,facing.z).length()>0.05:
					player.visual.rotation.y=atan2(-facing.x,-facing.z)
				if type=="water":watering_target=destination
				animation_player.play(clip,0.12)
				current_clip=clip
				interaction_until=elapsed+animation_player.get_animation(clip).length
		last_event_count=events.size()
	var move_speed=Vector2(player.velocity.x,player.velocity.z).length()
	if elapsed<interaction_until:
		if move_speed<.25:return
		interaction_until=elapsed
		current_clip=""
	var action="Run_Loop" if move_speed>player.walk_speed*1.5 else "Walk_Loop" if move_speed>.06 else "Idle_Loop"
	if animation_map.has(action) and current_clip!=animation_map[action]:
		current_clip=animation_map[action]
		animation_player.play(current_clip,0.22)
	if action=="Walk_Loop":
		animation_player.speed_scale=clampf(move_speed/lux_avatar.native_walk_speed,.08,2.4)
	elif action=="Run_Loop":
		animation_player.speed_scale=clampf(move_speed/lux_avatar.native_run_speed,.08,1.35)
	else:
		animation_player.speed_scale=1
