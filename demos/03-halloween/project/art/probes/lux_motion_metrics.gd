extends SceneTree
const Models=preload("res://art/runtime/model_visuals.gd")
func _initialize() -> void:
	call_deferred("measure")
func measure() -> void:
	var parent=Node3D.new()
	root.add_child(parent)
	var model=Models.spawn(parent,"traveler-lux-presets",1.72)
	var skeleton=model.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
	var player=model.find_children("*","AnimationPlayer",true,false)[0] as AnimationPlayer
	var adapter=preload("res://art/runtime/lux_preset_avatar.gd").new()
	var mapping=adapter.setup(player,skeleton)
	var report={"strides":adapter.strides,"durations":adapter.durations,"samples":{}}
	for action in mapping:
		var samples=[]
		var clip=player.get_animation(mapping[action])
		for n in range(61):
			player.play(mapping[action])
			player.seek(clip.length*n/60.0,true)
			player.advance(0)
			var row={"t":clip.length*n/60.0}
			for side in ["Left","Right"]:
				var points=[]
				for joint in ["UpLeg","Leg","Foot","ToeBase"]:
					var b=skeleton.find_bone("mixamorig_"+side+joint)
					var point=(skeleton.global_transform*skeleton.get_bone_global_pose(b)).origin
					points.append(point)
				var knee_angle=rad_to_deg((points[0]-points[1]).angle_to(points[2]-points[1]))
				row[side]={"knee_angle":knee_angle,"points":points.map(func(v):return [v.x,v.y,v.z])}
			samples.append(row)
		report.samples[action]=samples
	var output="user://lux-motion-metrics.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="):output=arg.trim_prefix("--report=")
	var f=FileAccess.open(output,FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"))
	f.close()
	print("LUX_PRESET_METRICS ",output)
	quit()
