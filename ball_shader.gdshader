shader_type canvas_item;
uniform vec2 center;
uniform float radius;
uniform float outline_width;
uniform sampler2D tex : hint_default_white, filter_nearest, repeat_enable;

void fragment() {
	float outline = 1.0 - step(length(FRAGCOORD.xy - center), radius - outline_width);
	vec2 uv = ((FRAGCOORD.xy - center) / vec2(textureSize(tex, 0)));
	COLOR = outline * vec4(vec3(0.0), 1.0) + (1.0 - outline) * texture(tex, uv);
	
}
