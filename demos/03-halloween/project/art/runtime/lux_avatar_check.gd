extends "res://tests/playthrough.gd"
func _ready() -> void:
	await wait(.3)
	var adapter=game.lux_avatar
	var ap=game.animation_player
	check(game.character_skeleton.get_bone_count()==52,"supplied_52_bone_skin")
	check(game.Models.triangles(game.live_assets.traveler)==19294,"supplied_geometry_preserved")
	check(game.live_assets.traveler.get_meta("source").ends_with("traveler-lux-presets.glb"),"supplied_file_is_runtime_avatar")
	check(game.hand_bone>=0,"right_hand_attachment_resolved")
	check(absf(adapter.source_duration-1.333333373)<.00001,"original_clip_duration_preserved")
	check(absf(adapter.native_walk_speed-.81813)<.002,"speed_matches_original_root_displacement",adapter.native_walk_speed)
	var worst_seam=0.0
	var source_travel=0.0
	for t in range(adapter.walk_animation.get_track_count()):
		if adapter.walk_animation.track_get_type(t)==Animation.TYPE_POSITION_3D:
			var clip=adapter.walk_animation
			var first: Vector3=clip.track_get_key_value(t,0)
			var last: Vector3=clip.track_get_key_value(t,clip.track_get_key_count(t)-1)
			worst_seam=maxf(worst_seam,first.distance_to(last))
			source_travel=(adapter.source_animation.track_get_key_value(t,0) as Vector3).distance_to(adapter.source_animation.track_get_key_value(t,adapter.source_animation.track_get_key_count(t)-1))
	check(worst_seam<.00001,"in_place_loop_no_root_snap",worst_seam)
	check(source_travel>.07,"source_animation_remains_unmodified",source_travel)
	await key(KEY_ENTER)
	var start=game.player.position
	Input.action_press("forward")
	await wait(2.0)
	check(game.current_clip==game.animation_map.Walk_Loop,"walking_uses_supplied_clip")
	check(absf(ap.speed_scale-game.player.walk_speed/adapter.native_walk_speed)<.03,"walk_cadence_matches_new_move_speed",ap.speed_scale)
	check(absf((game.player.position-start).length()-game.player.walk_speed*2)<.20,"collision_body_matches_visual_stride")
	Input.action_press("run")
	await wait(.8)
	check(game.current_clip==game.animation_map.Run_Loop,"shift_uses_distinct_lux_jog")
	check(game.animation_map.Run_Loop!=game.animation_map.Walk_Loop,"walk_and_jog_are_separate_clips")
	check(absf(ap.speed_scale-game.player.run_speed/adapter.native_run_speed)<.03,"jog_pace_matches_source_stride",ap.speed_scale)
	check(game.animation_map.Idle_Loop=="LuxPresets/Idle_Loop","lux_idle_replaces_averaged_pose")
	stop()
	await wait(.8)
	check(game.current_clip==game.animation_map.Idle_Loop,"release_returns_to_lux_idle")
	await key(KEY_ESCAPE)
	await wait(.2)
	var paused_position=ap.current_animation_position
	await wait(.3)
	check(is_equal_approx(paused_position,ap.current_animation_position),"pause_freezes_animation")
	await key(KEY_ESCAPE)
	await key(KEY_F)
	await key(KEY_E)
	await key(KEY_E)
	await wait(.2)
	check(game.plots.size()>0 and game.plots.back().water>0,"new_avatar_retains_watering_gameplay")
	check(game.watering_can.visible,"watering_prop_visible")
	var palm=game.character_skeleton.global_transform*game.character_skeleton.get_bone_global_pose(game.hand_bone)
	check(game.watering_can.global_position.distance_to(palm.origin)<.2,"prop_world_scale_attachment",game.watering_can.global_position.distance_to(palm.origin))
	if DisplayServer.get_name()!="headless":
		var folder="user://lux-preview"
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--capture-dir="):folder=arg.trim_prefix("--capture-dir=")
		DirAccess.make_dir_recursive_absolute(folder)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(folder+"/watering.png")
		await wait(2)
		game.player.pivot.rotation.y=PI
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(folder+"/standing.png")
	finish()
