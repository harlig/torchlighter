shader_type spatial;
render_mode cull_disabled;

uniform sampler2D albedo: source_color;
uniform bool flip_h = false;
uniform bool highlight = false;
uniform vec3 highlight_color : source_color;

void fragment() {
	vec2 uv = UV;

	if (flip_h) {
		uv.x = 1.0 - uv.x;
	}

	vec4 tex = texture(albedo, uv);

	ALBEDO = vec3(0.0);

	if (highlight) {
		vec4 highlight_tex = texture(albedo, uv * 0.93 + vec2(0.035, 0.05));
		ALPHA = highlight_tex.a;
		ALBEDO += vec3(highlight_color * 2.0) * (highlight_tex.a - tex.a);
	} else {
		ALPHA = tex.a;
	}

	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
