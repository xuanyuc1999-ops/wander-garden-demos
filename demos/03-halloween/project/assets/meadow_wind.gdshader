shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint : source_color = vec4(0.4, 0.6, 0.3, 1.0);
void vertex() {
	float phase = TIME * 1.05 + MODEL_MATRIX[3].x * 0.32 + MODEL_MATRIX[3].z * 0.21;
	VERTEX.x += sin(phase + VERTEX.y) * VERTEX.y * 0.16;
	VERTEX.z += cos(phase * 0.7) * VERTEX.y * 0.06;
}
void fragment() {
	ALBEDO = tint.rgb;
	ROUGHNESS = 1.0;
}
