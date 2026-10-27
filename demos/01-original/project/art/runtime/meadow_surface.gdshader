shader_type spatial;
render_mode diffuse_burley;
uniform vec4 grass_dark : source_color = vec4(0.48,0.64,0.44,1.0);
uniform vec4 grass_light : source_color = vec4(0.68,0.76,0.53,1.0);
uniform vec4 path_color : source_color = vec4(0.76,0.69,0.52,1.0);
varying vec3 world_position;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise2(vec2 p) {
	vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float segment_distance(vec2 p,vec2 a,vec2 b) {
	vec2 ba=b-a;return length(p-a-ba*clamp(dot(p-a,ba)/dot(ba,ba),0.0,1.0));
}
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p=world_position.xz;
	float broad=noise2(p*.18);
	float fine=noise2(p*2.8);
	vec3 grass=mix(grass_dark.rgb,grass_light.rgb,broad*.75+.16);
	grass*=.985+.03*fine;
	float road=abs(p.x-sin(p.y*.12)*.5)-1.70;
	float branch=segment_distance(p,vec2(0,-10),vec2(-11,-12))-.85;
	float porch=segment_distance(p,vec2(-11,-12),vec2(-11,-16))-.92;
	float side_route=abs(p.y+10.0)-.70;
	float distance_to_path=min(road,min(branch,min(porch,side_route)));
	float edge_noise=(noise2(p*1.9)-.5)*.3;
	float path=1.0-smoothstep(-.12,.32,distance_to_path+edge_noise);
	vec3 soil=path_color.rgb*(.95+.10*noise2(p*1.4));
	float pebbles=step(.96,hash(floor(p*15.0)))*.012;
	ALBEDO=mix(grass,soil+pebbles,path);
	ROUGHNESS=.98;
}
