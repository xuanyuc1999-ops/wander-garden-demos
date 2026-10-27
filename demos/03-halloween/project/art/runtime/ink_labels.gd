extends CanvasLayer
var game: Node
var labels=[]
func _ready() -> void:
	layer=1
	for source in game.world.find_children("*","Label3D",true,false):
		var label=Label.new()
		label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		label.text=source.text
		label.add_theme_font_override("font",source.font)
		label.add_theme_color_override("font_color",Color("#fff0c9"))
		label.add_theme_color_override("font_outline_color",Color("#172743"))
		label.add_theme_constant_override("outline_size",4)
		add_child(label)
		source.visible=false
		labels.append({"source":source,"label":label,"font_size":0})
func _process(_delta: float) -> void:
	if not is_instance_valid(game.player):return
	var camera=game.player.camera
	for entry in labels:
		var source=entry.source
		var label=entry.label
		var distance=camera.global_position.distance_to(source.global_position)
		label.visible=game.started and not game.hud.panel.visible and not game.photo and source.get_parent().is_visible_in_tree() and distance<55 and not camera.is_position_behind(source.global_position)
		if not label.visible:continue
		var query=PhysicsRayQueryParameters3D.create(camera.global_position,source.global_position,1,[game.player.get_rid()])
		var hit=game.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.position.distance_to(source.global_position)>.5:
			label.visible=false
			continue
		var size=clampi(roundi(30./(1.+distance*.035)),13,23)
		if entry.font_size!=size:
			label.add_theme_font_size_override("font_size",size)
			entry.font_size=size
		label.position=camera.unproject_position(source.global_position)-label.size*.5
		label.modulate.a=1.-smoothstep(43.,55.,distance)
