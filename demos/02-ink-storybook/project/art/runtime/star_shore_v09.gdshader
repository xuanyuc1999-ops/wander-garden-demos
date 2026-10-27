shader_type spatial;
render_mode cull_disabled;
uniform bool bank=false;
uniform vec4 shore_tint : source_color=vec4(.3,.4,.5,1);
void fragment(){
	ALBEDO=COLOR.rgb;
	ROUGHNESS=.98;
	EMISSION=COLOR.rgb*.035;
}
