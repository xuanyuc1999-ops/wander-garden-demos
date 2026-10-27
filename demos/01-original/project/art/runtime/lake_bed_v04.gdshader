shader_type spatial;
uniform bool bank=false;
uniform vec4 shore_tint : source_color=vec4(.48,.63,.43,1);
varying vec3 world_position;
float noise(vec2 p) { return fract(sin(dot(floor(p),vec2(127.1,311.7)))*43758.5453); }
void vertex() {world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment() {
	float grain=noise(world_position.xz*24.0);
	vec3 sand=mix(vec3(.40,.40,.26),vec3(.51,.52,.36),grain*.22+.3);
	if(bank) sand=mix(sand,shore_tint.rgb,smoothstep(.4,.95,UV.x));
	ALBEDO=sand;
	ROUGHNESS=.98;
	if(bank) ALPHA=1.0-smoothstep(.65,1.0,UV.x);
}
