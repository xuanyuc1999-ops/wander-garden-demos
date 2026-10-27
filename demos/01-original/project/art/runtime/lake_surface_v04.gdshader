shader_type spatial;
render_mode diffuse_burley,depth_draw_always;
uniform sampler2D reflection_texture : filter_linear;
uniform mat4 reflection_view;
uniform mat4 reflection_projection;
uniform bool reflection_ready=false;
uniform vec2 lake_center=vec2(13.0,5.0);
uniform vec2 lake_scale=vec2(1.0);
uniform vec4 shallow_tint : source_color=vec4(.31,.43,.32,1);
uniform vec4 deep_tint : source_color=vec4(.065,.23,.25,1);
varying vec3 world_position;
float edge_radius(vec2 p) {
	float a=atan(-p.y,p.x);
	return 5.55+.15*sin(a*3.0)+.12*sin(a*5.0+.6);
}
void vertex() {
	vec3 wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	vec2 p=(wp.xz-lake_center)/lake_scale;
	float shore=smoothstep(0.04,.65,edge_radius(p)-length(p));
	VERTEX.y+=shore*(.010*sin(wp.x*2.1+wp.z*1.5+TIME*.8+.65*sin(wp.z*.6+TIME*.2))+.006*sin(wp.x*-3.8+wp.z*2.5-TIME*.65+.4*sin(wp.x*.7-TIME*.13)));
	world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment() {
	vec2 p=(world_position.xz-lake_center)/lake_scale;
	float distance_to_edge=edge_radius(p)-length(p);
	float deep=smoothstep(.05,2.1,distance_to_edge);
	float w1=world_position.x*2.1+world_position.z*1.5+TIME*.8+.65*sin(world_position.z*.6+TIME*.2);
	float w2=world_position.x*-3.8+world_position.z*2.5-TIME*.65+.4*sin(world_position.x*.7-TIME*.13);
	float fine=world_position.x*9.7+world_position.z*5.2+TIME*1.2+.8*sin(world_position.z*1.7-TIME*.2)*sin(world_position.x*1.4+TIME*.3);
	vec2 slope=vec2(.010*2.1*cos(w1)+.006*(-3.8+.28*cos(world_position.x*.7-TIME*.13))*cos(w2)+.0018*9.7*cos(fine),.010*(1.5+.39*cos(world_position.z*.6+TIME*.2))*cos(w1)+.006*2.5*cos(w2)+.0018*5.2*cos(fine));
	vec3 wn=normalize(vec3(-slope.x,1.0,-slope.y));
	NORMAL=normalize((VIEW_MATRIX*vec4(wn,0.0)).xyz);
	float fresnel=.055+.62*pow(1.0-max(0.0,dot(NORMAL,normalize(VIEW))),3.0);
	vec4 projected=reflection_projection*reflection_view*vec4(world_position,1.0);
	vec2 uv=vec2(.5+.5*projected.x/projected.w,.5-.5*projected.y/projected.w);
	uv+=slope*.08;
	vec3 reflected=vec3(.48,.66,.68);
	if(reflection_ready && projected.w>0.0 && all(greaterThan(uv,vec2(.002))) && all(lessThan(uv,vec2(.998)))) {
		reflected=texture(reflection_texture,uv).rgb;
	}
	vec3 shallow=shallow_tint.rgb;
	vec3 depth_color=deep_tint.rgb;
	float caustic=pow(max(0.0,sin(p.x*4.0+sin(p.y*2.1)+TIME*.5)*sin(p.y*4.6+TIME*.3)),7.0)*.035*(1.0-deep);
	ALBEDO=(mix(shallow,depth_color,deep)+caustic)*(1.0-fresnel);
	EMISSION=reflected*fresnel;
	ROUGHNESS=.13;
	SPECULAR=.5;
	ALPHA=smoothstep(0.0,.14,distance_to_edge)*mix(.48,.94,deep);
}
