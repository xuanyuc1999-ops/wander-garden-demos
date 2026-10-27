extends RefCounted
# The user's GLB stays byte-for-byte intact. Only runtime animation copies change.
var native_walk_speed=0.818
var source_duration=0.0
var stride_m=0.0
var source_animation: Animation
var walk_animation: Animation

func setup(player: AnimationPlayer,skeleton: Skeleton3D) -> Dictionary:
	source_animation=player.get_animation("model-action")
	source_duration=source_animation.length
	walk_animation=source_animation.duplicate(true)
	walk_animation.loop_mode=Animation.LOOP_LINEAR
	for track in range(walk_animation.get_track_count()):
		if walk_animation.track_get_type(track)!=Animation.TYPE_POSITION_3D:continue
		if not str(walk_animation.track_get_path(track)).ends_with("mixamorig_Hips"):continue
		var first: Vector3=walk_animation.track_get_key_value(track,0)
		var last: Vector3=walk_animation.track_get_key_value(track,walk_animation.track_get_key_count(track)-1)
		var travel=Vector3(last.x-first.x,0,last.z-first.z)
		stride_m=(skeleton.global_basis*travel).length()
		native_walk_speed=stride_m/source_duration
		for key in range(walk_animation.track_get_key_count(track)):
			var value: Vector3=walk_animation.track_get_key_value(track,key)
			value-=travel*(walk_animation.track_get_key_time(track,key)/source_duration)
			walk_animation.track_set_key_value(track,key,value)
	var library=AnimationLibrary.new()
	library.add_animation("WalkInPlace",walk_animation)
	# No idle, running or interaction animations were supplied. A static pose
	# averaged from this walk is a local fallback, not a provider-authored clip.
	var stand=Animation.new()
	stand.length=1.0
	stand.loop_mode=Animation.LOOP_LINEAR
	for track in range(walk_animation.get_track_count()):
		var kind=walk_animation.track_get_type(track)
		var target=stand.add_track(kind)
		stand.track_set_path(target,walk_animation.track_get_path(track))
		var value: Variant
		if kind==Animation.TYPE_ROTATION_3D:
			var rotation=walk_animation.rotation_track_interpolate(track,0)
			for sample in range(1,16):
				rotation=rotation.slerp(walk_animation.rotation_track_interpolate(track,source_duration*sample/16.0),1.0/(sample+1))
			value=rotation.normalized()
		elif kind==Animation.TYPE_POSITION_3D:
			var position=Vector3.ZERO
			for sample in range(16):
				position+=walk_animation.position_track_interpolate(track,source_duration*sample/16.0)/16.0
			value=position
		else:
			value=walk_animation.track_get_key_value(track,0)
		stand.track_insert_key(target,0,value)
		stand.track_insert_key(target,stand.length,value)
	library.add_animation("LocalStand",stand)
	for action in ["LocalWaterStand","LocalInteractStand"]:
		var pose=stand.duplicate(true)
		pose.loop_mode=Animation.LOOP_NONE
		pose.length=1.6 if action=="LocalWaterStand" else 1.0
		library.add_animation(action,pose)
	player.add_animation_library("LuxAdapter",library)
	return {"Idle_Loop":"LuxAdapter/LocalStand","Walk_Loop":"LuxAdapter/WalkInPlace",
		"Run_Loop":"LuxAdapter/WalkInPlace","Farm_Watering":"LuxAdapter/LocalWaterStand",
		"Interact":"LuxAdapter/LocalInteractStand"}
