extends RefCounted
var pet: Node3D
var animation: AnimationPlayer
var clips={}
var current=""
var speed_blend=0.0
var hop_rate=1.0
var offset_blend=Vector3.ZERO
func setup(actor: Node3D,model: Node3D) -> void:
	pet=actor
	var players=model.find_children("*","AnimationPlayer",true,false)
	assert(not players.is_empty())
	animation=players[0]
	for name in animation.get_animation_list():
		for kind in ["Idle","Hop","Eat"]:
			if name=="Rabbit_"+kind or name=="Rabbit_"+kind+"_Loop":
				clips[kind]=name
				var clip=animation.get_animation(name)
				clip.loop_mode=Animation.LOOP_LINEAR
				if not clip.has_meta("trimmed_end_hold"):
					clip.length=maxf(.1,clip.length-1.0/30.0)
					clip.set_meta("trimmed_end_hold",true)
	assert(clips.size()==3)
	current="Idle"
	animation.play(clips.Idle)
	animation.advance(0)
func update(delta: float,paused: bool) -> void:
	if paused:
		animation.speed_scale=0
		return
	var speed=Vector2(pet.velocity.x,pet.velocity.z).length()
	speed_blend=lerpf(speed_blend,speed,1-exp(-delta*10))
	var state="Eat" if pet.state=="eat" else "Hop" if speed_blend>.12 else "Idle"
	var finishing=false
	if current=="Hop" and state!="Hop":
		var phase=animation.current_animation_position/animation.get_animation(clips.Hop).length
		if phase<.90:
			state="Hop"
			finishing=true
	if current!=state:
		current=state
		animation.play(clips[state],.14)
	if state=="Hop" and not finishing:hop_rate=clampf(speed_blend/1.15,.65,2.5)
	animation.speed_scale=hop_rate if state=="Hop" else 1
	pet.visual.position=Vector3(0,.04,0)
	pet.visual.rotation.x=0
	var wanted_offset=Vector3.ZERO
	if state=="Hop":
		var duration=animation.get_animation(clips.Hop).length
		var phase=fmod(animation.current_animation_position/duration,1.0)
		var progress=0.0
		if phase<.20:progress=0
		elif phase<.32:progress=.1*smoothstep(.20,.32,phase)
		elif phase<.72:progress=lerpf(.1,.9,smoothstep(.32,.72,phase))
		elif phase<.88:progress=lerpf(.9,1.0,smoothstep(.72,.88,phase))
		else:progress=1
		var stride=minf(.9,speed_blend*duration/maxf(animation.speed_scale,.01))
		var offset=Vector3(0,0,-(progress-phase)*stride)
		# The visual phase must not move the companion through a nearby obstacle.
		if not pet.test_move(pet.global_transform,pet.visual.basis*offset):
			wanted_offset=offset
	offset_blend=offset_blend.lerp(wanted_offset,1-exp(-delta*18))
	pet.visual.position+=offset_blend
