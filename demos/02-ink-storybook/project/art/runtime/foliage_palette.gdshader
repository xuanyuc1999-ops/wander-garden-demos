shader_type spatial;
render_mode cull_disabled;
uniform sampler2D base_texture : source_color,filter_linear_mipmap;
uniform vec4 base_tint : source_color=vec4(1);
uniform vec4 foliage_color : source_color=vec4(.9,.4,.13,1);
uniform float glow=0.;
void fragment(){
	vec4 sample_color=texture(base_texture,UV)*base_tint;
	float foliage=smoothstep(-.025,.07,sample_color.g-sample_color.r)*smoothstep(.015,.10,sample_color.g-sample_color.b);
	float lum=dot(sample_color.rgb,vec3(.3,.5,.2));
	vec3 recolored=foliage_color.rgb*(.55+lum*.9);
	ALBEDO=mix(sample_color.rgb,recolored,foliage);
	ROUGHNESS=.92;
	EMISSION=ALBEDO*glow;
	ALPHA=sample_color.a;
	ALPHA_SCISSOR_THRESHOLD=.3;
}
