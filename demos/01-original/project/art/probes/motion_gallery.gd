extends Node3D
const Models=preload("res://art/runtime/model_visuals.gd")
const Art=preload("res://scripts/art.gd")
func _ready() -> void:
	var folder="user://motion-gallery"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):folder=arg.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(folder)
	var environment=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("#dce5df")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color.WHITE
	environment.environment.ambient_light_energy=0.45
	add_child(environment)
	var light=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-48,-32,0)
	light.light_energy=0.42
	light.shadow_enabled=true
	add_child(light)
	Art.box(self,Vector3(0,-0.04,0),Vector3(20,0.08,20),Color("#b9c4b6"))
	var rabbit_mode="--rabbit-motion" in OS.get_cmdline_user_args()
	var model_id="rabbit" if rabbit_mode else "traveler-animated"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--model-id="):model_id=arg.trim_prefix("--model-id=")
	var model=Models.spawn(self,model_id,.9 if rabbit_mode else 1.72)
	var animation=model.find_children("*","AnimationPlayer",true,false)[0] as AnimationPlayer
	var skeleton=model.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
	if "--preset-calibrated" in OS.get_cmdline_user_args():
		var adapter=preload("res://art/runtime/lux_preset_avatar.gd").new()
		adapter.setup(animation,skeleton)
	var camera=Camera3D.new()
	camera.fov=40
	add_child(camera)
	camera.current=true
	var ui=CanvasLayer.new();add_child(ui)
	var label=Label.new();ui.add_child(label)
	label.position=Vector2(30,20);label.add_theme_font_size_override("font_size",24)
	label.add_theme_color_override("font_color",Color("#304c41"))
	var report={"clips":[],"bones":skeleton.get_bone_count(),"triangles":Models.triangles(model),"samples":[]}
	for clip in animation.get_animation_list():
		if clip=="RESET":continue
		if "--preset-calibrated" in OS.get_cmdline_user_args() and not clip.begins_with("LuxPresets/"):continue
		var length=animation.get_animation(clip).length
		report.clips.append({"name":clip,"seconds":length})
		for view in range(3):
			var angles=[0.22,PI/2,PI+0.22]
			var distance=2.2 if rabbit_mode else 3.8
			camera.position=Vector3(sin(angles[view])*distance,.65 if rabbit_mode else 1.1,cos(angles[view])*distance)
			camera.look_at(Vector3(0,.45 if rabbit_mode else .88,0))
			for sample in range(4):
				var time=length*float(sample)/4.0
				animation.play(clip)
				animation.seek(time,true)
				animation.pause()
				label.text="%s · %.2fs · view %d" % [clip,time,view]
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				var filename="%s-v%d-f%d.png" % [clip.replace("/","-"),view,sample]
				get_viewport().get_texture().get_image().save_png(folder+"/"+filename)
				report.samples.append({"clip":clip,"time":time,"view":view,"image":filename})
	var f=FileAccess.open(folder+"/motion-gallery.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"));f.close()
	get_tree().quit()
