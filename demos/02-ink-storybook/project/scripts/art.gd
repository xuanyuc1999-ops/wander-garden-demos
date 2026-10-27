extends RefCounted
# Editable geometry for the spatial/color prototype; no generated Lux3D assets.
static var materials: Dictionary = {}

static func mat(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var key = str(color) + str(glow)
	if materials.has(key):
		return materials[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.92
	if glow > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	materials[key] = m
	return m

static func mesh(parent: Node3D, shape: Mesh, pos: Vector3, color: Color, glow: float = 0.0) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	n.mesh = shape
	n.position = pos
	n.material_override = mat(color, glow)
	parent.add_child(n)
	return n

static func ball(parent: Node3D, pos: Vector3, size: Vector3, color: Color, glow: float = 0.0) -> MeshInstance3D:
	var s = SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 10
	s.rings = 5
	var n = mesh(parent, s, pos, color, glow)
	n.scale = size
	return n

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var s = BoxMesh.new()
	s.size = size
	return mesh(parent, s, pos, color)

static func cylinder(parent: Node3D, pos: Vector3, bottom: float, top: float, height: float, color: Color, glow: float = 0.0) -> MeshInstance3D:
	var s = CylinderMesh.new()
	s.bottom_radius = bottom
	s.top_radius = top
	s.height = height
	s.radial_segments = 9
	return mesh(parent, s, pos, color, glow)

static func solid(parent: Node3D, pos: Vector3, size: Vector3) -> StaticBody3D:
	var b = StaticBody3D.new()
	b.position = pos
	var c = CollisionShape3D.new()
	var s = BoxShape3D.new()
	s.size = size
	c.shape = s
	b.add_child(c)
	parent.add_child(b)
	return b

static func tree(parent: Node3D, pos: Vector3, color: Color, size: float, kind: int) -> Node3D:
	var n = Node3D.new()
	n.position = pos
	n.scale = Vector3.ONE * size
	parent.add_child(n)
	cylinder(n, Vector3(0, 1.8, 0), 0.27, 0.16, 3.6, Color("#766c59"))
	if kind == 1:
		for i in range(3):
			cylinder(n, Vector3(0, 2.6 + i * 0.85, 0), 1.65 - i * 0.32, 0.10, 2.0, color.lightened(i * 0.05))
	else:
		ball(n, Vector3(0, 3.7, 0), Vector3(3.3, 2.8, 3.0), color)
		ball(n, Vector3(-1.0, 3.2, 0.3), Vector3(2.1, 2.0, 2.4), color.darkened(0.05))
		ball(n, Vector3(0.9, 3.35, -0.25), Vector3(2.4, 2.5, 2.3), color.lightened(0.07))
	return n

static func flower(parent: Node3D, pos: Vector3, color: Color, size: float = 1.0, glow: float = 0.0) -> Node3D:
	var n = Node3D.new()
	n.position = pos
	n.scale = Vector3.ONE * size
	parent.add_child(n)
	cylinder(n, Vector3(0, 0.25, 0), 0.025, 0.018, 0.5, Color("#658572"))
	ball(n, Vector3(0.1, 0.18, 0), Vector3(0.27, 0.07, 0.14), Color("#86a97e"))
	for j in range(5):
		var angle = j * TAU / 5.0
		ball(n, Vector3(cos(angle)*0.14, 0.48, sin(angle)*0.14), Vector3(0.22, 0.10, 0.22), color, glow)
	ball(n, Vector3(0, 0.51, 0), Vector3(0.14, 0.13, 0.14), Color("#f5df9a"), glow)
	return n

static func mushroom(parent: Node3D, pos: Vector3, color: Color, size: float) -> Node3D:
	var n = Node3D.new()
	parent.add_child(n)
	n.position = pos
	n.scale = Vector3.ONE * size
	cylinder(n, Vector3(0,0.22,0), 0.09,0.07,0.45,Color("#e3d9b9"))
	ball(n, Vector3(0,0.48,0), Vector3(0.65,0.30,0.65),color)
	ball(n, Vector3(0.12,0.59,0),Vector3(0.10,0.03,0.09),Color("#f8ebcc"))
	return n

static func animal(parent: Node3D, kind: int) -> Node3D:
	var n = Node3D.new()
	parent.add_child(n)
	var colors = [Color("#f2e5cf"),Color("#ce8256"),Color("#9c8c76"),Color("#ac7451"),Color("#a6dace")]
	var c: Color = colors[kind]
	ball(n,Vector3(0,0.38,0.05),Vector3(0.65,0.63,0.88),c)
	ball(n,Vector3(0,0.66,-0.35),Vector3(0.57,0.52,0.55),c)
	ball(n,Vector3(0,0.55,-0.60),Vector3(0.30,0.19,0.20),c.lightened(0.22))
	for side in [-1,1]:
		ball(n,Vector3(side*0.17,0.72,-0.57),Vector3(0.065,0.075,0.045),Color("#343e3b"))
		ball(n,Vector3(side*0.23,0.12,0.13),Vector3(0.19,0.21,0.34),c.darkened(0.05))
		if kind == 0:
			var ear = ball(n,Vector3(side*0.16,1.06,-0.33),Vector3(0.17,0.66,0.18),c)
			ear.rotation.z = side * -0.15
			ball(n,Vector3(side*0.16,1.08,-0.42),Vector3(0.07,0.39,0.03),Color("#d9afa7"))
		elif kind in [1,3]:
			cylinder(n,Vector3(side*0.19,0.97,-0.31),0.17,0.01,0.34,c)
		else:
			ball(n,Vector3(side*0.23,0.86,-0.31),Vector3(0.18,0.19,0.15),c)
	if kind == 0:
		ball(n,Vector3(0,0.4,0.53),Vector3.ONE*0.30,c.lightened(0.1))
	elif kind == 1 or kind == 3:
		var tail = ball(n,Vector3(0.18,0.55,0.66),Vector3(0.45,0.60 if kind==3 else 0.36,0.98),c)
		tail.rotation.x = -0.6 if kind==3 else 0.25
		ball(n,Vector3(0.18,0.81 if kind==3 else 0.48,1.02),Vector3.ONE*0.34,c.lightened(0.28))
	elif kind == 2:
		ball(n,Vector3(0,0.19,0.65),Vector3(0.35,0.16,0.75),c)
	else:
		ball(n,Vector3(0,0.45,0.42),Vector3.ONE*0.50,Color("#d8eec2"),1.2)
		for side in [-1,1]:
			ball(n,Vector3(side*0.45,0.52,0.05),Vector3(0.65,0.08,0.42),Color("#c3e5ed"),0.3)
	return n

static func traveler(parent: Node3D) -> Node3D:
	var n = Node3D.new()
	parent.add_child(n)
	cylinder(n,Vector3(0,0.78,0),0.30,0.24,0.72,Color("#d3b99b"))
	ball(n,Vector3(0,1.39,-0.02),Vector3(0.46,0.48,0.44),Color("#f2d2b0"))
	cylinder(n,Vector3(0,1.62,0),0.48,0.48,0.07,Color("#d3af73"))
	cylinder(n,Vector3(0,1.75,0),0.28,0.23,0.25,Color("#dfc28d"))
	ball(n,Vector3(0,0.91,0.25),Vector3(0.46,0.58,0.28),Color("#647f75"))
	for side in [-1,1]:
		var leg = cylinder(n,Vector3(side*0.15,0.27,0),0.09,0.09,0.46,Color("#53665d"))
		leg.name = "LegL" if side==-1 else "LegR"
		ball(n,Vector3(side*0.15,0.08,-0.08),Vector3(0.20,0.16,0.32),Color("#6e6352"))
		var arm = cylinder(n,Vector3(side*0.34,0.80,0),0.085,0.10,0.50,Color("#cbb18f"))
		arm.name = "ArmL" if side==-1 else "ArmR"
	return n
