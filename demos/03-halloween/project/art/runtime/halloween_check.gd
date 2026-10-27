extends "res://tests/playthrough.gd"
func _ready() -> void:
	await wait(.4)
	check(game.halloween!=null,"halloween_world_installed")
	check(game.character_skeleton.get_bone_count()==52,"skeleton_52_bone_rig")
	check(game.live_assets.traveler.get_meta("source").ends_with("hw-skeleton.glb"),"cute_skeleton_is_player")
	check(game.hand_bone>=0,"watering_hand_attachment")
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://art/edition/halloween-manifest.json"))
	check(manifest is Dictionary,"halloween_manifest")
	if manifest is Dictionary:
		check(manifest.cloud_assets.size()==12,"twelve_actual_Lux_outputs")
		var ids={}
		for item in manifest.cloud_assets:
			check(ResourceLoader.exists(item.runtime_path),"generated_asset_"+item.id)
			ids[item.task_id]=true
		check(ids.size()==12,"twelve_unique_tasks")
	for action in ["Idle_Loop","Walk_Loop","Run_Loop","Farm_Watering","Interact"]:
		check(game.animation_map.has(action),"Lux_preset_"+action)
	for id in ["hw-pumpkin","hw-ghost","hw-cauldron","hw-candy"]:
		check(game.halloween.prop_counts.get(id,0)>=5,"decor_all_regions_"+id)
	for i in range(5):
		var count=0
		for node in game.halloween.decorations:
			if absf(node.position.z-game.data.center(i).z)<28:count+=1
		check(count>=10,"festive_vignettes_region_"+str(i),count)
	await key(KEY_ENTER)
	var start=game.player.position
	Input.action_press("forward")
	await wait(1)
	check(game.current_clip==game.animation_map.Walk_Loop,"walk_drives_skeleton")
	check(game.player.position.distance_to(start)>1,"walk_displacement")
	Input.action_press("run")
	await wait(.5)
	check(game.current_clip==game.animation_map.Run_Loop,"Shift_drives_Lux_jog")
	stop();await wait(.6)
	check(game.current_clip==game.animation_map.Idle_Loop,"stop_returns_idle")
	await key(KEY_F);await key(KEY_E);await key(KEY_E);await wait(.2)
	check(game.plots.size()>0 and game.plots.back().water>0,"skeleton_can_plant_and_water")
	check(game.watering_can.visible,"skeleton_holds_watering_can")
	var hand=game.character_skeleton.global_transform*game.character_skeleton.get_bone_global_pose(game.hand_bone)
	check(game.watering_can.global_position.distance_to(hand.origin)<.2,"skeleton_hand_alignment")
	finish()
