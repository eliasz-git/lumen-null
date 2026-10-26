shader_type spatial;
render_mode unshaded, cull_back;

// Red-tinted reveal for the hunter, clearly separated from white geometry.
// Bright solid red when scanned; faint dark silhouette otherwise so its
// shape is always readable.

uniform float time_since_ping : hint_range(0.0, 10.0) = 10.0;
uniform vec3 ping_origin : source_color = vec3(0.0);
uniform float ping_radius : hint_range(0.0, 40.0) = 14.0;
uniform float reveal_duration : hint_range(0.5, 6.0) = 2.2;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float reveal = 0.0;
	if (time_since_ping <= reveal_duration) {
		float d = distance(world_pos, ping_origin);
		float falloff = smoothstep(ping_radius, ping_radius * 0.3, d);
		float fade = 1.0 - smoothstep(reveal_duration * 0.3, reveal_duration, time_since_ping);
		reveal = falloff * fade;
	}

	// Faint silhouette so the hunter's shape is readable at all times.
	vec3 body = vec3(0.08, 0.08, 0.1);

	// Bright red scan returns — solid color, not sparse dots.
	vec3 red = vec3(1.0, 0.05, 0.04) * 6.0;

	vec3 col = mix(body, red, reveal);
	ALBEDO = vec3(0.0);
	EMISSION = col;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}
