shader_type spatial;
render_mode unshaded, cull_back;

// Red-tinted reveal for the hunter. Same fade logic as reveal.gdshader but
// always shows a menacing dark body with a red point-cloud when pinged.

uniform float time_since_ping : hint_range(0.0, 10.0) = 10.0;
uniform vec3 ping_origin : source_color = vec3(0.0);
uniform float ping_radius : hint_range(0.0, 40.0) = 14.0;
uniform float reveal_duration : hint_range(0.5, 6.0) = 2.2;

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
		float falloff = smoothstep(ping_radius, ping_radius * 0.3, d);
		float fade = 1.0 - smoothstep(reveal_duration * 0.3, reveal_duration, time_since_ping);
		reveal = falloff * fade;
	}

	// Cold dark body silhouette, red pulse reveals the hunter.
	vec3 body = vec3(0.01, 0.01, 0.015);

	vec3 h = fract(sin(local_pos * vec3(2.9, 1.9, 4.3)) * 9123.0);
	float dot = step(0.6, h.r * h.g);

	vec3 col = mix(body, vec3(1.0, 0.1, 0.05) * 3.0, reveal * dot);
	ALBEDO = vec3(0.0);
	EMISSION = col;
	ROUGHNESS = 1.0;
}