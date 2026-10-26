shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

// Billboarded round LiDAR dots.
// INSTANCE_CUSTOM.r = normalized distance (0 near, 1 far)
// INSTANCE_CUSTOM.g = kind (0 world, 1 hunter, 2 beacon)

varying vec2 v_info;

void vertex() {
	vec3 s = vec3(
		length(MODEL_MATRIX[0].xyz),
		length(MODEL_MATRIX[1].xyz),
		length(MODEL_MATRIX[2].xyz)
	);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0] * s.x,
		INV_VIEW_MATRIX[1] * s.y,
		INV_VIEW_MATRIX[2] * s.z,
		MODEL_MATRIX[3]
	);
	v_info = INSTANCE_CUSTOM.rg;
}

void fragment() {
	if (length(UV - vec2(0.5)) > 0.5) {
		discard;
	}
	float d = clamp(v_info.x, 0.0, 1.0);
	vec3 near_c = vec3(1.0, 0.85, 0.2);
	vec3 mid_c = vec3(1.0, 0.25, 0.55);
	vec3 far_c = vec3(0.35, 0.3, 1.0);
	vec3 col = d < 0.5 ? mix(near_c, mid_c, d * 2.0) : mix(mid_c, far_c, (d - 0.5) * 2.0);
	if (v_info.y > 1.5) {
		col = vec3(0.0, 0.95, 1.0);
	} else if (v_info.y > 0.5) {
		col = vec3(1.0, 0.04, 0.04);
	}
	// unshaded: ALBEDO is the final color.
	ALBEDO = pow(col, vec3(2.2));
}
