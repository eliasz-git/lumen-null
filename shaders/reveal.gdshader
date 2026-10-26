shader_type spatial;
render_mode unshaded, cull_back;

// LUMEN NULL reveal shader
// Surfaces are pitch black by default. After a lidar pulse, geometry within
// the pulse radius lights up only as a glowing point-cloud and fades to black.
// `show_base` adds a faint always-visible silhouette for grounding surfaces.

uniform float time_since_ping : hint_range(0.0, 10.0) = 10.0;
uniform vec3 ping_origin : source_color = vec3(0.0);
uniform float ping_radius : hint_range(0.0, 40.0) = 14.0;
uniform float reveal_duration : hint_range(0.5, 6.0) = 2.2;
uniform vec3 tint : source_color = vec3(0.35, 1.0, 0.7);
uniform float point_density : hint_range(0.0, 1.0) = 0.42;
uniform bool show_base = false;

varying vec3 world_pos;
varying vec3 local_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	local_pos = VERTEX;
	world_normal = normalize(mat3(MODEL_MATRIX) * NORMAL);
}

void fragment() {
	float reveal = 0.0;

	if (time_since_ping <= reveal_duration) {
		float d = distance(world_pos, ping_origin);
		float spatial_falloff = smoothstep(ping_radius, ping_radius * 0.35, d);
		float fade = 1.0 - smoothstep(reveal_duration * 0.30, reveal_duration, time_since_ping);
		reveal = spatial_falloff * fade;
	}

	// Fine, irregular scan returns. World space keeps the pattern consistent
	// across scaled walls while the high frequency creates the earlier
	// twinkling point-cloud look without wireframe lines.
	vec3 h = fract(sin(world_pos * vec3(5.2, 7.1, 9.3)) * 43758.5453);
	float dot = step(1.0 - point_density, h.r * h.g);
	float lit = dot;

	vec3 base = vec3(0.0);
	if (show_base) {
		base = vec3(0.055, 0.065, 0.075);
	}

	vec3 glow = tint * reveal * lit * 4.0;
	vec3 col = base + glow;
	ALBEDO = col;
	EMISSION = col;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}
