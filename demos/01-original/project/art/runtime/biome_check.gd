extends "res://tests/playthrough.gd"
func finish() -> void:
	var path="user://biome-check.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="):path=arg.trim_prefix("--report=")
	var f=FileAccess.open(path,FileAccess.WRITE)
	f.store_string(JSON.stringify({"mode":"asset_structure_and_staged_region_smoke","injected_state":true,"checks":checks,"failures":errors},"\t"))
	f.close()
	get_tree().quit(1 if errors else 0)
func _ready() -> void:
	await wait(.4)
	for id in ["forest-tree","forest-flora","fox","moss-rock","salt-rock","salt-reeds","otter","crystal-flower","maple-tree","pear-crop","squirrel","autumn-bush","moon-tree","star-flower","firefly-beast","moon-shrine"]:
		check(game.biome_art.available(id),"real_asset_"+id)
	for index in range(1,5):
		var id=game.biome_art.PETS[index]
		var models=game.pets[index].visual.find_children("*","Skeleton3D",true,false)
		check(not models.is_empty(),"companion_skin_"+id)
		var players=game.pets[index].visual.find_children("*","AnimationPlayer",true,false)
		check(not players.is_empty() and players[0].get_animation_list().size()>=3,"companion_three_actions_"+id)
	check(game.biome_art.lakes.size()==4,"four_additional_biome_water_surfaces")
	check(game.streamer.get_script().resource_path.ends_with("biome_streamer.gd"),"procedural_details_use_biome_assets")
	await key(KEY_ENTER)
	for i in range(1,5):
		game.player.position=game.data.center(i)+Vector3(0,.1,12)
		await wait(.2)
		check(game.region==i,"visual_region_"+str(i))
		check(game.env.background_mode==Environment.BG_SKY,"biome_sky_"+str(i))
		check(game.biome_art.lakes[i-1].region_index==i,"reflection_region_"+str(i))
	finish()
