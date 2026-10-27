shader_type canvas_item;
uniform sampler2D scene_texture : hint_screen_texture,filter_linear;
uniform vec4 ink : source_color=vec4(.045,.065,.13,1);
float luminance(vec3 c){return dot(c,vec3(.299,.587,.114));}
void fragment(){
	vec2 p=SCREEN_PIXEL_SIZE*1.1;
	vec3 c=texture(scene_texture,SCREEN_UV).rgb;
	float tl=luminance(texture(scene_texture,SCREEN_UV+vec2(-p.x,-p.y)).rgb);
	float tc=luminance(texture(scene_texture,SCREEN_UV+vec2(0.,-p.y)).rgb);
	float tr=luminance(texture(scene_texture,SCREEN_UV+vec2(p.x,-p.y)).rgb);
	float ml=luminance(texture(scene_texture,SCREEN_UV+vec2(-p.x,0.)).rgb);
	float mr=luminance(texture(scene_texture,SCREEN_UV+vec2(p.x,0.)).rgb);
	float bl=luminance(texture(scene_texture,SCREEN_UV+vec2(-p.x,p.y)).rgb);
	float bc=luminance(texture(scene_texture,SCREEN_UV+vec2(0.,p.y)).rgb);
	float br=luminance(texture(scene_texture,SCREEN_UV+p).rgb);
	float gx=-tl-2.*ml-bl+tr+2.*mr+br;
	float gy=-tl-2.*tc-tr+bl+2.*bc+br;
	float edge=smoothstep(.32,.78,length(vec2(gx,gy)));
	vec3 quantized=floor(c*10.+.5)/10.;
	vec3 print_color=mix(c,quantized,.32);
	COLOR=vec4(mix(print_color,ink.rgb,edge*.72),1.);
}
