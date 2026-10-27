extends SceneTree
const Models=preload("res://art/runtime/model_visuals.gd")
func _initialize() -> void:
	call_deferred("inspect")
func inspect() -> void:
	var parent=Node3D.new()
	root.add_child(parent)
	var model=Models.spawn(parent,"traveler-lux-user",1.72,PI)
	var skeleton=model.find_children("*","Skeleton3D",true,false)[0]
	var player=model.find_children("*","AnimationPlayer",true,false)[0]
	var animation=player.get_animation("model-action")
	print("LUX_SCALE ",model.get_meta("normalization")," skeleton basis ",skeleton.global_basis)
	for b in range(skeleton.get_bone_count()):
		if b<12 or "Leg" in skeleton.get_bone_name(b) or "Foot" in skeleton.get_bone_name(b):
			print("BONE ",b," ",skeleton.get_bone_name(b)," ",skeleton.get_bone_rest(b))
	for t in range(animation.get_track_count()):
		print("TRACK ",t," ",animation.track_get_type(t)," ",animation.track_get_path(t)," first=",animation.track_get_key_value(t,0)," last=",animation.track_get_key_value(t,animation.track_get_key_count(t)-1))
	quit()
