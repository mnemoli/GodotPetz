shader_type canvas_item;

uniform sampler2D tex : hint_default_white, filter_nearest, repeat_enable;
uniform vec2 max_uvs;
varying float max_y;
uniform vec2 center;
uniform float outline1_enabled = 1.0;
uniform float outline2_enabled = 1.0;

void vertex() {
	if(VERTEX.x > 0.0) {
		max_y = max_uvs.x * 2.0;
	} else {
		max_y = max_uvs.y * 2.0;
	}
}

void fragment() {
	float outline = step(UV.y, 1.0) * outline1_enabled;
	float outline2 = (1.0 - step(UV.y, max_y - 1.0)) * outline2_enabled;
	vec2 uv = ((FRAGCOORD.xy - center) / vec2(textureSize(tex, 0)));
	outline = outline + outline2;
	float inside = 1.0 - outline;
	COLOR = (outline * vec4(vec3(0.0), 1.0)) + (inside * texture(tex, uv));
}
