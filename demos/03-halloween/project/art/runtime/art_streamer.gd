extends "res://art/probes/h2_streamer.gd"
const Models=preload("res://art/runtime/model_visuals.gd")
var art_prototypes={}
var blade_mesh: ArrayMesh

func _ready() -> void:
	super._ready()
	blade_mesh=make_blades()

func make_blades() -> ArrayMesh:
	var tool=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng=RandomNumberGenerator.new();rng.seed=7217
	for i in range(7):
		var angle=rng.randf()*TAU
		var root=Vector3(rng.randf_range(-.14,.14),0,rng.randf_range(-.14,.14))
		var height=rng.randf_range(.18,.40)
		var across=Vector3(cos(angle),0,sin(angle))*.035
		var lean=Vector3(-sin(angle),0,cos(angle))*.11
		var middle=root+Vector3.UP*height*.55+lean*.35
		var tip=root+Vector3.UP*height+lean
		var points=[root-across,root+across,middle-across*.55,middle+across*.55,tip]
		for n in [0,2,1,1,2,3,2,4,3]:
			tool.set_uv(Vector2(.5,points[n].y/height))
			tool.add_vertex(points[n])
	tool.generate_normals()
	return tool.commit()

func get_art(id: String,height: float) -> Array:
	if art_prototypes.has(id):return art_prototypes[id]
	var holder=Models.spawn(self,id,height)
	var parts=[]
	for mesh in holder.find_children("*","MeshInstance3D",true,false):
		parts.append({"mesh":mesh.mesh,"transform":holder.global_transform.affine_inverse()*mesh.global_transform})
	remove_child(holder);holder.queue_free()
	art_prototypes[id]=parts
	return parts

func batch(parent: Node3D,kind: String,transforms: Array,color: Color,glow: float) -> void:
	if transforms.is_empty():return
	var first_world=parent.global_position+transforms[0].origin
	var region_index=Data.region_at(first_world)
	if region_index!=0:
		super.batch(parent,kind,transforms,color,glow)
		return
	if kind=="trunk":return # Imported tree includes its own trunk.
	if kind=="grass":
		var previous=families["grass"]
		families["grass"]=blade_mesh
		super.batch(parent,kind,transforms,Color("#b2977b"),glow)
		families["grass"]=previous
		return
	var id="meadow-tree" if kind=="tree" else "grass-flower" if kind=="flower" else "rock-cluster" if kind=="rock" and ResourceLoader.exists("res://art/assets/runtime/rock-cluster.glb") else ""
	if id.is_empty():
		super.batch(parent,kind,transforms,color,glow)
		return
	var height=3.8 if kind=="tree" else .38 if kind=="flower" else .55
	for part in get_art(id,height):
		var mm=MultiMesh.new()
		mm.transform_format=MultiMesh.TRANSFORM_3D
		mm.mesh=part.mesh
		mm.instance_count=transforms.size()
		for i in range(transforms.size()):
			mm.set_instance_transform(i,transforms[i]*part.transform)
		var node=MultiMeshInstance3D.new()
		node.multimesh=mm
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if kind=="flower" else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		parent.add_child(node)
