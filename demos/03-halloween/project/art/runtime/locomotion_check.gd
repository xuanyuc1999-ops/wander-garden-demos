extends "res://tests/playthrough.gd"
func _ready() -> void:
	await wait(.3)
	await key(KEY_ENTER)
	var legs=game.character_skeleton
	var start=game.player.global_position
	Input.action_press("forward")
	await wait(1.2)
	check(game.current_clip==game.animation_map.Walk_Loop,"walking_clip_active")
	check(absf(Vector2(game.player.velocity.x,game.player.velocity.z).length()-game.player.walk_speed)<.02,"walking_reaches_requested_speed")
	Input.action_press("run")
	await wait(1.2)
	check(game.current_clip==game.animation_map.Run_Loop,"distinct_running_clip_active")
	check(absf(Vector2(game.player.velocity.x,game.player.velocity.z).length()-game.player.run_speed)<.02,"running_reaches_requested_speed")
	var release=game.player.global_position
	stop()
	var frames=0
	while Vector2(game.player.velocity.x,game.player.velocity.z).length()>.02 and frames<120:
		await get_tree().physics_frame
		frames+=1
	var distance=Vector2(game.player.global_position.x-release.x,game.player.global_position.z-release.z).length()
	var duration=frames*get_physics_process_delta_time()
	check(true,"measured_release_braking",{"distance_m":distance,"duration_seconds":duration})
	if not "--locomotion-baseline" in OS.get_cmdline_user_args():
		check(distance<.75,"no_long_stop_slide",distance)
		check(duration<.3,"prompt_release_braking",duration)
	await wait(.35)
	check(game.current_clip==game.animation_map.Idle_Loop,"idle_after_braking")
	check(game.player.global_position.y>-.5,"capsule_stays_grounded")
	await key(KEY_ESCAPE)
	var pos=game.animation_player.current_animation_position
	await wait(.25)
	check(is_equal_approx(pos,game.animation_player.current_animation_position),"pause_holds_animation")
	await key(KEY_ESCAPE)
	Input.action_press("back")
	await wait(.6)
	check(game.player.velocity.z>0,"reverse_movement_responsive")
	stop()
	await wait(.4)
	check(game.current_clip==game.animation_map.Idle_Loop,"reverse_stop_returns_idle")
	finish()
