shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

// Billboarded round LiDAR dots.
// INSTANCE_CUSTOM.r = unused (reserved)
// INSTANCE_CUSTOM.g = kind (0 world, 1 hunter, 2 beacon)
// INSTANCE_CUSTOM.b = spawn time (same clock as `now`)
// INSTANCE_CUSTOM.w = lifetime multiplier (scan-type specific)

uniform float now = 0.0;
uniform float lifetime : hint_range(0.5, 30.0) = 6.0;

varying vec3 v_info;

void vertex() {
	vec3 s = vec3(
		length(MODEL_MATRIX[0].xyz),
		length(MODEL_MATRIX[1].xyz),
		length(MODEL_MATRIX[2].xyz)
	);
	float age = clamp((now - INSTANCE_CUSTOM.b) / (lifetime * INSTANCE_CUSTOM.w), 0.0, 1.0);
	s *= mix(1.0, 0.35, age);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0] * s.x,
		INV_VIEW_MATRIX[1] * s.y,
		INV_VIEW_MATRIX[2] * s.z,
		MODEL_MATRIX[3]
	);
	v_info = vec3(INSTANCE_CUSTOM.r, INSTANCE_CUSTOM.g, age);
}

void fragment() {
	if (length(UV - vec2(0.5)) > 0.5) {
		discard;
	}
	if (v_info.z >= 1.0) {
		discard;
	}
	vec3 col = vec3(0.92, 0.97, 1.0);
	if (v_info.y > 1.5) {
		col = vec3(0.0, 0.95, 1.0);
	} else if (v_info.y > 0.5) {
		col = vec3(1.0, 0.04, 0.04);
	}
	// unshaded: ALBEDO is the final color.
	float fade = 1.0 - smoothstep(0.3, 1.0, v_info.z);
	ALBEDO = pow(col, vec3(2.2)) * fade;
}
