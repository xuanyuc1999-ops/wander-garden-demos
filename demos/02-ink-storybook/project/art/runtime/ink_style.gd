extends RefCounted
static var materials={}
static var meshes={}
static func material(source: Material) -> Material:
	if not source is StandardMaterial3D:return source
	var texture=source.albedo_texture
	var key=str(texture.get_instance_id() if texture else 0)+str(source.albedo_color)+str(source.emission)+str(source.emission_energy_multiplier)
	if materials.has(key):return materials[key]
	var result=ShaderMaterial.new()
	result.shader=preload("res://art/runtime/ink_object.gdshader")
	result.set_shader_parameter("textured",texture!=null)
	if texture:result.set_shader_parameter("base_texture",texture)
	result.set_shader_parameter("base_color",source.albedo_color)
	result.set_shader_parameter("glow_color",source.emission if source.emission_enabled else Color.BLACK)
	result.set_shader_parameter("glow_strength",source.emission_energy_multiplier*.25 if source.emission_enabled else 0.)
	materials[key]=result
	return result

static func converted_mesh(source: Mesh) -> Mesh:
	var key=source.get_instance_id()
	if meshes.has(key):return meshes[key]
	var result=source.duplicate()
	for s in range(result.get_surface_count()):
		result.surface_set_material(s,material(source.surface_get_material(s)))
	meshes[key]=result
	return result

static func apply_node(root: Node) -> void:
	if root is MeshInstance3D:
		if root.material_override:root.material_override=material(root.material_override)
		else:
			for s in range(root.mesh.get_surface_count()):
				root.set_surface_override_material(s,material(root.get_active_material(s)))
	elif root is MultiMeshInstance3D:
		if root.material_override:root.material_override=material(root.material_override)
		elif root.multimesh and root.multimesh.mesh:
			root.multimesh.mesh=converted_mesh(root.multimesh.mesh)
	for child in root.get_children():apply_node(child)

static func install_screen(game: Node) -> void:
	var layer=CanvasLayer.new()
	layer.name="InkScenePass"
	layer.layer=0
	game.add_child(layer)
	var rect=ColorRect.new()
	rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader=ShaderMaterial.new()
	shader.shader=preload("res://art/runtime/ink_screen.gdshader")
	rect.material=shader
	layer.add_child(rect)
	var labels=preload("res://art/runtime/ink_labels.gd").new()
	labels.game=game
	game.add_child(labels)
