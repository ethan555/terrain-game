shader_type canvas_item;

uniform vec4 color1 : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 color2 : source_color = vec4(1.0);

void fragment() {
	float heightRatio = COLOR.r; // r = b = g
	vec4 heightColor = mix(color1, color2, COLOR.r);
	COLOR = heightColor; // mix(COLOR, heightColor, COLOR.r);
}
