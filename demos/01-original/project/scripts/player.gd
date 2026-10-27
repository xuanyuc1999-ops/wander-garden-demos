extends CharacterBody3D
const Art = preload("res://scripts/art.gd")
var pivot: Node3D
var arm: SpringArm3D
var camera: Camera3D
var visual: Node3D
var enabled = false
var photo = false
var stride = 0.0
var orbit_pitch = -0.46

func _ready() -> void:
	var c = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.31
	shape.height = 1.72
	c.shape = shape
	c.position.y = 0.86
	add_child(c)
	visual = Art.traveler(self)
	pivot = Node3D.new()
	pivot.position.y = 1.45
	add_child(pivot)
	arm = SpringArm3D.new()
	arm.spring_length = 7.4
	arm.margin = 0.22
	arm.rotation.x = orbit_pitch
	arm.add_excluded_object(get_rid())
	var probe = SphereShape3D.new()
	probe.radius = 0.16
	arm.shape = probe
	pivot.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 55
	camera.far = 230
	arm.add_child(camera)
	camera.current = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and enabled and (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)):
		pivot.rotation.y -= event.relative.x * 0.003
		orbit_pitch = clampf(orbit_pitch - event.relative.y * 0.0025, -1.1, -0.12)
		arm.rotation.x = orbit_pitch
	if event is InputEventMouseButton and enabled:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			arm.spring_length = maxf(3.0, arm.spring_length - 0.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			arm.spring_length = minf(14.0, arm.spring_length + 0.5)

func _physics_process(delta: float) -> void:
	var axis = Input.get_vector("left","right","forward","back") if enabled and not photo else Vector2.ZERO
	var direction = pivot.global_basis * Vector3(axis.x, 0, axis.y)
	direction.y = 0
	var speed = 6.5 if Input.is_action_pressed("run") else 3.6
	velocity.x = move_toward(velocity.x,direction.x*speed,delta*16)
	velocity.z = move_toward(velocity.z,direction.z*speed,delta*16)
	velocity.y -= 20.0 * delta
	if is_on_floor():
		velocity.y = -0.1
	move_and_slide()
	if direction.length() > 0.1:
		visual.rotation.y = lerp_angle(visual.rotation.y,atan2(-direction.x,-direction.z),delta*9)
	stride += delta * velocity.length() * 2.5
	var swing = sin(stride) * minf(Vector2(velocity.x,velocity.z).length()/5,0.65)
	visual.get_node("LegL").rotation.x = swing
	visual.get_node("LegR").rotation.x = -swing
	visual.get_node("ArmL").rotation.x = -swing * 0.6
	visual.get_node("ArmR").rotation.x = swing * 0.6
	if global_position.y < -8:
		global_position = Vector3(0,1,-72.0*clampi(roundi(-global_position.z/72.0),0,4))
		velocity = Vector3.ZERO
