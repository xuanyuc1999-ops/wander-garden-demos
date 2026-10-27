extends CharacterBody3D
const Art = preload("res://scripts/art.gd")
var kind = 0
var affection = 0
var following = false
var state = "wander"
var home = Vector3.ZERO
var target = Vector3.ZERO
var timer = 0.0
var phase = 0.0
var game: Node
var visual: Node3D
var rng = RandomNumberGenerator.new()
var trail: Array[Vector3]=[]

func _ready() -> void:
	rng.seed=170+kind
	visual = Art.animal(self,kind)
	var c=CollisionShape3D.new()
	var s=SphereShape3D.new()
	s.radius=0.28
	c.shape=s
	c.position.y=0.32
	add_child(c)
	collision_layer=2
	collision_mask=1
	home=position
	target=home

func _physics_process(delta: float) -> void:
	if game.paused:
		return
	if not following and is_instance_valid(game.player):
		var nearby=position.distance_to(game.player.position)<76
		visible=nearby
		if not nearby or (game.streamer and not game.streamer.has_surface(position)):
			velocity=Vector3.ZERO
			return
	else:
		visible=true
	phase+=delta
	timer-=delta
	var direction=Vector3.ZERO
	if state=="eat":
		visual.rotation.x=sin(phase*10)*0.12
		if timer<=0:
			state="follow" if following else "rest"
			timer=2
	else:
		visual.rotation.x=0
		if following:
			state="follow"
			var pp: Vector3=game.player.global_position
			# Follow the player's actual collision-safe path, including turns around
			# trees/huts. This prevents straight-line steering into static obstacles.
			var waypoint=Vector3(pp.x,0,pp.z)
			if trail.is_empty() or trail.back().distance_to(waypoint)>0.25:
				trail.append(waypoint)
			while trail.size()>1 and Vector2(position.x-trail[0].x,position.z-trail[0].z).length()<0.10:
				trail.pop_front()
			# Smooth only segments that the companion's own collision shape can
			# traverse. This avoids oscillating on dense samples on straight paths.
			for lookahead in range(mini(trail.size()-1,8),0,-1):
				var motion=trail[lookahead]-position
				motion.y=0
				if motion.length()>1.35:
					continue
				var probe=global_transform
				probe.origin.y+=0.08
				if not test_move(probe,motion,null,0.0001):
					for consumed in range(lookahead):
						trail.pop_front()
					break
			target=trail[0] if not trail.is_empty() else waypoint
			if Vector2(position.x-pp.x,position.z-pp.z).length()>1.65 or trail.size()>4:
				direction=(target-position)
		elif timer<=0:
			state="rest" if rng.randf()<0.35 else "wander"
			timer=rng.randf_range(3,6)
			target=home+Vector3(rng.randf_range(-2,2),0,rng.randf_range(-2,2))
		elif state=="wander" and position.distance_to(target)>0.25:
			direction=target-position
	direction.y=0
	var speed=7.2 if following and position.distance_to(game.player.position)>5 else 2.8 if following else 0.7
	direction=direction.normalized()
	velocity.x=direction.x*speed
	velocity.z=direction.z*speed
	velocity.y=-2.5
	move_and_slide()
	if direction.length()>0.1:
		visual.rotation.y=lerp_angle(visual.rotation.y,atan2(-direction.x,-direction.z),delta*5)
	visual.position.y=0.24+sin(phase*3)*0.13 if kind==4 else abs(sin(phase*(7 if kind==0 else 4)))*0.07*direction.length()
	if position.y< -3:
		position=home

func feed() -> void:
	if game.harvest[kind]<=0:
		game.toast("它喜欢"+game.data.REGIONS[kind].crop+"。现在也可以陪它待一会儿。")
		return
	game.harvest[kind]-=1
	affection=mini(100,affection+50)
	state="eat"
	timer=1.8
	game.discovered_pets[kind]=true
	game.event("feed",{"pet":kind,"affection":affection})
	game.chime()
	if affection>=100:
		game.set_companion(self)
		game.toast("它愿意陪你一起走。R 可让它在这里休息。")
	else:
		game.toast("它又靠近了一点。好感 "+str(affection)+" / 100")
