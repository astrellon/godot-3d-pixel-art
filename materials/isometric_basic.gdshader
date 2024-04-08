shader_type spatial;
render_mode world_vertex_coords, depth_prepass_alpha, cull_back;

global uniform vec2 screen_size;

uniform sampler2D tex: filter_nearest, source_color;
uniform vec2 texture_size = vec2(128.0, 128.0);

varying vec2 world_offset;

void vertex() {
	vec4 world_pos = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	world_pos = PROJECTION_MATRIX * world_pos;
	world_offset = world_pos.xy * 0.5;
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 col = texture(tex, (SCREEN_UV - world_offset) * screen_size / texture_size);
	ALBEDO = col.rgb;
	ALPHA = col.a;
}
