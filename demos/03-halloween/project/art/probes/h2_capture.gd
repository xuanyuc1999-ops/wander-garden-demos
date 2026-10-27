extends Node
# Explicit visual setup; not normal-input evidence.
var game: Node
func _ready() -> void:
	var folder="user://h2-probe"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			folder=arg.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(folder)
	await get_tree().create_timer(1.0).timeout
	game.begin()
	var plot=game.add_plot(Vector3(-4,0.03,1.5))
	plot.crop=0
	plot.growth=1
	plot.water=1
	plot.refresh()
	await get_tree().create_timer(1.8).timeout
	await shot(folder+"/01-entry.png")
	var entry_projection=game.projected_cottage()
	if game.proposal:
		game.player.position=Vector3(-11,0.2,-10)
		await get_tree().create_timer(1.2).timeout
		await shot(folder+"/02-porch.png")
		game.player.position=Vector3(1,0.2,-29)
		await get_tree().create_timer(1.2).timeout
		await shot(folder+"/03-connector.png")
		game.player.pivot.rotation.y=PI
		await get_tree().create_timer(1.2).timeout
		await shot(folder+"/04-look-back.png")
	var file=FileAccess.open(folder+"/measurements.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"kind":"visual_probe_with_position_crop_state_setup","proposal":game.proposal,"changes":game.changes,"entry_cottage_projection":entry_projection,"chunks":game.streamer.stats()},"\t"))
	file.close()
	get_tree().quit()

func shot(path: String) -> void:
	game.hud.toast_time=0
	game.hud.toast_label.modulate.a=0
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("H2_CAPTURE ",path)
