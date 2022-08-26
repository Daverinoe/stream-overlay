shader_type canvas_item;

uniform sampler2D NOISE;
uniform float intermission;

uniform float speedAdjustment = 8.0;

uniform float border = 25.0;

vec4 Noise(vec2 x){
	return texture(NOISE, (vec2(x)+0.5) /256.0, -100.0 );
}

void fragment(){
	vec2 borderv = vec2(border/1920.0, border/1080.0);
	vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;
	
	if (UV.x < borderv.x || UV.x > 1.0 - borderv.x || UV.y < borderv.y || UV.y > 1.0 - borderv.y){
		
		vec3 ray;
		ray.xy = 2.0 * (FRAGCOORD.xy - iResolution.xy * .5) / iResolution.x + vec2(cos(TIME / 20.0) * 2.0, sin(TIME / 20.0) * 2.0) * intermission;
		ray.z = 1.0;

		float offset = TIME / speedAdjustment;
		float speed2 = (cos(offset) + 1.0) * 2.0;
		float speed = speed2 + 0.1;
	//	offset += sin(offset) * 0.96;
		offset *= 2.0;
		
		
		vec3 col = vec3(0);
		
		vec3 stp = ray / max(abs(ray.x),abs(ray.y));
		
		vec3 pos = 2.0 * stp + 0.5;
		for ( int i=0; i < 20; i++ )
		{
			float z = float(Noise(vec2(pos.xy)).x);
			z = fract(z - offset);
			float d = 50.0 * z - pos.z;
			float w = pow(max(0.0, 1.0 - 8.0 * length(fract(pos.xy) - 0.5)), 2.0);
			vec3 c = max(vec3(0), vec3(1.0 - abs(d + speed2 * .5) / speed, 1.0 - abs(d) / speed, 1.0 - abs(d - speed2 * 0.5) / speed));
			col += 1.5 * (1.0 - z) * c * w;
			pos += stp;
		}
		
		COLOR = vec4(col, 1.0);
	} else {
		COLOR = vec4(0.0);
	}
}