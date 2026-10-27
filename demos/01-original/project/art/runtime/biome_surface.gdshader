shader_type spatial;
uniform vec4 soil_dark : source_color=vec4(.3,.5,.4,1);
uniform vec4 soil_light : source_color=vec4(.5,.65,.5,1);
uniform vec4 path_tint : source_color=vec4(.65,.63,.47,1);
uniform vec2 region_center=vec2(0);
uniform int biome=1;
varying vec3 world_position;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise2(vec2 p){
	vec2 a=floor(p),b=fract(p);b=b*b*(3.-2.*b);
	return mix(mix(hash(a),hash(a+vec2(1,0)),b.x),mix(hash(a+vec2(0,1)),hash(a+vec2(1,1)),b.x),b.y);
}
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;}
void fragment(){
	vec2 p=world_position.xz-region_center;
	float n=noise2(p*.24);
	vec3 soil=mix(soil_dark.rgb,soil_light.rgb,n*.7+.15);
	float road=min(abs(p.x-sin(p.y*.12)*.5)-1.7,abs(p.y+10.)-.72);
	float path=1.-smoothstep(-.15,.42,road+(noise2(p*2.)-.5)*.35);
	vec3 lane=path_tint.rgb*(.95+.09*noise2(p*1.9));
	float speck=step(.97,hash(floor(p*7.)))*.045;
	if(biome==2){soil+=vec3(.07,.06,.05)*smoothstep(.64,.77,n);lane+=speck;}
	if(biome==3){
		float leaf=step(.84,hash(floor(p*4.)))*noise2(p*11.);
		soil=mix(soil,vec3(.78,.40,.16),leaf*.5);lane=mix(lane,vec3(.83,.56,.22),leaf*.4);
	}
	ALBEDO=mix(soil,lane,path);
	ROUGHNESS=.96;
	if(biome==4) EMISSION=soil*.025;
}
