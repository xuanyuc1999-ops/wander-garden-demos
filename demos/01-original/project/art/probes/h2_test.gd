extends "res://tests/playthrough.gd"
# Uses unchanged key/walk drivers from the baseline, with proposal-specific checks.
var mouse_radians_per_injected_pixel=0.003
func _ready() -> void:
	await wait(0.4)
	await key(KEY_ENTER)
	check(game.started and game.player.enabled,"h2_entry_ordinary_input")
	await wait(0.4)
	check(game.projected_cottage().within_frame,"cottage_complete_in_entry_camera",game.projected_cottage())
	check(game.cottage.position.distance_to(Vector3(-11,0,-18))<0.01,"cottage_proposed_position")
	check(game.can_farm(Vector3(-12,0.03,11)),"old_cottage_lawn_becomes_plantable")
	check(not game.can_farm(Vector3(-11,0.03,-18)),"new_cottage_excludes_farming")
	var turn_press=InputEventMouseButton.new()
	turn_press.button_index=MOUSE_BUTTON_RIGHT
	turn_press.pressed=true
	Input.parse_input_event(turn_press)
	# Input.parse_input_event mouse deltas are transformed by the root stretch
	# in headless mode. Calibrate using observed response, not presumed pixels.
	var yaw_before=game.player.pivot.rotation.y
	var calibration=InputEventMouseMotion.new()
	calibration.relative=Vector2(1,0)
	Input.parse_input_event(calibration)
	await wait(0.05)
	mouse_radians_per_injected_pixel=absf(game.player.pivot.rotation.y-yaw_before)
	assert(mouse_radians_per_injected_pixel>0.000001)
	calibration=InputEventMouseMotion.new()
	calibration.relative=Vector2(-1,0)
	Input.parse_input_event(calibration)
	await wait(0.05)
	var last_fog=game.env.fog_depth_end
	var maximum_step=0.0
	var samples=[]
	var finite=true
	for n in range(72):
		var turn=InputEventMouseMotion.new()
		turn.relative=Vector2(deg_to_rad(5)/mouse_radians_per_injected_pixel,0)
		Input.parse_input_event(turn)
		await wait(0.05)
		var fog_value=game.env.fog_depth_end
		samples.append({"n":n,"yaw":game.player.pivot.rotation.y,"fog_end":fog_value,"base":game.streamer.fog_limit(game.player.camera),"camera":str(game.player.camera.global_position)})
		finite=finite and is_finite(fog_value) and fog_value>=22 and fog_value<=70.01
		maximum_step=maxf(maximum_step,absf(fog_value-last_fog))
		last_fog=fog_value
	var turn_release=InputEventMouseButton.new()
	turn_release.button_index=MOUSE_BUTTON_RIGHT
	turn_release.pressed=false
	Input.parse_input_event(turn_release)
	check(finite and maximum_step<7,"fog_rotation_sample_continuity",{"yaw_step_degrees":5,"measured_mouse_radians_per_pixel":mouse_radians_per_injected_pixel,"sample_interval_seconds":0.05,"maximum_fog_end_step_m":maximum_step,"samples":samples})
	if "--h2-fog-only" in OS.get_cmdline_user_args():
		finish()
		return
	await key(KEY_T)
	await key(KEY_T)
	await walk(Vector3(-3,0,4))
	await key(KEY_E)
	await walk(Vector3(-4,0,-3))
	await key(KEY_F)
	check(game.plots.size()==1,"baseline_planting_location_unchanged")
	if game.plots.is_empty():
		finish()
		return
	for cycle in range(2):
		await key(KEY_E)
		await key(KEY_E)
		await wait(12.3)
		check(game.plots[0].growth>=1,"h2_growth_"+str(cycle))
		await key(KEY_E)
	check(game.harvest[0]==6,"h2_harvest_inventory")
	await walk(Vector3(0,0,0))
	for cycle in range(2):
		await walk(game.pets[0].position+Vector3(0,0,0.7),0.5)
		await key(KEY_E)
		await wait(1.9)
	check(game.pets[0].following and game.pets[0].affection==100,"h2_companion_loop")
	await walk(Vector3(0,0,-10))
	await walk(Vector3(-11,0,-10))
	await walk(Vector3(-11,0,-15.2))
	check(game.player.position.z< -14.5,"porch_opening_traversable")
	Input.action_press("forward")
	await wait(1.0)
	stop()
	check(game.player.position.z> -16,"cottage_front_collision")
	await walk(Vector3(-11,0,-10))
	await walk(Vector3(-5,0,-10))
	await walk(Vector3(-5,0,-24))
	await walk(Vector3(-17.5,0,-24))
	await walk(Vector3(-17.5,0,-10))
	await wait(4)
	check(game.pets[0].position.distance_to(game.player.position)<4,"companion_around_new_cottage",str(game.pets[0].position))
	# Camera orbits around the altered collision footprint through mouse events.
	await walk(Vector3(-7.5,0,-16))
	var mouse=InputEventMouseButton.new()
	mouse.button_index=MOUSE_BUTTON_RIGHT
	mouse.pressed=true
	Input.parse_input_event(mouse)
	var clear=true
	for n in range(8):
		var motion=InputEventMouseMotion.new()
		motion.relative=Vector2((PI/4)/mouse_radians_per_injected_pixel,0)
		Input.parse_input_event(motion)
		await wait(0.2)
		var q=PhysicsShapeQueryParameters3D.new()
		var s=SphereShape3D.new()
		s.radius=0.08
		q.shape=s
		q.transform=Transform3D(Basis.IDENTITY,game.player.camera.global_position)
		q.collision_mask=1
		q.exclude=[game.player.get_rid()]
		clear=clear and game.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty()
	mouse=InputEventMouseButton.new()
	mouse.button_index=MOUSE_BUTTON_RIGHT
	mouse.pressed=false
	Input.parse_input_event(mouse)
	check(clear,"proposal_camera_orbit_clear")
	await walk(Vector3(-5,0,-10))
	await walk(Vector3(0,0,-10))
	await walk(Vector3(0,0,-33.3))
	mouse=InputEventMouseButton.new()
	mouse.button_index=MOUSE_BUTTON_RIGHT
	mouse.pressed=true
	Input.parse_input_event(mouse)
	var gate_clear=true
	for n in range(8):
		var motion=InputEventMouseMotion.new()
		motion.relative=Vector2((PI/4)/mouse_radians_per_injected_pixel,0)
		Input.parse_input_event(motion)
		await wait(0.2)
		var q=PhysicsShapeQueryParameters3D.new()
		var s=SphereShape3D.new()
		s.radius=0.08
		q.shape=s
		q.transform=Transform3D(Basis.IDENTITY,game.player.camera.global_position)
		q.collision_mask=1
		q.exclude=[game.player.get_rid()]
		gate_clear=gate_clear and game.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty()
	mouse=InputEventMouseButton.new()
	mouse.button_index=MOUSE_BUTTON_RIGHT
	mouse.pressed=false
	Input.parse_input_event(mouse)
	check(gate_clear,"gate_full_orbit_camera_clear")
	await key(KEY_E)
	check(game.unlocked==1,"h2_original_gate_unlock")
	await walk(Vector3(0,0,-57))
	await wait(3)
	check(game.region==1 and game.pets[0].position.distance_to(game.player.position)<5,"h2_connector_and_pet_crossing")
	await walk(Vector3(0,0,-10))
	await walk(Vector3(48,0,-10))
	await wait(0.5)
	var signature=game.streamer.signature(Vector2i(1,-1))
	await walk(Vector3(128,0,-10),0.5,25)
	await wait(0.4)
	check(not game.streamer.chunks.has(Vector2i(1,-1)),"h2_chunk_unload_preserved")
	await walk(Vector3(48,0,-10),0.5,25)
	await wait(0.4)
	check(game.streamer.signature(Vector2i(1,-1))==signature and game.streamer.chunks.size()<=9,"h2_stable_chunk_reload")
	finish()
