extends Node
var game: Node
func _ready() -> void:
	var folder="user://meadow-sample"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):folder=arg.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(folder)
	await get_tree().create_timer(1).timeout
	game.begin()
	await get_tree().create_timer(1).timeout
	await shot(folder+"/01-entry.png")
	game.player.position=Vector3(0,0.1,2)
	await get_tree().create_timer(0.8).timeout
	await shot(folder+"/02-interactions.png")
	game.player.position=Vector3(-11,0.1,-10)
	await get_tree().create_timer(0.8).timeout
	await shot(folder+"/03-home.png")
	var measured={}
	for id in game.live_assets:
		measured[id]={"triangles":game.Models.triangles(game.live_assets[id]),"source":game.live_assets[id].get_meta("source")}
	var f=FileAccess.open(folder+"/sample-state.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"mode":"visual probe only","assets":measured,"animation_map":game.animation_map,"main_camera":game.player.camera.get_path()},"\t"));f.close()
	get_tree().quit()

func shot(path: String) -> void:
	game.hud.toast_time=0;game.hud.toast_label.modulate.a=0
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
