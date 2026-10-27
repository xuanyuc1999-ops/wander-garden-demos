extends RefCounted
static func install(parent: Node3D,index: int) -> Node3D:
	var id="meshy-autumn-ground" if index==3 else "meshy-stars-ground"
	var model=load("res://art/assets/runtime/"+id+".glb").instantiate()
	model.name="MeshyWholeRegionGround"
	parent.add_child(model)
	model.set_meta("provider","Meshy")
	model.set_meta("source","res://art/assets/raw/"+id+".glb")
	model.set_meta("runtime_derivative","res://art/assets/runtime/"+id+".glb")
	model.set_meta("size_m",Vector2(50,56))
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		mesh.layers=1<<6
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in range(mesh.mesh.get_surface_count()):
			var original=mesh.get_active_material(surface)
			if original is StandardMaterial3D:
				var material=original.duplicate()
				material.albedo_color=Color(.82,.82,.82) if index==3 else Color(.92,.92,.92)
				mesh.set_surface_override_material(surface,material)
	return model
