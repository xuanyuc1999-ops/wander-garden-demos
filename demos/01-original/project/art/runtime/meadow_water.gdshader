shader_type spatial;
render_mode diffuse_burley;
varying vec3 world_position;
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p=world_position.xz-vec2(13.0,5.0);
	float rim=smoothstep(5.0,5.95,length(p));
	float wave=sin(p.x*3.0+p.y*2.4+TIME*.7)*sin(p.x*1.3-p.y*3.5-TIME*.5);
	float spark=pow(max(0.0,wave),12.0)*.13;
	ALBEDO=mix(vec3(.27,.56,.58),vec3(.55,.72,.65),rim)+spark;
	ROUGHNESS=.35;
	SPECULAR=.35;
}
