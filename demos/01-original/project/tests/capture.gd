extends Node
# VISUAL PROBE ONLY: teleports camera/player and injects example crop states.
# Never counted as input-playthrough evidence.
var game: Node
func _ready() -> void:
	var folder="user://screens"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			folder=arg.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(folder)
	await get_tree().create_timer(1.0).timeout
	game.begin()
	game.hud.toast_time=0
	for i in range(5):
		game.player.position=game.data.center(i)+Vector3(0,0.2,10)
		game.player.pivot.rotation.y=0.20
		game.player.arm.spring_length=11
		game.player.arm.rotation.x=-0.50
		game.selected_seed=i
		var plot=game.add_plot(game.data.center(i)+Vector3(-3,0.03,3))
		plot.crop=i
		plot.growth=1
		plot.water=1
		plot.refresh()
		await get_tree().create_timer(2.0).timeout
		game.hud.toast_time=0
		game.hud.toast_label.modulate.a=0
		RenderingServer.force_draw()
		await RenderingServer.frame_post_draw
		var image=get_viewport().get_texture().get_image()
		image.save_png(folder+"/"+str(i)+"-"+game.data.REGIONS[i].id+".png")
		print("CAPTURED ",i)
	game.player.position=Vector3(0,0.2,-307)
	game.player.pivot.rotation.y=0
	game.player.arm.spring_length=7.4
	game.player.arm.rotation.x=-0.40
	await get_tree().create_timer(1.5).timeout
	game.hud.toast_time=0
	game.hud.toast_label.modulate.a=0
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(folder+"/6-star-resting-place.png")
	game.player.position=Vector3(48,game.streamer.height_at(Vector3(48,0,-10))+0.3,-10)
	game.player.pivot.rotation.y=-PI/2
	game.player.arm.spring_length=10
	await get_tree().create_timer(2.0).timeout
	game.hud.toast_time=0
	game.hud.toast_label.modulate.a=0
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(folder+"/5-procedural-outskirts.png")
	print("CHUNK_STATS ",JSON.stringify(game.streamer.stats()))
	get_tree().quit()
