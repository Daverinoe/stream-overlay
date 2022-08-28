shader_type canvas_item; 

uniform sampler2D noise;

uniform vec4 color_base: hint_color;

uniform vec4 color_border: hint_color;
uniform float border_size: hint_range(0.0, 0.1);

uniform float direction: hint_range(-1.0, 1.0) = -1.0;

uniform float edge_size: hint_range( 0.0, 0.2);


void fragment() 
{
	vec4 color = color_base;
	
	vec2 uv = mod(vec2(UV.x * 0.25 + TIME * direction, 0.0), 1.0); 
	uv.y = UV.y;
	float noise_value = texture(noise, uv).r; 
	
	if (noise_value > 0.65) 
	{
		color = mix(vec4(1.0), color_base, 0.4);
	} 
	
	if (UV.y < border_size || UV.y > 1.0 - border_size) 
	{
		color = color_border;
	}
	
	float edge_offset = ((sin(uv.y * 10.0 + TIME * 10.0) + 1.0) / 2.0) * edge_size;
	if (UV.x + edge_offset <  edge_size || UV.x - edge_offset > 1.0 - edge_size) 
	{
		color = vec4(0.0);
	}
	
	COLOR = color;
}