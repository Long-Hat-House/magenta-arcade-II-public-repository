shader_type spatial;
render_mode diffuse_toon;
render_mode specular_toon;


varying vec3 world_pos;
uniform sampler2D normal_tex: repeat_enable;

uniform sampler2D noise_texture: repeat_enable;
uniform sampler2D color_gradient: repeat_disable;
uniform float fresnelImpact = 1.0;

//uniform sampler2D displ_tex: repeat_enable;
uniform vec4 top_light_color : source_color;
uniform vec4 top_dark_color : source_color;
uniform vec4 bot_light_color : source_color;
uniform vec4 bot_dark_color : source_color;
//uniform float displ_amount = 0.1;
uniform float refraction = 0.1;
uniform float refraction_size = 0.4;
uniform float normal_effect = 0.1;
uniform float noise_speed = 0.25;
uniform float wave_speed = 0.5;
 
void vertex(){
	world_pos = (MODEL_MATRIX*vec4(VERTEX, 1.0)).xyz;
}
float fresnel(float amount, vec3 normal, vec3 view)
{
    return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}
void fragment()
{

		
	//normal
	//float f = 1.0 - fresnel(1.0, NORMAL, VIEW);
	vec3 normalX = texture(normal_tex, world_pos.xz * refraction_size + vec2(TIME * noise_speed, 0)).xyz;
	vec3 normalY = texture(normal_tex, world_pos.xz * refraction_size * 0.25 + vec2( 0, TIME * noise_speed * 2.0)).xyz;
	NORMAL = mix(normalX, normalY, 0.5);
	vec2 normal = NORMAL.xz;
	
	
	normal = ((normal * 2.0) - 1.0) * refraction;
	NORMAL = ((NORMAL * 2.0) -1.0) * normal_effect;
	float f = fresnel(1.0, NORMAL, VIEW);
	float f_global = fresnel(4.0, NORMAL, vec3(0, -1.0, 0.5));

	float velocity = TIME * wave_speed / 10.0;
		
	float noiseX =  texture(noise_texture, world_pos.xz * 0.4 + vec2(0,velocity) + normal).x;
	float noiseY =  texture(noise_texture, world_pos.xz * 0.2 + vec2(velocity , 0) + normal).y;
	
	float noise = mix(noiseX, noiseY,0.5);
	noise =  floor(noise * 4.0) / 4.0;
//	f = 0.0;
	//vec4 col = mix(mix(top_dark_color, bot_dark_color, f), mix(top_light_color, bot_light_color, f), noise);
	if(f_global > 0.2 && f_global < 0.6)
	{
	ALBEDO = top_light_color.rgb;
	}
	else
	{
	vec4 col = texture(color_gradient, vec2(noise + f * fresnelImpact , 0));
	col = pow(col,vec4(2.2));
	ALBEDO =  col.xyz;
	}
	
	
	
}