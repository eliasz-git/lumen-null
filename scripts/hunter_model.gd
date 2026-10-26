extends Node3D
## Procedural hunter body: tall, gaunt, hunched, with arms that hang to the
## knees. Each part is a StaticBody3D on collision layer 4 in the "hunter"
## group, so lidar rays paint the real silhouette (not a capsule).

var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var torso: Node3D
var head: Node3D
var phase := 0.0
var swing := 0.0


func _ready() -> void:
	torso = _body("Torso", self, Vector3(0, 1.28, 0.0), Vector3(-0.32, 0, 0))
	_capsule(torso, 0.15, 0.8, Vector3.ZERO)
	_capsule(torso, 0.1, 0.5, Vector3(0, 0.0, 0.1), Vector3(0.9, 0, 0))

	var neck := _body("Neck", torso, Vector3(0, 0.38, -0.02), Vector3(0.55, 0, 0))
	_capsule(neck, 0.05, 0.3, Vector3(0, 0.05, 0))

	head = _body("Head", neck, Vector3(0, 0.22, 0.0), Vector3(0.1, 0, 0))
	_capsule(head, 0.095, 0.36, Vector3(0, 0.04, 0))
	_sphere(head, 0.07, Vector3(0, -0.06, -0.09))

	left_arm = _limb("LeftArm", torso, Vector3(-0.27, 0.32, 0), 0.04, 1.2, 0.1)
	right_arm = _limb("RightArm", torso, Vector3(0.27, 0.32, 0), 0.04, 1.2, -0.1)
	left_leg = _limb("LeftLeg", self, Vector3(-0.12, 0.95, 0), 0.065, 0.95, 0.0)
	right_leg = _limb("RightLeg", self, Vector3(0.12, 0.95, 0), 0.065, 0.95, 0.0)


func animate(speed: float, delta: float) -> void:
	var amount := clampf(speed / 3.0, 0.0, 1.4)
	swing = lerpf(swing, amount, clampf(delta * 6.0, 0.0, 1.0))
	phase += delta * (2.0 + speed * 2.4)
	var s := sin(phase)
	left_leg.rotation.x = s * 0.7 * swing
	right_leg.rotation.x = -s * 0.7 * swing
	left_arm.rotation.x = -s * 0.5 * swing + 0.05
	right_arm.rotation.x = s * 0.5 * swing + 0.05
	torso.position.y = 1.28 + absf(s) * 0.03 * swing
	head.rotation.z = sin(phase * 0.5) * 0.08 * (0.4 + swing)


func _body(part_name: String, parent: Node3D, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.name = part_name
	b.collision_layer = 4
	b.collision_mask = 0
	b.add_to_group("hunter")
	b.position = pos
	b.rotation = rot
	parent.add_child(b)
	return b


func _capsule(parent: Node3D, radius: float, height: float, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	_attach(parent, shape, pos, rot)
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	_attach_mesh(parent, mesh, pos, rot)


func _sphere(parent: Node3D, radius: float, pos: Vector3) -> void:
	var shape := SphereShape3D.new()
	shape.radius = radius
	_attach(parent, shape, pos, Vector3.ZERO)
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	_attach_mesh(parent, mesh, pos, Vector3.ZERO)


func _limb(part_name: String, parent: Node3D, joint: Vector3, radius: float, length: float, splay: float) -> StaticBody3D:
	var b := _body(part_name, parent, joint, Vector3(0, 0, splay))
	_capsule(b, radius, length, Vector3(0, -length * 0.5, 0))
	return b


func _attach(parent: Node3D, shape: Shape3D, pos: Vector3, rot: Vector3) -> void:
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = pos
	cs.rotation = rot
	parent.add_child(cs)


func _attach_mesh(parent: Node3D, mesh: Mesh, pos: Vector3, rot: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
