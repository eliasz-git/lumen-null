extends Camera3D
## LiDAR scanner. Fires rays in a forward cone and leaves a persistent point
## cloud at every hit (Scanner Sombre style). Dots are stored in a ring buffer.

@export var ray_count := 800
@export var cone_degrees := 30.0
@export var max_range := 22.0
@export var max_points := 40000

var point_cloud: MultiMeshInstance3D
var multimesh: MultiMesh
var write_index := 0
var filled := 0
var rng := RandomNumberGenerator.new()
var exclude_rids: Array[RID] = []

signal scan_fired(origin: Vector3, forward: Vector3, hit_count: int)


func _ready() -> void:
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
	point_cloud.material_override = preload("res://materials/lidar_points.tres")
	point_cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	point_cloud.custom_aabb = AABB(Vector3(-500, -500, -500), Vector3(1000, 1000, 1000))
	point_cloud.top_level = true
	add_child(point_cloud)
	point_cloud.global_transform = Transform3D.IDENTITY


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

	for i in ray_count:
		var cos_theta := 1.0 - rng.randf() * (1.0 - cos_max)
		var sin_theta := sqrt(maxf(0.0, 1.0 - cos_theta * cos_theta))
		var phi := rng.randf() * TAU
		var dir := (forward * cos_theta + (right * cos(phi) + up * sin(phi)) * sin_theta).normalized()

		var query := PhysicsRayQueryParameters3D.new()
		query.from = origin
		query.to = origin + dir * max_range
		query.collision_mask = 3
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

		var size := 0.018 + dist * 0.0045
		var xform := Transform3D(Basis.IDENTITY.scaled(Vector3(size, size, size)), pos + normal * 0.04)
		multimesh.set_instance_transform(write_index, xform)
		multimesh.set_instance_custom_data(write_index, Color(nd, kind, 0.0, 1.0))
		write_index = (write_index + 1) % max_points
		filled = mini(filled + 1, max_points)
		hits += 1

	multimesh.visible_instance_count = filled
	scan_fired.emit(origin, forward, hits)
	return hits
