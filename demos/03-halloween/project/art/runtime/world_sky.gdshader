shader_type sky;
uniform vec4 zenith : source_color=vec4(.5,.7,.8,1);
uniform vec4 horizon : source_color=vec4(.8,.85,.8,1);
uniform vec4 ridge_color : source_color=vec4(.4,.6,.5,1);
uniform float stars=0.;
uniform float daylight=1.;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void sky(){
	float a=atan(EYEDIR.x,EYEDIR.z),e=EYEDIR.y;
	vec3 c=mix(horizon.rgb,zenith.rgb,floor(clamp((e+.03)/.68,0.,1.)*4.)/4.);
	float cloud=sin(a*3.+e*8.)*sin(a*8.-e*5.);
	c=mix(c,horizon.rgb,smoothstep(.65,.96,cloud)*.16*(1.-stars));
	float far_ridge=.025+.023*sin(a*4.)+.019*sin(a*7.+1.)+.01*sin(a*15.);
	float mid_ridge=.002+.017*sin(a*5.-2.)+.011*sin(a*10.);
	float near_ridge=-.025+.014*sin(a*3.+.4)+.011*sin(a*8.);
	c=mix(c,mix(ridge_color.rgb,horizon.rgb,.65),1.-smoothstep(far_ridge-.002,far_ridge+.002,e));
	c=mix(c,mix(ridge_color.rgb,horizon.rgb,.28),1.-smoothstep(mid_ridge-.002,mid_ridge+.002,e));
	c=mix(c,ridge_color.rgb,1.-smoothstep(near_ridge-.002,near_ridge+.002,e));
	vec2 uv=vec2(a,e)*125.;
	float dotstar=step(.989,hash(floor(uv)))*(1.-smoothstep(.06,.23,length(fract(uv)-.5)));
	c+=vec3(.67,.83,1.)*dotstar*stars*smoothstep(.08,.2,e);
	vec3 moon_dir=normalize(vec3(-.20,.12,-.97));
	float disc=1.-smoothstep(.0009,.0015,1.-dot(EYEDIR,moon_dir));
	float crescent=1.-smoothstep(.00075,.0013,1.-dot(EYEDIR,normalize(moon_dir+vec3(.025,.007,0.))));
	c=mix(c,vec3(1.,.79,.43),disc*(1.-crescent)*.85);
	COLOR=c*daylight;
}
