extends Node
var game: Node
func _ready() -> void:
	var folder="user://biome-capture"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):folder=arg.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(folder)
	await get_tree().create_timer(.5).timeout
	game.begin()
	game.player.enabled=false
	game.set_process_unhandled_input(false)
	game.player.arm.spring_length=8
	game.player.orbit_pitch=-.28
	game.player.camera.fov=52
	var frames=[]
	for i in range(5):
		game.player.position=game.data.center(i)+Vector3(0,.1,16)
		game.player.velocity=Vector3.ZERO
		game.player.pivot.rotation.y=0
		await get_tree().create_timer(2.0).timeout
		await RenderingServer.frame_post_draw
		var filename=str(i)+"-"+game.data.REGIONS[i].id+".png"
		get_viewport().get_texture().get_image().save_png(folder+"/"+filename)
		frames.append({"region":i,"image":filename,"assets":game.biome_art.asset_counts})
	var f=FileAccess.open(folder+"/capture.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"visual_staging":true,"not_gameplay_proof":true,"frames":frames},"\t"));f.close()
	get_tree().quit()
