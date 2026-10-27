shader_type spatial;
render_mode cull_disabled,specular_disabled;
uniform sampler2D base_texture : source_color,filter_linear_mipmap;
uniform bool textured=false;
uniform vec4 base_color : source_color=vec4(1.);
uniform vec4 glow_color : source_color=vec4(0.);
uniform float glow_strength=0.;
void fragment(){
	vec3 color=base_color.rgb;
	if(textured)color*=texture(base_texture,UV).rgb;
	float gray=dot(color,vec3(.299,.587,.114));
	color=clamp(mix(vec3(gray),color,.98),0.,1.);
	ALBEDO=mix(color,floor(color*7.+.5)/7.,.35);
	ROUGHNESS=1.;
	SPECULAR=0.;
	EMISSION=ALBEDO*glow_color.rgb*glow_strength;
}
void light(){
	float shade=max(0.,dot(NORMAL,LIGHT));
	vec3 tone=shade<.25 ? vec3(.18,.24,.46) : shade<.66 ? vec3(.59,.67,.83) : vec3(1.,.96,.85);
	DIFFUSE_LIGHT+=tone*LIGHT_COLOR*ATTENUATION/PI;
}
