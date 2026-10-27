shader_type sky;
uniform vec4 sky_top : source_color = vec4(.63,.79,.85,1.0);
uniform vec4 sky_horizon : source_color = vec4(.88,.91,.83,1.0);
uniform float daylight=1.0;
void sky() {
	float a=atan(EYEDIR.x,EYEDIR.z);
	float elevation=EYEDIR.y;
	vec3 color=mix(sky_horizon.rgb,sky_top.rgb,smoothstep(-.03,.55,elevation));
	float far_ridge=.032+.026*sin(a*4.0)+.022*sin(a*7.0+1.0)+.009*sin(a*15.0);
	float mid_ridge=.005+.018*sin(a*5.0-2.0)+.012*sin(a*10.0);
	float near_ridge=-.024+.014*sin(a*3.0+.4)+.012*sin(a*8.0);
	color=mix(color,vec3(.62,.75,.72),1.0-smoothstep(far_ridge-.002,far_ridge+.002,elevation));
	color=mix(color,vec3(.54,.68,.62),1.0-smoothstep(mid_ridge-.002,mid_ridge+.002,elevation));
	color=mix(color,vec3(.48,.63,.51),1.0-smoothstep(near_ridge-.002,near_ridge+.002,elevation));
	COLOR=color*daylight;
}
