extends MeshInstance3D
## Attach to any MeshInstance3D that should be revealed by lidar pulses.
## Copies live ping state out of GameState into this mesh's material each frame.

@export var radius_override := -1.0   # -1 = use global GameState radius

func _ready() -> void:
	if material_override == null:
		push_warning("RevealMesh: no material_override set on " + name)
		return

func _process(_delta: float) -> void:
	if material_override == null:
		return
	var gs: Node = get_node("/root/GameState")
	var r: float = float(gs.reveal_duration)
	if material_override is ShaderMaterial:
		material_override.set_shader_parameter("time_since_ping", gs.ping_time)
		material_override.set_shader_parameter("ping_origin", gs.ping_origin)
		material_override.set_shader_parameter("ping_radius", radius_override if radius_override > 0.0 else gs.ping_radius)
		material_override.set_shader_parameter("reveal_duration", r)