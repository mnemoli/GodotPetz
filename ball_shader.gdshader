shader_type canvas_item;
uniform vec2 center;
uniform float radius;
uniform float outline_width;
uniform sampler2D tex : hint_default_white, filter_nearest, repeat_enable;
uniform float fuzz = 1.0;

float random(float x) {
    return fract(sin(dot(vec2(x,x),
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

float bucket(float y) {
	return trunc(y / 2.0);
}

void fragment() {
	vec2 frag = FRAGCOORD.xy;
	frag.x += (random(bucket(frag.y - center.y + radius))) * fuzz;
	float len = length(frag - center);
	float inside = step(len, radius);
	float outline = (1.0 - step(len, radius - outline_width));
	vec2 uv = ((frag - center) / vec2(textureSize(tex, 0)));
	COLOR = (outline * vec4(vec3(0.0), 1.0) + (1.0 - outline) * texture(tex, uv)) * inside;
}
