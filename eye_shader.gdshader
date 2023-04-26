shader_type canvas_item;
uniform vec2 center;
uniform float radius;
uniform float outline_width;
uniform vec2 iris_center;
uniform float iris_radius;
uniform float iris_outline_width;
uniform float eyelid_tilt_direction = 1.0;

void fragment() {
	float len = length(FRAGCOORD.xy - center);
	float iris_len = length(FRAGCOORD.xy - iris_center);
	float inside = step(len, radius);
	float white_part = step(len, radius - outline_width);
	float outline = (1.0 - step(len, radius - outline_width));
	float part_of_main_iris = step(iris_len, iris_radius - iris_outline_width);
	float part_of_iris_inc_outline = step(iris_len, iris_radius);
	float part_of_iris_outline = part_of_iris_inc_outline - part_of_main_iris;
	vec4 base_eye = white_part * vec4(1.0) + (1.0 - white_part) * vec4(vec3(0.0), 1.0);
	vec4 eye_with_iris = part_of_main_iris * vec4(vec3(0.0), 1.0) + (1.0 - part_of_main_iris) * base_eye;
	vec4 eye_with_outlined_iris = eye_with_iris * (1.0 - part_of_iris_outline) + part_of_iris_outline * vec4(0.1, 0.5, 0.3, 1.0);
	
	// eyelid
	vec2 dist = ((FRAGCOORD.xy - center) / radius);
	// first number controls amount of eyelid
	// second controls tilt
	float y = -0.3 + (dist.x / 4.5) * eyelid_tilt_direction;
	float eyelid_space = step(dist.y, y);
	
	vec4 eye_with_outline = eye_with_outlined_iris * (1.0 - outline) + outline * vec4(vec3(0.0), 1.0);
	vec4 with_eyelid = (eyelid_space * vec4(0.5, 0.5, 0.5, 1.0) + (1.0 - eyelid_space) * eye_with_outline);
	
	COLOR = with_eyelid * inside; 
}
