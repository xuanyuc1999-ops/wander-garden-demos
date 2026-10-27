extends "res://art/runtime/art_streamer.gd"
const TREES=["meadow-tree","forest-tree","salt-rock","maple-tree","moon-tree"]
const FLORA=["grass-flower","forest-flora","crystal-flower","autumn-bush","star-flower"]
const ROCKS=["rock-cluster","moss-rock","salt-rock","rock-cluster","rock-cluster"]
var ground_extension: ShaderMaterial
func _ready() -> void:
	super._ready()
	ground_extension=ShaderMaterial.new()
	ground_extension.shader=preload("res://art/runtime/meshy_ground_extension.gdshader")
	ground_extension.set_shader_parameter("autumn_ground",preload("res://art/assets/runtime/meshy-autumn-ground-albedo.png"))
	ground_extension.set_shader_parameter("stars_ground",preload("res://art/assets/runtime/meshy-stars-ground-albedo.png"))
	# Pay the first import/prototype cost during initial loading, not on a
	# walking frame at the next biome or procedural chunk boundary.
	for i in range(5):
		for entry in [[TREES[i],1.4 if i==2 else 3.7],[FLORA[i],.42],[ROCKS[i],.65]]:
			if ResourceLoader.exists(Models.resource_path(entry[0])):get_art(entry[0],entry[1])
	for parts in art_prototypes.values():
		for part in parts:preload("res://art/runtime/ink_style.gd").converted_mesh(part.mesh)
	for i in range(5):
		var grass_material=StandardMaterial3D.new()
		grass_material.albedo_color=ground_color(i).darkened(.15).lightened(.10)
		preload("res://art/runtime/ink_style.gd").material(grass_material)

func build_terrain(job: Dictionary) -> void:
	super.build_terrain(job)
	for child in job.node.get_children():
		if child is MeshInstance3D and child.get_aabb().size.x>20:
			child.material_override=ground_extension
			child.layers=1<<6
func batch(parent: Node3D,kind: String,transforms: Array,color: Color,glow: float) -> void:
	if transforms.is_empty():return
	var region_index=Data.region_at(parent.global_position+transforms[0].origin)
	if region_index==0:
		super.batch(parent,kind,transforms,color,glow)
		return
	if kind=="trunk":return
	if kind=="grass":
		var previous=families.grass
		families.grass=blade_mesh
		# Call the base through a dedicated primitive path, avoiding imported trees.
		draw_instances(parent,[{"mesh":blade_mesh,"transform":Transform3D.IDENTITY}],transforms,false,color)
		families.grass=previous
		return
	var tree=kind in ["tree","pine"]
	var id=TREES[region_index] if tree else ROCKS[region_index] if kind=="rock" else FLORA[region_index]
	if not ResourceLoader.exists(Models.resource_path(id)):
		super.batch(parent,kind,transforms,color,glow)
		return
	var height=(1.4 if region_index==2 else 3.7) if tree else .65 if kind=="rock" else .42
	draw_instances(parent,get_art(id,height),transforms,tree,Color.TRANSPARENT,0)

func draw_instances(parent: Node3D,parts: Array,transforms: Array,shadow: bool,tint: Color=Color.TRANSPARENT,palette: int=0) -> void:
	for part in parts:
		var mm=MultiMesh.new()
		mm.transform_format=MultiMesh.TRANSFORM_3D
		mm.mesh=part.mesh
		mm.instance_count=transforms.size()
		for i in range(transforms.size()):mm.set_instance_transform(i,transforms[i]*part.transform)
		var node=MultiMeshInstance3D.new()
		node.multimesh=mm
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if tint.a>0:
			var material=StandardMaterial3D.new()
			material.albedo_color=tint.lightened(.10)
			material.cull_mode=BaseMaterial3D.CULL_DISABLED
			material.roughness=.95
			node.material_override=material
		elif palette>0:
			var original=part.mesh.surface_get_material(0)
			if original is StandardMaterial3D and original.albedo_texture:
				var material=ShaderMaterial.new()
				material.shader=preload("res://art/runtime/foliage_palette.gdshader")
				material.set_shader_parameter("base_texture",original.albedo_texture)
				material.set_shader_parameter("base_tint",original.albedo_color)
				material.set_shader_parameter("foliage_color",Color("#ed8246") if palette==3 else Color("#7d8eb8"))
				node.material_override=material
		parent.add_child(node)

func _process(delta: float) -> void:
	super._process(delta)
	for chunk in chunks.values():
		if chunk.get_meta("ink_child_count",-1)!=chunk.get_child_count():
			preload("res://art/runtime/ink_style.gd").apply_node(chunk)
			chunk.set_meta("ink_child_count",chunk.get_child_count())
