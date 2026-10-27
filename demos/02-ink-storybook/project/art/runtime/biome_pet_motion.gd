extends RefCounted
var pet: Node3D
var animation: AnimationPlayer
var clips={}
var current=""
var kind=0
func setup(actor: Node3D,model: Node3D,index: int) -> void:
	pet=actor
	kind=index
	var players=model.find_children("*","AnimationPlayer",true,false)
	if players.is_empty():return
	animation=players[0]
	for name in animation.get_animation_list():
		for action in ["Idle","Walk","Eat"]:
			if str(name).ends_with(action) or str(name).ends_with(action+"_Loop"):
				clips[action]=name
				animation.get_animation(name).loop_mode=Animation.LOOP_LINEAR
	if clips.has("Idle"):
		current="Idle"
		animation.play(clips.Idle)
func update(_delta: float,paused: bool) -> void:
	if animation==null:return
	if paused:
		animation.speed_scale=0
		return
	var speed=Vector2(pet.velocity.x,pet.velocity.z).length()
	var state="Eat" if pet.state=="eat" else "Walk" if speed>.1 else "Idle"
	if clips.has(state) and current!=state:
		current=state
		animation.play(clips[state],.18)
	animation.speed_scale=clampf(speed/1.2,.65,2.0) if state=="Walk" else 1.
	pet.visual.position.y=.24+sin(pet.phase*2)*.06 if kind==4 else .02
	pet.visual.rotation.x=0
