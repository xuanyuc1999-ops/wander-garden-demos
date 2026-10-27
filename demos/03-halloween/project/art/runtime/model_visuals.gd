extends RefCounted
# Visual-only import adapter: authoritative controllers and collision stay external.
static var cache: Dictionary={}
static var ink_enabled=false
static func _bounds(node: Node3D,xf: Transform3D,points: Array) -> void:
	var next=xf*node.transform
	if node is MeshInstance3D:
		var box=node.get_aabb()
		for n in range(8):
			points.append(next*box.get_endpoint(n))
	for child in node.get_children():
		if child is Node3D:
			_bounds(child,next,points)

static func resource_path(id: String) -> String:
	var paths={
		"meadow-tree":"res://art/assets/runtime/meshy-meadow-tree.glb",
		"forest-tree":"res://art/assets/runtime/meshy-forest-tree.glb",
		"maple-tree":"res://art/assets/runtime/meshy-maple-tree.glb",
		"moon-tree":"res://art/assets/runtime/moon-tree-pruned-v091.glb",
		"grass-flower":"res://art/assets/runtime/grass-flower.glb",
		"rabbit":"res://art/assets/runtime/rabbit-motion-v04.glb",
		"traveler":"res://art/assets/runtime/traveler.glb",
		"traveler-animated":"res://art/assets/runtime/hw-skeleton.glb",
		"stone-arch":"res://art/assets/runtime/stone-arch-wide-r2.glb"
	}
	return paths.get(id,"res://art/assets/runtime/"+id+".glb")

static func spawn(parent: Node3D,id: String,height: float,rotation_y: float=0.0) -> Node3D:
	var path=resource_path(id)
	if not cache.has(path):
		cache[path]=load(path)
	var model=cache[path].instantiate()
	var points=[]
	_bounds(model,Transform3D.IDENTITY,points)
	assert(not points.is_empty())
	var box=AABB(points[0],Vector3.ZERO)
	for point in points:
		box=box.expand(point)
	var factor=height/maxf(box.size.y,0.00001)
	var holder=Node3D.new()
	holder.name=id.replace("-","_")+"_Visual"
	holder.rotation.y=rotation_y
	parent.add_child(holder)
	var correction=Node3D.new()
	correction.scale=Vector3.ONE*factor
	correction.position=Vector3(-box.get_center().x*factor,-box.position.y*factor,-box.get_center().z*factor)
	holder.add_child(correction)
	correction.add_child(model)
	holder.set_meta("asset_id",id)
	holder.set_meta("source",path)
	holder.set_meta("normalization",factor)
	holder.set_meta("height_m",height)
	if ink_enabled:preload("res://art/runtime/ink_style.gd").apply_node(holder)
	return holder

static func hide_old_meshes(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			child.visible=false

static func triangles(node: Node) -> int:
	var total=0
	for child in node.find_children("*","MeshInstance3D",true,false):
		for surface in range(child.mesh.get_surface_count()):
			var arrays=child.mesh.surface_get_arrays(surface)
			total+=arrays[Mesh.ARRAY_INDEX].size()/3 if arrays[Mesh.ARRAY_INDEX].size()>0 else arrays[Mesh.ARRAY_VERTEX].size()/3
	return total
