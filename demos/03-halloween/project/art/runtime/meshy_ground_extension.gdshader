shader_type spatial;
render_mode cull_disabled;
uniform sampler2D autumn_ground : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D stars_ground : source_color,filter_linear_mipmap,repeat_enable;
varying vec3 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
	float region=clamp(floor(-world_position.z/72.+.5),0.,4.);
	vec2 uv=vec2(world_position.x/50.+.5,.5-(world_position.z+region*72.)/56.);
	vec3 color=COLOR.rgb;
	float shade=clamp(dot(color,vec3(.299,.587,.114)),.1,1.);
	if(region<.5)color=mix(vec3(.24,.15,.27),vec3(.48,.32,.38),shade);
	else if(region<1.5)color=mix(vec3(.18,.18,.31),vec3(.34,.42,.47),shade);
	else if(region<2.5)color=mix(vec3(.39,.43,.52),vec3(.63,.71,.77),shade);
	if(region>2.5 && region<3.5)color=texture(autumn_ground,uv).rgb*.82;
	else if(region>3.5)color=texture(stars_ground,uv).rgb*.92;
	ALBEDO=color;
	ROUGHNESS=.96;
}
