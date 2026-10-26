shader_type canvas_item;

// Screen-edge darkening. Transparent in the center, dark at the corners.

uniform float vignette_amount : hint_range(0.0, 1.0) = 0.85;
uniform float inner_radius : hint_range(0.0, 1.5) = 0.35;
uniform float outer_radius : hint_range(0.0, 2.0) = 1.15;

void fragment() {
	float dist = length(UV * 2.0 - 1.0);
	float v = smoothstep(inner_radius, outer_radius, dist) * vignette_amount;
	COLOR = vec4(0.0, 0.0, 0.0, v);
}
