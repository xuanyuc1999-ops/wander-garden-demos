extends "res://tests/playthrough.gd"
func _ready() -> void:
	await wait(.3)
	await key(KEY_ENTER)
	await wait(.4)
	check(game.animation_map.has("Run_Loop") and game.animation_map.size()==5,"walk_run_and_interaction_clips_present")
	var skeleton=game.character_skeleton
	var lateral=[]
	for name in ["Hand.L","Hand.R"]:
		var bone=skeleton.find_bone(name)
		var world=skeleton.global_transform*skeleton.get_bone_global_pose(bone).origin
		lateral.append(absf((game.player.visual.global_transform.affine_inverse()*world).x))
	check(lateral.max()<.34,"idle_hands_relaxed_beside_body",lateral)
	Input.action_press("right")
	await wait(.35)
	check(game.current_clip=="Walk","ordinary_walk_uses_walk_clip")
	check(absf(game.player.velocity.x-.65)<.05,"walking_speed_matches_short_stride")
	var steps_per_second=2.0*game.animation_player.speed_scale/game.animation_player.current_animation_length
	check(steps_per_second>1.7 and steps_per_second<2.4,"walking_cadence_is_unhurried",steps_per_second)
	var max_error=0.0
	var contact_samples=0
	for sample in range(72):
		await get_tree().process_frame
		var phase=game.animation_player.current_animation_position/game.animation_player.current_animation_length
		for item in [["Foot.L",0.0],["Foot.R",.5]]:
			var p=fmod(phase+item[1],1.0)
			if p>.06 and p<.36:
				var bone=skeleton.find_bone(item[0])
				var foot=skeleton.global_transform*skeleton.get_bone_global_pose(bone).origin
				max_error=maxf(max_error,absf(foot.y-game.player.position.y-.10))
				contact_samples+=1
	check(contact_samples>10 and max_error<.035,"stance_ankles_stay_at_ground_height",{"samples":contact_samples,"max_error_m":max_error})
	Input.action_press("run")
	await wait(.5)
	check(game.current_clip=="Run","sprint_uses_distinct_run_clip")
	stop();await wait(.7)
	check(game.current_clip=="Idle","deceleration_returns_to_relaxed_idle")
	check(game.rabbit_motion.clips.size()==3,"rabbit_idle_hop_eat_clips_bound")
	var rabbit_skeleton=game.live_assets["rabbit"].find_children("*","Skeleton3D",true,false)[0]
	check(rabbit_skeleton.get_bone_count()==17,"rabbit_has_articulated_body_limbs_ears")
	check(absf(game.pets[0].visual.rotation.x)<.001,"legacy_whole_rabbit_nod_removed")
	check(game.lake_visual.material.get_shader_parameter("reflection_ready"),"actual_scene_reflection_ready")
	check(absf(game.lake_visual.reflection_camera.global_position.y+game.player.camera.global_position.y-.13)<.04,"reflection_camera_mirrors_water_plane")
	check(game.lake_visual.reflection_camera.cull_mask==1,"reflection_excludes_water_recursion")
	check(game.lake_visual.reflection_viewport.size.x<=512,"reflection_resolution_bounded")
	await key(KEY_ESCAPE)
	await wait(.1)
	var hero_time=game.animation_player.current_animation_position
	var rabbit_time=game.rabbit_motion.animation.current_animation_position
	await wait(.3)
	check(is_equal_approx(hero_time,game.animation_player.current_animation_position) and is_equal_approx(rabbit_time,game.rabbit_motion.animation.current_animation_position),"pause_freezes_both_skeletal_animations")
	await key(KEY_ESCAPE)
	finish()
