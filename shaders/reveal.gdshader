shader_type spatial;
render_mode unshaded, cull_back;

// LUMEN NULL reveal shader
// Surfaces are pitch black by default. After a lidar pulse, geometry within
// the pulse radius lights up as a glowing point-cloud and fades back to black.
// `show_base` adds a faint always-visible silhouette for grounding surfaces.

uniform float time_since_ping : hint_range(0.0, 10.0) = 10.0;
uniform vec3 ping_origin : source_color = vec3(0.0);
uniform float ping_radius : hint_range(0.0, 40.0) = 14.0;
uniform float reveal_duration : hint_range(0.5, 6.0) = 2.2;
uniform vec3 tint : source_color = vec3(0.35, 1.0, 0.7);
uniform float point_density : hint_range(0.0, 1.0) = 0.42;
uniform float wire_scale : hint_range(0.0, 10.0) = 1.4;
uniform bool show_base = false;

varying vec3 world_pos;
varying vec3 local_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	local_pos = VERTEX;
}

void fragment() {
	float reveal = 0.0;

	if (time_since_ping <= reveal_duration) {
		float d = distance(world_pos, ping_origin);
		float spatial_falloff = smoothstep(ping_radius, ping_radius * 0.35, d);
		float fade = 1.0 - smoothstep(reveal_duration * 0.30, reveal_duration, time_since_ping);
		reveal = spatial_falloff * fade;
	}

	// Deterministic pseudo-random dot grid from local position.
	vec3 h = fract(sin(local_pos * vec3(1.7, 2.3, 3.1)) * 43758.5453);
	float dot = step(1.0 - point_density, h.r * h.g);

	// Faint wireframe edges.
	vec3 edge = step(0.97, abs(fract(local_pos * wire_scale)));
	float wire = max(edge.r, max(edge.g, edge.b)) * 0.25;

	float lit = max(dot, wire);

	vec3 base = vec3(0.0);
	if (show_base) {
		base = vec3(0.055, 0.065, 0.075);
	}

	vec3 glow = tint * reveal * lit * 2.0;
	vec3 col = base + glow;
	ALBEDO = col;
	EMISSION = col;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}