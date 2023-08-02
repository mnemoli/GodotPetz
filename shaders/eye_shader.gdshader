shader_type canvas_item;
uniform vec2 center;
uniform float radius;
uniform float outline_width;
uniform vec2 iris_center;
uniform float iris_radius;
uniform float iris_outline_width;
uniform float eyelid_tilt_direction = 1.0;
uniform float head_tilt_deg = 0.0;
varying flat mat2 rot_matrix;

mat2 rotationMatrix(float angle) {
	angle *= PI / 180.0;
    float s=sin(angle);
	float c=cos(angle);
    return mat2( vec2(c, -s), vec2(s, c) );
}

void vertex() {
	rot_matrix = rotationMatrix((20.0 + head_tilt_deg) * eyelid_tilt_direction);
}

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
	// number controls eyelid tilt amt
	dist = rot_matrix * dist;
	// number controls amount of eyelid
	float y = -0.3;
	float eyelid_space = step(dist.y, y);
	
	vec4 eye_with_outline = eye_with_outlined_iris * (1.0 - outline) + outline * vec4(vec3(0.0), 1.0);
	vec4 with_eyelid = (eyelid_space * vec4(0.5, 0.5, 0.5, 1.0) + (1.0 - eyelid_space) * eye_with_outline);
	
	COLOR = with_eyelid * inside;
}
