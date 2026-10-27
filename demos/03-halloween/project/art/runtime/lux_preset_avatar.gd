extends RefCounted
# Clip identities verified by native playback, not inferred from output ordering.
# Provider task4306686 has successful Idle/Walk/Jog/Water/Interact action results.
const CLIPS={
	"Idle_Loop":"animation_1","Walk_Loop":"animation_2","Run_Loop":"animation_3",
	"Farm_Watering":"animation_4","Interact":"animation_5"}
var native_walk_speed=0.0
var native_run_speed=0.0
var source_duration=0.0
var stride_m=0.0
var source_animation: Animation
var walk_animation: Animation
var strides: Dictionary={}
var durations: Dictionary={}

func setup(player: AnimationPlayer,skeleton: Skeleton3D) -> Dictionary:
	var library=AnimationLibrary.new()
	var result={}
	for action in CLIPS:
		var original=player.get_animation(CLIPS[action])
		var clip=original.duplicate(true)
		clip.loop_mode=Animation.LOOP_LINEAR if action.ends_with("_Loop") else Animation.LOOP_NONE
		var stride=0.0
		for track in range(clip.get_track_count()):
			if clip.track_get_type(track)!=Animation.TYPE_POSITION_3D:continue
			if not str(clip.track_get_path(track)).ends_with("mixamorig_Hips"):continue
			var first: Vector3=clip.track_get_key_value(track,0)
			var last: Vector3=clip.track_get_key_value(track,clip.track_get_key_count(track)-1)
			var travel=Vector3(last.x-first.x,0,last.z-first.z)
			stride=(skeleton.global_basis*travel).length()
			for key in range(clip.track_get_key_count(track)):
				var value: Vector3=clip.track_get_key_value(track,key)
				value-=travel*(clip.track_get_key_time(track,key)/clip.length)
				clip.track_set_key_value(track,key,value)
		strides[action]=stride
		durations[action]=clip.length
		library.add_animation(action,clip)
		result[action]="LuxPresets/"+action
		if action=="Walk_Loop":
			native_walk_speed=stride/clip.length
			stride_m=stride
			source_duration=clip.length
			source_animation=original
			walk_animation=clip
		elif action=="Run_Loop":
			native_run_speed=stride/clip.length
	player.add_animation_library("LuxPresets",library)
	for action in ["Idle_Loop","Walk_Loop","Farm_Watering","Interact"]:
		var corrected=calibrate_legs(player,skeleton,result[action],action!="Walk_Loop")
		library.remove_animation(action)
		library.add_animation(action,corrected)
		if action=="Walk_Loop":walk_animation=corrected
	return result

func rotate_global(skeleton: Skeleton3D,bone: int,rotation: Basis) -> void:
	var parent=skeleton.get_bone_parent(bone)
	var basis=skeleton.get_bone_global_pose(parent).basis if parent>=0 else Basis.IDENTITY
	skeleton.set_bone_pose_rotation(bone,(basis.inverse()*rotation).orthonormalized().get_rotation_quaternion())

func calibrate_legs(player: AnimationPlayer,skeleton: Skeleton3D,clip_name: String,standing: bool) -> Animation:
	var original=player.get_animation(clip_name)
	var corrected=original.duplicate(true)
	var tracks={}
	for t in range(original.get_track_count()):
		var name=str(original.track_get_path(t)).get_slice(":",1)
		if name=="mixamorig_Hips" and original.track_get_type(t)==Animation.TYPE_POSITION_3D:
			tracks[t]=skeleton.find_bone(name)
		elif original.track_get_type(t)==Animation.TYPE_ROTATION_3D and (name.ends_with("UpLeg") or name.ends_with("Leg") or name.ends_with("Foot")):
			tracks[t]=skeleton.find_bone(name)
	for t in tracks:
		while corrected.track_get_key_count(t)>0:corrected.track_remove_key(t,0)
	var count=ceili(original.length*60)
	var unit_scale=skeleton.global_basis.get_scale().abs().y
	for n in range(count+1):
		var time=original.length*n/count
		player.play(clip_name)
		player.seek(time,true)
		player.advance(0)
		var legs=[]
		for side in ["Left","Right"]:
			var upper=skeleton.find_bone("mixamorig_"+side+"UpLeg")
			var lower=skeleton.find_bone("mixamorig_"+side+"Leg")
			var foot=skeleton.find_bone("mixamorig_"+side+"Foot")
			var hip=skeleton.get_bone_global_pose(upper).origin
			var knee=skeleton.get_bone_global_pose(lower).origin
			var ankle=skeleton.get_bone_global_pose(foot)
			var target=ankle.origin
			if standing:
				target.x=hip.x+(.015 if side=="Left" else -.015)/unit_scale
				target.z=hip.z+.01/unit_scale
			else:
				target.x=lerpf(target.x,hip.x+(.02 if side=="Left" else -.02)/unit_scale,.35)
			legs.append({"upper":upper,"lower":lower,"foot":foot,"hip":hip,"knee":knee,
				"ankle":ankle,"target":target,"a":hip.distance_to(knee),"b":knee.distance_to(ankle.origin)})
		var hips=skeleton.find_bone("mixamorig_Hips")
		var lift=(.027 if standing else .024)/unit_scale
		if standing:
			lift=0.0
			for leg in legs:
				var reach=sqrt(leg.a*leg.a+leg.b*leg.b-2*leg.a*leg.b*cos(deg_to_rad(176.5)))
				var lateral=Vector2(leg.target.x-leg.hip.x,leg.target.z-leg.hip.z).length_squared()
				lift=maxf(lift,leg.target.y+sqrt(maxf(0,reach*reach-lateral))-leg.hip.y)
		skeleton.set_bone_pose_position(hips,skeleton.get_bone_pose_position(hips)+Vector3.UP*lift)
		for leg in legs:
			var hip=skeleton.get_bone_global_pose(leg.upper).origin
			var direction=(leg.target-hip).normalized()
			var reach=clampf(hip.distance_to(leg.target),absf(leg.a-leg.b)+.00001,(leg.a+leg.b)*.9997)
			var along=(leg.a*leg.a-leg.b*leg.b+reach*reach)/(2*reach)
			var height=sqrt(maxf(0,leg.a*leg.a-along*along))
			# Bend in the sagittal plane: the knee should not bow sideways.
			var pole=Vector3(0,0,1)
			pole=(pole-direction*pole.dot(direction)).normalized()
			var knee_target=hip+direction*along+pole*height
			var upper_pose=skeleton.get_bone_global_pose(leg.upper)
			var old_knee=skeleton.get_bone_global_pose(leg.lower).origin
			var swing=Quaternion((old_knee-hip).normalized(),(knee_target-hip).normalized())
			rotate_global(skeleton,leg.upper,Basis(swing)*upper_pose.basis)
			var lower_pose=skeleton.get_bone_global_pose(leg.lower)
			var old_ankle=skeleton.get_bone_global_pose(leg.foot).origin
			var ankle_target=hip+direction*reach
			swing=Quaternion((old_ankle-lower_pose.origin).normalized(),(ankle_target-lower_pose.origin).normalized())
			rotate_global(skeleton,leg.lower,Basis(swing)*lower_pose.basis)
			rotate_global(skeleton,leg.foot,leg.ankle.basis)
		for t in tracks:
			var value: Variant=skeleton.get_bone_pose_position(tracks[t]) if original.track_get_type(t)==Animation.TYPE_POSITION_3D else skeleton.get_bone_pose_rotation(tracks[t])
			corrected.track_insert_key(t,time,value)
	player.stop()
	return corrected
