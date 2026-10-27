extends "res://scripts/player.gd"
# Same collision/orbit/input interface; pacing matches the short character's gait.
const WALK_SPEED=1.8
const RUN_SPEED=5.4
var walk_speed=WALK_SPEED
var run_speed=RUN_SPEED
func _physics_process(delta: float) -> void:
	var axis=Input.get_vector("left","right","forward","back") if enabled and not photo else Vector2.ZERO
	var direction=pivot.global_basis*Vector3(axis.x,0,axis.y)
	direction.y=0
	var speed=run_speed if Input.is_action_pressed("run") else walk_speed
	var horizontal=Vector2(velocity.x,velocity.z)
	var wanted=Vector2(direction.x,direction.z)*speed
	var rate=28.0 if wanted.length_squared()<.001 else 20.0 if horizontal.dot(wanted)<0 else 9.0
	horizontal=horizontal.move_toward(wanted,delta*rate)
	velocity.x=horizontal.x
	velocity.z=horizontal.y
	velocity.y-=20.0*delta
	if is_on_floor():velocity.y=-.1
	move_and_slide()
	if direction.length()>.1:
		visual.rotation.y=lerp_angle(visual.rotation.y,atan2(-direction.x,-direction.z),delta*9)
	if global_position.y< -8:
		global_position=Vector3(0,1,-72.0*clampi(roundi(-global_position.z/72.0),0,4))
		velocity=Vector3.ZERO
