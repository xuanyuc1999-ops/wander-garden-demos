extends Node3D
const data=preload("res://scripts/data.gd")
const Art=preload("res://scripts/art.gd")
const Player=preload("res://scripts/player.gd")
const World=preload("res://scripts/world.gd")
const Plot=preload("res://scripts/plot.gd")
const Pet=preload("res://scripts/pet.gd")
const Hud=preload("res://scripts/hud.gd")
const ChunkStreamer=preload("res://scripts/chunk_streamer.gd")
var player: CharacterBody3D
var world: Node3D
var hud: CanvasLayer
var env: Environment
var sunlight: DirectionalLight3D
var plots: Array=[]
var pets: Array=[]
var seeds: Array=[5,0,0,0,0]
var harvest: Array=[0,0,0,0,0]
var discovered_crops: Array=[false,false,false,false,false]
var discovered_pets: Array=[false,false,false,false,false]
var read_signs: Array=[]
var unlocked=0
var selected_seed=0
var speed_index=1
var grid=false
var region=0
var paused=true
var world_ready=false
var started=false
var clock=0.20
var elapsed=0.0
var save_timer=0.0
var basket_times: Array=[-100.0,-100.0,-100.0,-100.0,-100.0]
var music: Array[AudioStreamPlayer]=[]
var music_on=true
var sound: AudioStreamPlayer
var events: Array=[]
var qa=false
var photo=false
var photo_filter=0
var photo_overlay: ColorRect
var photo_controls: Label
var cursor: Node3D
var streamer: Node3D
var current_target: Dictionary={}

func _ready() -> void:
	qa="--qa" in OS.get_cmdline_user_args() or "--screenshots" in OS.get_cmdline_user_args() or "--benchmark" in OS.get_cmdline_user_args()
	setup_input()
	setup_environment()
	world=World.new()
	add_child(world)
	for i in range(5):
		world.build_region(i)
		if i<4:
			world.build_connector(i)
		await get_tree().process_frame
	player=Player.new()
	player.name="Traveler"
	add_child(player)
	player.position=Vector3(0,0.2,9)
	streamer=ChunkStreamer.new()
	streamer.game=self
	add_child(streamer)
	for i in range(5):
		var pet=Pet.new()
		pet.kind=i
		pet.game=self
		pet.position=data.center(i)+Vector3(4,0,0)
		add_child(pet)
		pets.append(pet)
	hud=Hud.new()
	hud.game=self
	add_child(hud)
	cursor=Node3D.new()
	add_child(cursor)
	var ring=MeshInstance3D.new()
	var torus=TorusMesh.new()
	torus.inner_radius=0.81
	torus.outer_radius=0.87
	torus.rings=24
	torus.ring_segments=6
	ring.mesh=torus
	ring.scale.y=0.12
	ring.material_override=Art.mat(Color("#f0e4bd"),0.25)
	cursor.add_child(ring)
	setup_audio()
	if not qa:
		load_game()
	world_ready=true
	print("WANDER_GARDEN_READY")
	if "--qa" in OS.get_cmdline_user_args():
		var test=load("res://tests/playthrough.gd").new()
		test.game=self
		add_child(test)
	elif "--screenshots" in OS.get_cmdline_user_args():
		var capture=load("res://tests/capture.gd").new()
		capture.game=self
		add_child(capture)
	elif "--benchmark" in OS.get_cmdline_user_args():
		var benchmark=load("res://tests/benchmark.gd").new()
		benchmark.game=self
		add_child(benchmark)

func setup_input() -> void:
	var keys={"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"run":KEY_SHIFT,"interact":KEY_E,"cultivate":KEY_F,"seed":KEY_Q}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var ev=InputEventKey.new()
		ev.physical_keycode=keys[action]
		InputMap.action_add_event(action,ev)

func setup_environment() -> void:
	var we=WorldEnvironment.new()
	env=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("#b4d2d0")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("#e0e2ce")
	env.ambient_light_energy=0.44
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	env.fog_enabled=true
	env.fog_mode=Environment.FOG_MODE_DEPTH
	env.fog_depth_begin=22
	env.fog_depth_end=48
	env.fog_depth_curve=1.35
	env.fog_light_color=Color("#b4d2d0")
	env.fog_density=1.0
	we.environment=env
	add_child(we)
	sunlight=DirectionalLight3D.new()
	sunlight.rotation_degrees=Vector3(-55,-30,0)
	sunlight.light_color=Color("#fff0ce")
	sunlight.light_energy=0.72
	sunlight.shadow_enabled=true
	sunlight.directional_shadow_max_distance=65
	add_child(sunlight)

func setup_audio() -> void:
	for i in range(5):
		var p=AudioStreamPlayer.new()
		p.stream=load("res://assets/audio/region_"+str(i)+".wav")
		p.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
		p.stream.loop_end=384000
		p.volume_db=-60
		add_child(p)
		music.append(p)
	sound=AudioStreamPlayer.new()
	sound.stream=load("res://assets/audio/chime.wav")
	sound.volume_db=-19
	add_child(sound)

func begin() -> void:
	started=true
	paused=false
	player.enabled=true
	hud.start_screen.visible=false
	hud.main.visible=true
	toast(data.REGIONS[region].line)
	for m in music:
		if not m.playing and not qa:
			m.play()
	event("begin",{})

func _process(delta: float) -> void:
	if not world_ready:
		return
	if not paused:
		elapsed+=delta
		clock=fmod(clock+delta/600,1)
	var next_region=data.region_at(player.position)
	# Crossing a connector changes mood gradually while walking.
	if next_region!=region:
		region=next_region
		toast(data.REGIONS[region].line)
		event("region",{"region":region})
	var coordinate=clampf(-player.position.z/72.0,0,4)
	var lo=int(floor(coordinate))
	var hi=mini(lo+1,4)
	var blend=smoothstep(0.33,0.67,coordinate-lo)
	var sky=Color(data.REGIONS[lo].sky).lerp(Color(data.REGIONS[hi].sky),blend)
	var night=clampf((sin(clock*TAU-PI/2)+0.1)*0.55,0,0.55)
	var star_blend=clampf((coordinate-3.3)/0.4,0,1)
	var sun_target=lerpf(0.72-night*0.55,0.22,star_blend)
	sunlight.light_energy=lerpf(sunlight.light_energy,sun_target,delta*1.7)
	env.ambient_light_energy=lerpf(env.ambient_light_energy,lerpf(0.44-night*0.2,0.36,star_blend),delta)
	env.background_color=env.background_color.lerp(sky.darkened(night*(1-star_blend)),delta*1.4)
	env.fog_light_color=env.background_color
	var fog_end=streamer.fog_limit(player.camera)*(0.85 if region==1 else 1.0)
	env.fog_depth_end=lerpf(env.fog_depth_end,fog_end,delta*4)
	env.fog_depth_begin=env.fog_depth_end*0.48
	for i in range(music.size()):
		var distance=absf(coordinate-i)
		var volume=-19.0 if distance<0.4 else -19.0-(distance-0.4)*80.0
		music[i].volume_db=lerpf(music[i].volume_db,maxf(-70.0,volume) if music_on and started else -70.0,delta)
		if started and not music[i].playing and not qa:
			music[i].play()
	world.update_visibility(player.position)
	for p in plots:
		p.visible=p.position.distance_to(player.position)<115
	current_target=find_target()
	cursor.position=farm_position()
	cursor.visible=started and not hud.panel.visible and not photo and current_target.is_empty() and can_farm(cursor.position)
	save_timer+=delta
	if save_timer>12 and started and not qa:
		save_timer=0
		save_game()

func _unhandled_input(ev: InputEvent) -> void:
	if not world_ready or not ev is InputEventKey or not ev.pressed or ev.echo:
		return
	if not started:
		if ev.physical_keycode==KEY_ENTER:
			begin()
		return
	if ev.physical_keycode==KEY_ESCAPE:
		if photo:
			toggle_photo()
		elif hud.panel.visible:
			hud.close()
		else:
			hud.toggle("pause")
			paused=true
		return
	if photo:
		if ev.physical_keycode==KEY_P:
			toggle_photo()
		elif ev.physical_keycode==KEY_ENTER:
			take_photo()
		elif ev.physical_keycode==KEY_V:
			photo_filter=(photo_filter+1)%3
			photo_overlay.color=[Color(0,0,0,0),Color(0.8,0.55,0.25,0.10),Color(0.3,0.45,0.8,0.12)][photo_filter]
		return
	match ev.physical_keycode:
		KEY_B: hud.toggle("bag")
		KEY_J: hud.toggle("journal")
		KEY_T:
			speed_index=(speed_index+1)%3
			hud.update_panel()
			toast("生长速度 · "+data.SPEED_NAMES[speed_index])
		KEY_G:
			grid=not grid
			toast("网格吸附已开启" if grid else "自由开垦已开启")
		KEY_M:
			music_on=not music_on
			toast("原野安静下来了。" if not music_on else "风里的音乐回来了。")
		KEY_H: hud.help_label.visible=not hud.help_label.visible
		KEY_P: toggle_photo()
		KEY_F5:
			save_game()
			toast("这片田园已保存。")
	if hud.panel.visible:
		return
	match ev.physical_keycode:
		KEY_F: cultivate()
		KEY_E: interact()
		KEY_Q:
			for step in range(1,6):
				var candidate=(selected_seed+step)%5
				if seeds[candidate]>0:
					selected_seed=candidate
					break
		KEY_R: toggle_companion()
		KEY_L:
			if current_target.get("type")=="plot":
				current_target.node.loosened=true
				toast("土壤松软了一点，生长速度增加 20%。")

func farm_position() -> Vector3:
	var forward=-player.pivot.global_basis.z
	forward.y=0
	var pos=player.position+forward.normalized()*1.9
	if grid:
		pos.x=snappedf(pos.x,2)
		pos.z=snappedf(pos.z,2)
	pos.y=0.03 if absf(pos.x)<25 else streamer.height_at(pos)+0.035
	return pos

func can_farm(pos: Vector3) -> bool:
	var i=data.region_at(pos)
	var local=pos-data.center(i)
	if i>unlocked or absf(local.z)>25 or not streamer.has_surface(pos):
		return false
	if local.x>6 and local.x<20 and absf(local.z-5)<(11 if i==2 else 7):
		return false
	if i==0 and absf(local.x+12)<3.4 and absf(local.z-11)<3:
		return false
	for b in world.baskets:
		if pos.distance_to(b.global_position)<1.5:
			return false
	for p in plots:
		if pos.distance_to(p.position)<1.65:
			return false
	# Reject contact with physical props without conflating decorative foliage.
	var params=PhysicsShapeQueryParameters3D.new()
	var shape=SphereShape3D.new()
	shape.radius=0.86
	params.shape=shape
	params.transform=Transform3D(Basis.IDENTITY,pos+Vector3(0,1,0))
	params.collision_mask=1
	params.exclude=[player.get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(params,1).is_empty()

func cultivate() -> void:
	var pos=farm_position()
	if not can_farm(pos):
		toast("换一块开阔的平地试试吧。")
		return
	add_plot(pos)
	streamer.refresh_at(pos)
	event("cultivate",{"region":region,"x":pos.x,"z":pos.z})
	toast("一小块属于你的田。E 播种，Q 换种子。")
	chime()

func add_plot(pos: Vector3):
	var p=Plot.new()
	p.game=self
	p.position=pos
	add_child(p)
	plots.append(p)
	return p

func find_target() -> Dictionary:
	var best: Dictionary={}
	var distance=2.7
	for plot in plots:
		var d=player.position.distance_to(plot.position)
		if d<distance:
			distance=d
			best={"type":"plot","node":plot}
	for pet in pets:
		# A following friend should not steal E from an unfamiliar animal in front.
		var actual_distance=player.position.distance_to(pet.position)
		var d=actual_distance+(1.1 if pet.following else 0.0)
		if d<distance:
			distance=d
			best={"type":"pet","node":pet}
	for i in range(5):
		var d=player.position.distance_to(world.baskets[i].global_position)
		if d<distance:
			distance=d
			best={"type":"basket","index":i}
	for i in range(4):
		var d=player.position.distance_to(data.gate_pos(i))
		if i==unlocked and d<3.8 and best.is_empty():
			best={"type":"gate","index":i}
	for sign in world.signs:
		var d=player.position.distance_to(sign.node.global_position)
		if d<distance:
			distance=d
			best={"type":"sign","sign":sign}
	for id in streamer.pickup_nodes:
		var pickup: Dictionary=streamer.pickup_nodes[id]
		if not is_instance_valid(pickup.node) or not pickup.node.visible:
			continue
		var d=player.position.distance_to(pickup.position)
		if d<distance:
			distance=d
			best={"type":"wild","id":id,"region":pickup.region}
	return best

func target_prompt() -> String:
	if current_target.is_empty():
		return "F  留下一小块田园" if cursor.visible else ""
	match current_target.type:
		"plot": return current_target.node.prompt()
		"pet":
			var p=current_target.node
			return "E  投喂 %s · 好感 %d / 100" % [data.REGIONS[p.kind].pet,p.affection]
		"basket": return "E  取一些"+data.REGIONS[current_target.index].crop+"种子"
		"gate": return "E  留下 %s × 2 · 让微光连通原野" % data.REGIONS[current_target.index].crop
		"sign": return "E  读一封留在风里的短笺"
		"wild": return "E  轻采一些野生种子 · "+data.REGIONS[current_target.region].crop
	return ""

func interact() -> void:
	current_target=find_target()
	if current_target.is_empty():
		return
	match current_target.type:
		"plot": current_target.node.interact()
		"pet": current_target.node.feed()
		"basket":
			var i=current_target.index
			if elapsed-basket_times[i]>=30 or seeds[i]==0:
				seeds[i]+=3
				basket_times[i]=elapsed
				selected_seed=i
				toast(data.REGIONS[i].crop+"种子 +3")
				event("seed_pickup",{"region":i})
				chime()
			else:
				toast("篮子在慢慢补满。可以先去看看风景。")
		"gate":
			var i=current_target.index
			if harvest[i]>=2:
				harvest[i]-=2
				unlocked=i+1
				world.open_gate(i)
				event("gate_unlock",{"gate":i})
				chime()
				toast("微光回应了你。前方是"+data.REGIONS[i+1].name+"。")
			else:
				toast("这里喜欢"+data.REGIONS[i].crop+" ×2。想来时再带上就好。")
		"sign":
			var s=current_target.sign
			if not s.id in read_signs:
				read_signs.append(s.id)
			hud.story(s.text)
		"wild":
			var i=current_target.region
			seeds[i]+=2
			streamer.collected[current_target.id]=elapsed
			streamer.pickup_nodes[current_target.id].node.visible=false
			toast(data.REGIONS[i].crop+"种子 +2 · 这里会慢慢长出新的")
			event("wild_pickup",{"id":current_target.id,"region":i})
			chime()

func set_companion(pet: Node) -> void:
	for p in pets:
		if p!=pet:
			if p.following:
				p.home=p.position
			p.following=false
	pet.following=true
	pet.trail.clear()
	event("companion",{"pet":pet.kind})

func toggle_companion() -> void:
	for p in pets:
		if p.following:
			p.following=false
			p.trail.clear()
			p.home=p.position
			p.state="rest"
			toast("它会在这里等你。靠近后按 R 再一起走。")
			return
	var nearest=null
	var distance=4.0
	for p in pets:
		if p.affection>=100 and p.position.distance_to(player.position)<distance:
			nearest=p
			distance=p.position.distance_to(player.position)
	if nearest:
		set_companion(nearest)

func toggle_photo() -> void:
	photo=not photo
	player.photo=photo
	hud.main.visible=not photo
	if photo:
		photo_overlay=ColorRect.new()
		photo_overlay.color=Color(0,0,0,0)
		photo_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		photo_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
		hud.add_child(photo_overlay)
		photo_controls=hud.label(hud,"右键环绕 · 滚轮远近 · V 滤镜 · Enter 保存照片 · P / Esc 返回",16)
		photo_controls.position=Vector2(400,850)
	else:
		if is_instance_valid(photo_overlay):
			photo_overlay.queue_free()
			photo_controls.queue_free()

func take_photo() -> void:
	photo_controls.visible=false
	await RenderingServer.frame_post_draw
	var image=get_viewport().get_texture().get_image()
	var filename="WanderGarden-"+str(int(Time.get_unix_time_from_system()))+".png"
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(image.save_png_to_buffer(),filename,"image/png")
	else:
		var folder=OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)+"/WanderGarden"
		DirAccess.make_dir_recursive_absolute(folder)
		var result=image.save_png(folder+"/"+filename)
		print("PHOTO ",folder+"/"+filename," result=",result)
	photo_controls.visible=true
	photo_controls.text="照片已保存 · P 返回漫游"

func event(type: String,details: Dictionary) -> void:
	events.append({"time":elapsed,"type":type,"details":details})
	if qa:
		print("EVENT ",JSON.stringify(events.back()))

func toast(text: String) -> void:
	if is_instance_valid(hud):
		hud.toast(text)

func chime() -> void:
	if sound and music_on and not qa:
		sound.play()

func save_payload() -> Dictionary:
	var saved_plots=[]
	for p in plots:
		saved_plots.append(p.record())
	var saved_pets=[]
	for p in pets:
		saved_pets.append({"affection":p.affection,"following":p.following,"pos":[p.position.x,p.position.z],"home":[p.home.x,p.home.z]})
	return {"version":1,"seeds":seeds,"harvest":harvest,"unlocked":unlocked,"plots":saved_plots,"pets":saved_pets,"pos":[player.position.x,player.position.z],"clock":clock,"speed":speed_index,"grid":grid,"crop_journal":discovered_crops,"pet_journal":discovered_pets,"signs":read_signs,"selected_seed":selected_seed,"world_seed":streamer.world_seed,"wild_collected":streamer.collected,"elapsed":elapsed}

func save_game() -> void:
	if qa:
		return
	var f=FileAccess.open("user://garden.tmp",FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save_payload()))
		f.close()
		var path=OS.get_user_data_dir()
		if FileAccess.file_exists("user://garden.json"):
			DirAccess.copy_absolute(path+"/garden.json",path+"/garden.backup.json")
		DirAccess.rename_absolute(path+"/garden.tmp",path+"/garden.json")

func load_game() -> void:
	if not FileAccess.file_exists("user://garden.json"):
		return
	var result=JSON.parse_string(FileAccess.get_file_as_string("user://garden.json"))
	if not result is Dictionary or int(result.get("version",0))!=1:
		toast("旧存档暂时无法读取，已保留原文件。")
		return
	restore_payload(result)

func restore_payload(result: Dictionary) -> void:
	for key in ["seeds","harvest","crop_journal","pet_journal","pets"]:
		if not result.has(key) or not result[key] is Array or result[key].size()!=5:
			return
	seeds=result.seeds
	harvest=result.harvest
	discovered_crops=result.crop_journal
	discovered_pets=result.pet_journal
	unlocked=clampi(int(result.get("unlocked",0)),0,4)
	speed_index=clampi(int(result.get("speed",1)),0,2)
	selected_seed=clampi(int(result.get("selected_seed",0)),0,4)
	grid=bool(result.get("grid",false))
	clock=float(result.get("clock",0.2))
	elapsed=float(result.get("elapsed",0))
	streamer.world_seed=int(result.get("world_seed",348802))
	streamer.noise.seed=streamer.world_seed
	streamer.collected=result.get("wild_collected",{})
	read_signs=result.get("signs",[])
	var pos=result.get("pos",[0,9])
	player.position=Vector3(float(pos[0]),0.2,clampf(float(pos[1]),-72.0*unlocked-25,25))
	player.position.y=maxf(0.2,streamer.height_at(player.position)+0.2)
	streamer.request_neighborhood(streamer.cell_at(player.position))
	# Restore the current terrain immediately, before the first physics step.
	for job in streamer.jobs:
		if int(job.phase)==0 and job.cell==streamer.cell_at(player.position):
			streamer.build_terrain(job)
			job.phase=1
	region=data.region_at(player.position)
	for i in range(unlocked):
		world.open_gate(i)
	for p in plots:
		p.free()
	plots.clear()
	for rec in result.get("plots",[]):
		var p=add_plot(Vector3(float(rec.x),float(rec.get("y",0.03)),float(rec.z)))
		p.crop=clampi(int(rec.crop),-1,4)
		p.growth=clampf(float(rec.growth),0,1)
		p.water=clampf(float(rec.water),0,1)
		p.loosened=bool(rec.get("loosened",false))
		p.refresh()
	var follow_taken=false
	for i in range(5):
		var rec=result.pets[i]
		pets[i].affection=clampi(int(rec.affection),0,100)
		pets[i].following=bool(rec.following) and not follow_taken and pets[i].affection>=100
		follow_taken=follow_taken or pets[i].following
		pets[i].position=Vector3(float(rec.pos[0]),0.2,float(rec.pos[1]))
		pets[i].home=Vector3(float(rec.home[0]),0,float(rec.home[1]))
		pets[i].trail.clear()
		if pets[i].following:
			# Reconnect a saved companion inside the player's loaded neighborhood.
			# Resting companions retain their original saved location.
			pets[i].position=player.position+Vector3(0.9,0.05,0.9)

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST and world_ready:
		save_game()

