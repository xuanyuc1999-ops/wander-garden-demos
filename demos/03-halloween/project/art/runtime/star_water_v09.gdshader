shader_type spatial;
render_mode diffuse_burley,depth_draw_always;
uniform sampler2D reflection_texture : filter_linear;
uniform mat4 reflection_view;
uniform mat4 reflection_projection;
uniform bool reflection_ready=false;
uniform vec2 lake_center=vec2(13.0,-283.0);
uniform vec2 lake_scale=vec2(1.0);
uniform vec4 shallow_tint : source_color=vec4(.25,.46,.53,1);
uniform vec4 deep_tint : source_color=vec4(.10,.19,.34,1);
varying vec3 world_position;
varying vec4 face_color;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float edge_radius(vec2 p){
	float a=atan(-p.y/.94,p.x);
	return 5.22+.25*sin(a*3.+.5)+.14*sin(a*7.);
}
void vertex(){
	vec3 wp=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
	vec2 p=(wp.xz-lake_center)/lake_scale;
	float edge=edge_radius(p)-length(p/vec2(1.,.94));
	float weight=smoothstep(.1,1.,edge);
	// Broad, slow motion on the real triangulated surface; no stripe texture.
	VERTEX.y+=weight*(sin(wp.x*.43+wp.z*.31+TIME*.42)*.012
		+sin(wp.x*-.29+wp.z*.51-TIME*.30)*.007);
	world_position=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
	face_color=COLOR;
}
void fragment(){
	vec2 p=(world_position.xz-lake_center)/lake_scale;
	float edge=edge_radius(p)-length(p/vec2(1.,.94));
	float depth=smoothstep(.05,2.3,edge);
	float facet=.93+.12*face_color.r;
	vec3 water=mix(shallow_tint.rgb,deep_tint.rgb,depth)*facet;
	float fresnel=.08+.25*pow(1.-max(0.,dot(NORMAL,normalize(VIEW))),3.);
	vec4 projected=reflection_projection*reflection_view*vec4(world_position,1.);
	vec2 uv=vec2(.5+.5*projected.x/projected.w,.5-.5*projected.y/projected.w);
	vec3 reflection=vec3(.18,.25,.43);
	if(reflection_ready && projected.w>0. && all(greaterThan(uv,vec2(.002))) && all(lessThan(uv,vec2(.998))))
		reflection=texture(reflection_texture,uv).rgb;
	vec2 cell=floor(p*1.5),local=fract(p*1.5)-.5;
	float star=step(.91,hash(cell))*(1.-smoothstep(.01,.035,length(local)));
	float twinkle=.25+.75*pow(.5+.5*sin(TIME*.7+hash(cell)*6.283),3.);
	float rim=(1.-smoothstep(.02,.16,edge))*smoothstep(-.02,.04,edge);
	ALBEDO=water*(1.-fresnel)+vec3(.20,.32,.36)*rim*.18;
	EMISSION=reflection*fresnel+vec3(.50,.70,.76)*star*twinkle*smoothstep(.3,.8,edge);
	ROUGHNESS=.38;
	SPECULAR=.25;
	ALPHA=smoothstep(-.035,.08,edge)*mix(.78,.98,depth);
}
