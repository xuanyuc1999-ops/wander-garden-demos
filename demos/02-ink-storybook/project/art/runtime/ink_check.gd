extends "res://art/runtime/meshy_check.gd"
func finish() -> void:
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://art/edition/ink-manifest.json"))
	check(manifest is Dictionary,"ink_manifest_available")
	if manifest is Dictionary:
		check(manifest.generated_materials.size()==30,"thirty_real_lux_material_results")
		var tasks={}
		for item in manifest.generated_materials:
			check(ResourceLoader.exists(item.runtime_path),"ink_asset_available_"+item.asset_id)
			tasks[item.task_id]=true
		check(tasks.size()==30,"thirty_distinct_provider_tasks")
	check(game.get_node_or_null("InkScenePass")!=null,"scene_outline_pass_installed")
	check(preload("res://art/runtime/ink_style.gd").materials.size()>0,"cel_materials_applied")
	var firefly=game.pets[4].visual.find_children("*","Skeleton3D",true,false)
	check(not firefly.is_empty() and firefly[0].get_bone_count()>=4,"retextured_firefly_keeps_skeleton")
	super.finish()
