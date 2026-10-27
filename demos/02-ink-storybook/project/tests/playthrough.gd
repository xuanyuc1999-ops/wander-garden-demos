extends Node
# Real gameplay actions through Godot's input queue. No inventory/unlock injection.
# --fixed-fps may accelerate wall time; this is NOT a performance benchmark.
var game: Node
var checks: Array=[]
var errors=0
var max_pet_gap=0.0

func check(ok: bool,name: String,details: Variant="") -> void:
	checks.append({"name":name,"pass":ok,"details":details})
	if not ok:
		errors+=1
	print("CHECK ",name," ", "PASS" if ok else "FAIL"," ",details)

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func key(code: int) -> void:
	var ev=InputEventKey.new()
	ev.physical_keycode=code
	ev.pressed=true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	ev=InputEventKey.new()
	ev.physical_keycode=code
	ev.pressed=false
	Input.parse_input_event(ev)
	await get_tree().process_frame

func stop() -> void:
	for action in ["forward","back","left","right","run"]:
		Input.action_release(action)

func walk(destination: Vector3, tolerance: float=0.3, budget: float=35.0) -> bool:
	var timer=0.0
	while timer<budget:
		var delta=destination-game.player.position
		delta.y=0
		if delta.length()<tolerance:
			stop()
			await wait(0.15)
			return true
		var camera_delta=game.player.pivot.global_basis.inverse()*delta
		for pair in [["right",camera_delta.x],["left",-camera_delta.x],["back",camera_delta.z],["forward",-camera_delta.z]]:
			if pair[1]>0.13:
				Input.action_press(pair[0],minf(1.0,pair[1]))
			else:
				Input.action_release(pair[0])
		Input.action_press("run")
		await get_tree().physics_frame
		timer+=get_physics_process_delta_time()
	stop()
	check(false,"walk_reachable",{"destination":str(destination),"actual":str(game.player.position)})
	return false

func finish() -> void:
	stop()
	var report={"mode":"engine_input_playthrough","injected_state":false,"time_basis":"simulation seconds, not benchmark","checks":checks,"failures":errors,"events":game.events,"simulated_seconds":game.elapsed,"engine":Engine.get_version_info()}
	var path="user://qa-report.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="):
			path=arg.trim_prefix("--report=")
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("QA_COMPLETE failures=",errors," report=",path)
	get_tree().quit(1 if errors else 0)

func _ready() -> void:
	await wait(0.3)
	await key(KEY_ENTER)
	check(game.started and game.player.enabled,"enter_starts_normal_entry")
	await key(KEY_T)
	await key(KEY_T)
	check(game.speed_index==0,"player_selects_fast_growth")
	await walk(Vector3(0,0,-33.5))
	await key(KEY_E)
	check(game.unlocked==0,"empty_harvest_cannot_unlock_gate")
	Input.action_press("forward")
	Input.action_press("run")
	await wait(1.0)
	stop()
	check(game.player.position.z>-36,"locked_gate_blocks_walk")
	for i in range(5):
		var c=game.data.center(i)
		if not await walk(c+Vector3(0,0,4)):
			finish()
			return
		await walk(c+Vector3(-3.0,0,4))
		await key(KEY_E)
		check(game.seeds[i]>=3,"local_seed_pickup_"+str(i))
		await walk(c+Vector3(-4,0,-3))
		var previous=game.plots.size()
		await key(KEY_F)
		check(game.plots.size()==previous+1,"cultivate_region_"+str(i))
		if game.plots.size()==previous:
			finish()
			return
		var plot=game.plots.back()
		await key(KEY_F)
		check(game.plots.size()==previous+1,"overlap_rejected_"+str(i))
		for cycle in range(2):
			await key(KEY_E)
			check(plot.crop==i,"sow_"+str(i)+"_"+str(cycle))
			var before=plot.growth
			await wait(0.6)
			check(is_equal_approx(before,plot.growth),"dry_crop_pauses_"+str(i)+"_"+str(cycle))
			await key(KEY_E)
			check(plot.water>0,"water_"+str(i)+"_"+str(cycle))
			await wait(12.3)
			check(plot.growth>=1,"four_stage_growth_"+str(i)+"_"+str(cycle))
			var count=game.harvest[i]
			await key(KEY_E)
			check(game.harvest[i]==count+3 and plot.crop==-1,"harvest_inventory_"+str(i)+"_"+str(cycle))
		# Move away from the farm so the pet is the nearest interactable.
		await walk(c+Vector3(0,0,0))
		for count in range(2):
			await walk(game.pets[i].position+Vector3(0,0,0.7),0.5)
			await key(KEY_E)
			await wait(1.9)
		check(game.pets[i].affection==100,"pet_affection_"+str(i))
		check(game.pets[i].following,"pet_follow_"+str(i))
		var followers=0
		for p in game.pets:
			if p.following:
				followers+=1
		check(followers==1,"single_companion_"+str(i))
		if i<4:
			await walk(c+Vector3(0,0,-33.3))
			await key(KEY_E)
			check(game.unlocked==i+1,"gate_unlock_"+str(i))
			if not await walk(game.data.center(i+1)+Vector3(0,0,15)):
				finish()
				return
			await wait(3)
			var gap=game.pets[i].position.distance_to(game.player.position)
			check(gap<5,"companion_crosses_connector_"+str(i),gap)
			check(game.region==i+1,"walk_into_region_"+str(i+1))
	# Zero-pressure idle: resources and affection must survive 5 simulation minutes.
	await walk(game.data.center(4)+Vector3(0,0,-22))
	Input.action_press("forward")
	await wait(1.4)
	stop()
	check(game.player.position.z> -312 and game.player.position.z< -309,"star_resting_landmark_collision")
	await walk(game.data.center(4))
	var harvest_before=game.harvest.duplicate()
	var affection_before=game.pets[4].affection
	await wait(301)
	check(game.harvest==harvest_before and game.pets[4].affection==affection_before,"five_minute_idle_no_loss")
	check(game.region==4 and game.sunlight.light_energy<0.5,"star_valley_permanent_night")
	# All unlocked corridors are bidirectional with ordinary movement.
	for i in range(3,-1,-1):
		if not await walk(game.data.center(i)+Vector3(0,0,0),0.6,40):
			finish()
			return
	check(game.region==0,"return_walk_across_all_five_regions")
	# Follow the actual walking path around the hut instead of steering through it.
	await walk(Vector3(-7,0,7))
	await walk(Vector3(-7,0,15))
	await walk(Vector3(-17,0,15))
	await walk(Vector3(-17,0,7))
	await wait(4)
	var pet_collisions=[]
	for n in range(game.pets[4].get_slide_collision_count()):
		var hit=game.pets[4].get_slide_collision(n)
		pet_collisions.append({"normal":str(hit.get_normal()),"point":str(hit.get_position()),"body":str(hit.get_collider().get_path()),"body_position":str(hit.get_collider().global_position)})
	check(game.pets[4].position.distance_to(game.player.position)<4,"companion_follows_around_hut",{"pet":str(game.pets[4].position),"player":str(game.player.position),"trail":game.pets[4].trail.size(),"next":str(game.pets[4].target),"following":game.pets[4].following,"velocity":str(game.pets[4].velocity),"collisions":pet_collisions})
	await walk(Vector3(-7,0,7))
	await walk(Vector3(-7,0,11))
	var mouse=InputEventMouseButton.new()
	mouse.button_index=MOUSE_BUTTON_RIGHT
	mouse.pressed=true
	Input.parse_input_event(mouse)
	var camera_clear=true
	for orbit in range(8):
		var motion=InputEventMouseMotion.new()
		motion.relative=Vector2((PI/4.0)/0.003,0)
		Input.parse_input_event(motion)
		await wait(0.18)
		var query=PhysicsShapeQueryParameters3D.new()
		var sphere=SphereShape3D.new()
		sphere.radius=0.08
		query.shape=sphere
		query.transform=Transform3D(Basis.IDENTITY,game.player.camera.global_position)
		query.collision_mask=1
		query.exclude=[game.player.get_rid()]
		camera_clear=camera_clear and game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
	mouse=InputEventMouseButton.new()
	mouse.button_index=MOUSE_BUTTON_RIGHT
	mouse.pressed=false
	Input.parse_input_event(mouse)
	check(camera_clear,"camera_full_orbit_near_solid_hut")
	await walk(Vector3(-7,0,0))
	await walk(Vector3(0,0,-10))
	await walk(Vector3(48,0,-10))
	await wait(0.5)
	check(game.player.position.y> -2,"procedural_terrain_supports_player")
	check(game.streamer.chunks.size()<=9,"chunk_3x3_budget")
	var signature=game.streamer.signature(Vector2i(1,-1))
	var resource_id="348802:1:-1"
	await key(KEY_E)
	check(game.streamer.collected.has(resource_id),"procedural_resource_collect")
	await key(KEY_Q)
	var nplots=game.plots.size()
	await key(KEY_F)
	check(game.plots.size()==nplots+1,"peripheral_planting_supported")
	var persistent_plot=game.plots.back()
	await key(KEY_E)
	var plot_position=persistent_plot.position
	await walk(Vector3(160,0,-10),0.5,35)
	await wait(0.5)
	check(not game.streamer.chunks.has(Vector2i(1,-1)),"distant_chunk_actually_unloaded")
	check(is_instance_valid(persistent_plot) and persistent_plot.position==plot_position,"planted_state_survives_unload")
	await walk(Vector3(48,0,-10),0.5,35)
	await wait(0.5)
	check(game.streamer.signature(Vector2i(1,-1))==signature,"terrain_reloads_deterministically")
	check(persistent_plot.crop==0 and persistent_plot.growth==0,"dry_peripheral_crop_survives_trip")
	check(game.streamer.collected.has(resource_id) and not game.streamer.pickup_nodes[resource_id].node.visible,"resource_cooldown_survives_reload")
	await key(KEY_E)
	await wait(12.3)
	check(persistent_plot.growth>=1,"peripheral_growth_after_reload")
	await key(KEY_E)
	await walk(Vector3(48,0,-25))
	var toward_edge=game.player.pivot.global_basis.inverse()*Vector3(0,0,-1)
	for pair in [["right",toward_edge.x],["left",-toward_edge.x],["back",toward_edge.z],["forward",-toward_edge.z]]:
		if pair[1]>0:
			Input.action_press(pair[0],pair[1])
	Input.action_press("run")
	await wait(1.0)
	stop()
	check(game.player.position.z> -28,"peripheral_canyon_prevents_gate_bypass")
	await key(KEY_ESCAPE)
	var before_clock=game.clock
	await wait(0.3)
	check(game.paused and game.clock==before_clock,"pause_stops_clock")
	await key(KEY_ESCAPE)
	check(not game.paused and game.player.enabled,"pause_resume_input")
	var payload=game.save_payload()
	var copied=JSON.parse_string(JSON.stringify(payload))
	game.restore_payload(copied)
	check(game.unlocked==4 and game.plots.size()==6 and game.pets[4].affection==100 and game.pets[4].position.distance_to(game.player.position)<2,"save_json_restore_roundtrip")
	check(game.streamer.collected.has(resource_id),"resource_cooldown_in_save")
	check(game.streamer.peak_chunks<=9 and game.streamer.unloaded_count>0,"chunk_lifecycle_bounded",game.streamer.stats())
	check(game.discovered_crops.count(true)==5 and game.discovered_pets.count(true)==5,"journal_five_crops_five_pets")
	check(game.seeds.all(func(v): return v>=0) and game.harvest.all(func(v): return v>=0),"inventory_nonnegative")
	finish()
