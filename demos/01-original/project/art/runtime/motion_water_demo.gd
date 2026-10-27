extends Node
# Visual demonstration with explicit staging, then ordinary movement input.
# Offline24fps capture is not a performance benchmark.
var game: Node
var folder=""
var frame=0
var recording=false
var shot_records=[]
func _process(_delta: float) -> void:
	if not recording:return
	RenderingServer.force_draw()
	var file="frame-%05d.jpg" % frame
	get_viewport().get_texture().get_image().save_jpg(folder+"/"+file,.9)
	shot_records.append({"frame":frame,"time":frame/24.0,"hero_clip":game.current_clip,
		"rabbit_clip":game.rabbit_motion.current,"player":str(game.player.position)})
	frame+=1
func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):folder=arg.trim_prefix("--capture-dir=")
	assert(not folder.is_empty())
	DirAccess.make_dir_recursive_absolute(folder)
	await get_tree().create_timer(.5).timeout
	game.begin()
	game.player.position=Vector3(-4,.1,8)
	game.player.arm.spring_length=5.5
	game.player.orbit_pitch=-.25;game.player.arm.rotation.x=-.25
	game.player.camera.fov=42
	await get_tree().create_timer(.5).timeout
	recording=true
	await get_tree().create_timer(1).timeout
	Input.action_press("right")
	await get_tree().create_timer(3).timeout
	Input.action_release("right")
	await get_tree().create_timer(1).timeout
	Input.action_press("right");Input.action_press("run")
	await get_tree().create_timer(1.2).timeout
	Input.action_release("right");Input.action_release("run")
	await get_tree().create_timer(.8).timeout
	recording=false
	# Stage a followed companion for a close view of its original navigation AI.
	game.player.position=Vector3(-4,.1,0)
	game.player.pivot.rotation.y=0
	game.player.camera.fov=48;game.player.arm.spring_length=6.5
	game.pets[0].position=Vector3(-2,.1,1)
	game.pets[0].affection=100;game.pets[0].following=true;game.pets[0].trail.clear()
	await get_tree().create_timer(.7).timeout
	recording=true
	Input.action_press("right")
	await get_tree().create_timer(4).timeout
	Input.action_release("right")
	await get_tree().create_timer(1.5).timeout
	game.pets[0].state="eat";game.pets[0].timer=2.3
	await get_tree().create_timer(2).timeout
	recording=false
	# Shore view: same existing safe floor, actual reflected shared3D world.
	game.player.position=Vector3(7,.1,5)
	game.player.pivot.rotation.y=-PI/2
	game.player.orbit_pitch=-.35;game.player.arm.rotation.x=-.35
	game.player.arm.spring_length=5.8;game.player.camera.fov=52
	await get_tree().create_timer(.6).timeout
	recording=true
	await get_tree().create_timer(3).timeout
	game.player.pivot.rotation.y=-.75*PI
	await get_tree().create_timer(2).timeout
	recording=false
	var f=FileAccess.open(folder+"/capture.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"fps":24,"visual_staging":true,"ordinary_movement_input":true,
		"not_gameplay_proof":"Companion affection and locations staged for presentation",
		"frames":shot_records,"reflection_resolution":str(game.lake_visual.reflection_viewport.size)},"\t"));f.close()
	get_tree().quit()
