extends "res://tests/playthrough.gd"
var folder=""
var recording=false
var saving=false
var media=[]
var next_capture=0.0
var started_at=0.0
var last_clip=""
var clip_history=[]

func _process(_delta: float) -> void:
	if game.animation_player!=null and game.current_clip!=last_clip:
		last_clip=game.current_clip
		clip_history.append({"time":game.elapsed,"clip":last_clip})
	if recording and not saving and game.elapsed>=next_capture:
		saving=true
		next_capture=game.elapsed+0.20
		capture()

func capture() -> void:
	# The desktop may occlude this test window. Force an actual render instead
	# of waiting indefinitely for the next presentation while simulation advances.
	RenderingServer.force_draw()
	var filename="frame-%04d.png" % media.size()
	get_viewport().get_texture().get_image().save_png(folder+"/"+filename)
	media.append({"file":filename,"time_seconds":game.elapsed-started_at,
		"wall_msec":Time.get_ticks_msec(),"clip":game.current_clip,
		"player":str(game.player.position)})
	saving=false

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):folder=arg.trim_prefix("--capture-dir=")
	assert(not folder.is_empty())
	DirAccess.make_dir_recursive_absolute(folder)
	await wait(.5)
	await key(KEY_ENTER)
	await wait(.4)
	check(game.animation_map.size()==5,"five_named_animation_bindings",game.animation_map)
	check(game.current_clip=="Idle","idle_from_still_input")
	Input.action_press("forward")
	await wait(.3)
	check(game.current_clip=="Walk","walk_from_movement_input")
	stop();await wait(.5)
	check(game.current_clip=="Idle","stop_returns_idle")
	await key(KEY_ESCAPE)
	await wait(.1)
	var paused_position=game.animation_player.current_animation_position
	await wait(.35)
	check(game.paused and is_equal_approx(paused_position,game.animation_player.current_animation_position),"pause_freezes_animation")
	await key(KEY_ESCAPE)
	await wait(.2)
	check(not game.paused and game.animation_player.speed_scale>0,"resume_restarts_animation")
	await key(KEY_T);await key(KEY_T)
	await walk(Vector3(-3,0,4))
	await key(KEY_E)
	await wait(1.3)
	await walk(Vector3(-4,0,-3))
	started_at=game.elapsed
	next_capture=game.elapsed
	recording=true
	await wait(.25)
	await key(KEY_F)
	await wait(1.3)
	check(game.plots.size()==1,"cultivation_with_visible_player")
	await key(KEY_E)
	await wait(1.3)
	check(game.plots[0].crop==0,"sowing_with_visible_player")
	await key(KEY_E)
	await wait(.3)
	check(game.current_clip=="Farm_Watering","water_event_selects_watering")
	check(is_equal_approx(game.animation_player.speed_scale,1.0),"watering_not_inherited_run_speed")
	check(game.player.arm.rotation.x<-.80,"planting_view_exposes_crop_surface")
	await wait(12.3)
	await key(KEY_E)
	await wait(1.3)
	check(game.harvest[0]==3,"harvest_with_visible_player")
	var manual_press=InputEventMouseButton.new()
	manual_press.button_index=MOUSE_BUTTON_RIGHT;manual_press.pressed=true
	Input.parse_input_event(manual_press)
	var manual_move=InputEventMouseMotion.new()
	manual_move.relative=Vector2(0,-10);Input.parse_input_event(manual_move)
	await wait(.9)
	check(game.manual_plot_camera and absf(game.player.arm.rotation.x-game.player.orbit_pitch)<.04,"manual_look_overrides_planting_camera")
	manual_move=InputEventMouseMotion.new()
	manual_move.relative=Vector2(0,10);Input.parse_input_event(manual_move)
	manual_press=InputEventMouseButton.new()
	manual_press.button_index=MOUSE_BUTTON_RIGHT;manual_press.pressed=false
	Input.parse_input_event(manual_press)
	await walk(Vector3(0,0,0))
	var mouse=InputEventMouseButton.new()
	mouse.button_index=MOUSE_BUTTON_RIGHT
	mouse.pressed=true
	Input.parse_input_event(mouse)
	var orbit=InputEventMouseMotion.new()
	orbit.relative=Vector2(-280,0)
	Input.parse_input_event(orbit)
	await wait(.2)
	mouse=InputEventMouseButton.new()
	mouse.button_index=MOUSE_BUTTON_RIGHT
	mouse.pressed=false
	Input.parse_input_event(mouse)
	await walk(game.pets[0].position+Vector3(0,0,1.5),.35)
	await key(KEY_E)
	await wait(.3)
	check(game.current_clip=="Interact" and game.pets[0].affection==50,"pet_feeding_and_animation")
	await wait(1.6)
	if "--complete-proof" in OS.get_cmdline_user_args():
		await walk(Vector3(0,0,-10))
		await walk(Vector3(0,0,-33.3))
		await key(KEY_E)
		await wait(1.3)
		check(game.unlocked==1,"generated_arch_gate_unlock")
		var clear_x=[]
		var intended_span_clear=true
		for n in range(-40,41):
			var q=PhysicsShapeQueryParameters3D.new()
			var shape=CapsuleShape3D.new();shape.radius=.31;shape.height=1.72
			q.shape=shape
			q.transform=Transform3D(Basis.IDENTITY,Vector3(n*.1,.96,-30))
			q.motion=Vector3(0,0,-12)
			q.collision_mask=1
			q.exclude=[game.player.get_rid()]
			var fractions=game.get_world_3d().direct_space_state.cast_motion(q)
			if fractions[0]>.999:clear_x.append(n*.1)
			elif absi(n)<=29:intended_span_clear=false
		check(clear_x.has(0.0),"arch_center_capsule_clear",clear_x)
		check(intended_span_clear,"arch_6_4m_effective_opening",{"capsule_radius":.31,"required_center_range":[-2.9,2.9],"clear_x":clear_x})
		await walk(Vector3(0,0,-48))
		await wait(.5)
		check(game.player.position.z< -47,"walk_through_actual_arch_geometry")
	recording=false
	while saving:await get_tree().process_frame
	var measured={}
	for id in game.live_assets:
		measured[id]={"triangles":game.Models.triangles(game.live_assets[id]),"source":game.live_assets[id].get_meta("source")}
	if not game.crop_asset_metrics.is_empty():measured["carrot"]=game.crop_asset_metrics
	var f=FileAccess.open(folder+"/continuous-input.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"mode":"ordinary engine input with native player-camera frames",
		"injected_state":false,"assets":measured,"checks":checks,"failures":errors,
		"camera_id":"player-camera","media":media,"events":game.events,
		"clip_history":clip_history,"engine":Engine.get_version_info()},"\t"));f.close()
	finish()
