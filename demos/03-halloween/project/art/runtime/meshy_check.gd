extends "res://art/runtime/biome_check.gd"
const Models=preload("res://art/runtime/model_visuals.gd")
func finish() -> void:
	check(is_equal_approx(game.player.walk_speed,1.8),"faster_walk_1_8_mps")
	check(is_equal_approx(game.player.run_speed,5.4),"faster_run_5_4_mps")
	for id in ["meadow-tree","forest-tree","maple-tree","moon-tree"]:
		if id=="moon-tree":
			check(Models.resource_path(id).ends_with("moon-tree-pruned-v091.glb"),"authored_and_streamed_blender_pruned_moon_tree")
		else:
			check("meshy-"+id in Models.resource_path(id),"authored_and_streamed_meshy_tree_"+id)
	for index in [3,4]:
		var decor=game.world.chunks[index]
		var model=decor.get_node_or_null("MeshyWholeRegionGround")
		check(model!=null,"whole_meshy_ground_region_"+str(index))
		if model==null:continue
		var bounds=[]
		Models._bounds(model,Transform3D.IDENTITY,bounds)
		var box=AABB(bounds[0],Vector3.ZERO)
		for point in bounds:box=box.expand(point)
		check(absf(box.size.x-50)<.01 and absf(box.size.z-56)<.01,"full_50x56m_ground_coverage_"+str(index),str(box))
		check(box.end.y<=.021 and box.end.y>=.003,"ground_does_not_bury_feet_or_crops_"+str(index),box.end.y)
		check(not decor.get_node(game.data.REGIONS[index].id.capitalize()+"LayeredGround").visible,"old_shader_ground_hidden_"+str(index))
		check(model.get_meta("provider")=="Meshy","ground_provider_trace_"+str(index))
	check(game.streamer.ground_extension!=null,"peripheral_ground_uses_meshy_surface_derivative")
	super.finish()
