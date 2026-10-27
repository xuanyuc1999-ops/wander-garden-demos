extends Node
var game: Node
func _ready() -> void:
	var folder="user://halloween-preview"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):folder=arg.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(folder)
	await get_tree().create_timer(.7).timeout
	game.begin()
	game.player.position=Vector3(0,.1,12)
	game.player.pivot.rotation.y=PI
	game.player.arm.spring_length=3.5
	game.player.orbit_pitch=-.12
	game.player.camera.fov=45
	await get_tree().create_timer(1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(folder+"/skeleton-front.png")
	game.player.pivot.rotation.y=PI/2
	await get_tree().create_timer(.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(folder+"/skeleton-side.png")
	Input.action_press("forward")
	await get_tree().create_timer(.45).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(folder+"/skeleton-walk.png")
	Input.action_press("run")
	await get_tree().create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(folder+"/skeleton-jog.png")
	Input.action_release("forward");Input.action_release("run")
	get_tree().quit()
