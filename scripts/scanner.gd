extends Camera3D
## LiDAR scanner. Fires rays in a forward cone and leaves a persistent point
## cloud at every hit (Scanner Sombre style). Dots are stored in a ring buffer.

@export var ray_count := 800
@export var cone_degrees := 30.0
@export var max_range := 22.0
@export var max_points := 40000
@export var dot_lifetime := 6.0
@export var size_variation := Vector2(0.45, 2.0)

var point_cloud: MultiMeshInstance3D
var multimesh: MultiMesh
var write_index := 0
var filled := 0
var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var material: ShaderMaterial
var exclude_rids: Array[RID] = []
var last_kind_hits := [0, 0, 0]   # world, hunter, exit gate (last scan)

signal scan_fired(origin: Vector3, forward: Vector3, hit_count: int)


func _ready() -> void:
	add_to_group("scanner")
	rng.randomize()
	var body := get_parent()
	while body != null and not (body is CollisionObject3D):
		body = body.get_parent()
	if body != null:
		exclude_rids.append((body as CollisionObject3D).get_rid())

	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	multimesh.mesh = quad
	multimesh.instance_count = max_points
	multimesh.visible_instance_count = 0

	point_cloud = MultiMeshInstance3D.new()
	point_cloud.multimesh = multimesh
	material = preload("res://materials/lidar_points.tres")
	material.set_shader_parameter("lifetime", dot_lifetime)
	point_cloud.material_override = material
	point_cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	point_cloud.custom_aabb = AABB(Vector3(-500, -500, -500), Vector3(1000, 1000, 1000))
	point_cloud.top_level = true
	add_child(point_cloud)
	point_cloud.global_transform = Transform3D.IDENTITY


func _process(delta: float) -> void:
	elapsed += delta
	material.set_shader_parameter("now", elapsed)


func scan() -> int:
	var origin := global_position
	var forward := -global_transform.basis.z
	var up := Vector3.UP
	if absf(forward.dot(up)) > 0.95:
		up = Vector3.RIGHT
	var right := forward.cross(up).normalized()
	up = right.cross(forward).normalized()

	var cone_rad := deg_to_rad(cone_degrees)
	var cos_max := cos(cone_rad)
	var space := get_world_3d().direct_space_state
	var hits := 0
	last_kind_hits = [0, 0, 0]

	for i in ray_count:
		var cos_theta := 1.0 - rng.randf() * (1.0 - cos_max)
		var sin_theta := sqrt(maxf(0.0, 1.0 - cos_theta * cos_theta))
		var phi := rng.randf() * TAU
		var dir := (forward * cos_theta + (right * cos(phi) + up * sin(phi)) * sin_theta).normalized()

		var query := PhysicsRayQueryParameters3D.new()
		query.from = origin
		query.to = origin + dir * max_range
		query.collision_mask = 7  # world (1) + exit gate (2) + hunter parts (4)
		query.exclude = exclude_rids
		var result := space.intersect_ray(query)
		if result.is_empty():
			continue

		var pos: Vector3 = result.position
		var normal: Vector3 = result.normal
		var dist := origin.distance_to(pos)
		var nd := clampf(dist / max_range, 0.0, 1.0)
		var kind := 0.0
		var collider: Object = result.collider
		if collider is Node:
			if (collider as Node).is_in_group("hunter"):
				kind = 1.0
			elif (collider as Node).is_in_group("beacon"):
				kind = 2.0

		_add_dot(pos, normal, dist, nd, kind, 2 if kind == 1.0 else 1)
		last_kind_hits[int(kind)] += 1
		hits += 1

	multimesh.visible_instance_count = filled
	scan_fired.emit(origin, forward, hits)
	return hits


## The hunter lights itself up: rays from all around, aimed at random points on
## its body, paint it in red dots (360 degrees, independent of the player's cone).
func paint_hunter(hunter_pos: Vector3, count: int = 90) -> void:
	var space := get_world_3d().direct_space_state
	var origin := global_position
	for i in range(count):
		var yaw := rng.randf() * TAU
		var to := hunter_pos + Vector3(0.0, rng.randf_range(0.05, 1.95), 0.0)
		var from := to + Vector3(cos(yaw), 0.0, sin(yaw)) * 2.5
		var q := PhysicsRayQueryParameters3D.new()
		q.from = from
		q.to = to
		q.collision_mask = 4
		var r := space.intersect_ray(q)
		if r.is_empty():
			continue
		var pos: Vector3 = r.position
		_add_dot(pos, r.normal, origin.distance_to(pos), 0.0, 1.0)
	multimesh.visible_instance_count = filled


func _add_dot(pos: Vector3, normal: Vector3, dist: float, nd: float, kind: float, copies: int = 1) -> void:
	var base_size := 0.018 + dist * 0.0045
	if kind == 1.0:
		base_size *= 0.6
	for c in range(copies):
		var size := base_size * rng.randf_range(size_variation.x, size_variation.y)
		var jitter := Vector3.ZERO
		if c > 0:
			jitter = Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 0.05
		var xform := Transform3D(Basis.IDENTITY.scaled(Vector3(size, size, size)), pos + normal * 0.04 + jitter)
		multimesh.set_instance_transform(write_index, xform)
		multimesh.set_instance_custom_data(write_index, Color(nd, kind, elapsed, 1.0))
		write_index = (write_index + 1) % max_points
		filled = mini(filled + 1, max_points)
