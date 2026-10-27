extends Node3D
const GROUND_LAYER=1<<6
const WATER_LAYER=1<<7
var game: Node
var reflection_viewport: SubViewport
var reflection_camera: Camera3D
var material: ShaderMaterial
var timer=0.0
var last_generated=-1
var region_index=0
var stretch=Vector2.ONE
var shallow_tint=Color(.31,.43,.32)
var deep_tint=Color(.065,.23,.25)
var shore_tint=Color(.48,.63,.43)
var model_path="res://art/assets/runtime/lake-v04.glb"
var water_shader_path="res://art/runtime/lake_surface_v04.gdshader"
var shore_shader_path="res://art/runtime/lake_bed_v04.gdshader"
func _ready() -> void:
	position=Vector3(13,0,5)
	var model=load(model_path).instantiate()
	model.scale=Vector3(stretch.x,1,stretch.y)
	add_child(model)
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		mesh.layers=WATER_LAYER
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mesh.name.begins_with("LakeSurface") or mesh.name.begins_with("StarWaterSurface"):
			material=ShaderMaterial.new()
			material.shader=load(water_shader_path)
			material.set_shader_parameter("lake_center",Vector2(global_position.x,global_position.z))
			material.set_shader_parameter("lake_scale",stretch)
			material.set_shader_parameter("shallow_tint",shallow_tint)
			material.set_shader_parameter("deep_tint",deep_tint)
			mesh.material_override=material
		else:
			var mat=ShaderMaterial.new()
			mat.shader=load(shore_shader_path)
			mat.set_shader_parameter("bank",mesh.name.begins_with("LakeBank"))
			mat.set_shader_parameter("shore_tint",shore_tint)
			mesh.material_override=mat
	reflection_viewport=SubViewport.new()
	reflection_viewport.size=Vector2i(512,320)
	reflection_viewport.world_3d=game.get_world_3d()
	reflection_viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	reflection_viewport.gui_disable_input=true
	add_child(reflection_viewport)
	reflection_camera=Camera3D.new()
	reflection_camera.cull_mask=1
	reflection_viewport.add_child(reflection_camera)
	reflection_camera.current=true
	material.set_shader_parameter("reflection_texture",reflection_viewport.get_texture())
	mark_ground()
func mark_ground() -> void:
	for mesh in game.world.find_children("*","MeshInstance3D",true,false):
		if str(mesh.name).ends_with("LayeredGround") or (mesh.mesh is BoxMesh and mesh.mesh.size.x>40):
			mesh.layers=GROUND_LAYER
	for chunk in game.streamer.chunks.values():
		for child in chunk.get_children():
			if child is MeshInstance3D and child.get_aabb().size.x>20:child.layers=GROUND_LAYER
	last_generated=game.streamer.generated_count
func _process(delta: float) -> void:
	if material==null or not is_instance_valid(game.player):return
	timer+=delta
	if timer<1.0/24.0:return
	timer=0
	if game.streamer.generated_count!=last_generated:mark_ground()
	var camera=game.player.camera
	if game.region!=region_index or camera.global_position.distance_to(global_position)>55:
		reflection_viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
		return
	var viewport_size=game.get_viewport().get_visible_rect().size
	var width=384 if OS.has_feature("web") else 512
	reflection_viewport.size=Vector2i(width,maxi(128,int(width*viewport_size.y/viewport_size.x)))
	var origin=camera.global_position
	origin.y=.13-origin.y
	var forward=-camera.global_basis.z;forward.y=-forward.y
	var up=camera.global_basis.y;up.y=-up.y
	reflection_camera.global_position=origin
	reflection_camera.look_at(origin+forward,up)
	reflection_camera.fov=camera.fov
	reflection_camera.near=.08;reflection_camera.far=48
	material.set_shader_parameter("reflection_view",Projection(reflection_camera.global_transform.affine_inverse()))
	material.set_shader_parameter("reflection_projection",reflection_camera.get_camera_projection())
	material.set_shader_parameter("reflection_ready",true)
	reflection_viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
