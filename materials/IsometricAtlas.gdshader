shader_type spatial;
render_mode world_vertex_coords, depth_prepass_alpha;

global uniform vec2 screen_size;

uniform sampler2D tex: filter_nearest;
uniform vec2 texture_size = vec2(128.0, 128.0);

varying vec2 world_offset;

const float WOOD1 = 0.0;
const float WOOD2 = 1.0;
const float RED_WOOD = 2.0;

void vertex() {
	vec4 world_pos = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	world_pos = PROJECTION_MATRIX * world_pos;
	world_offset = world_pos.xy * 0.5;
}

void fragment() {
	// Called for every pixel the material is visible on.
	float grid_x = floor(UV.x * 8.0);
	float grid_y = floor(UV.y * 8.0);
	float grid_pos = grid_x + grid_y * 8.0;
	
	vec2 local_uv = (SCREEN_UV - world_offset) * screen_size / texture_size * 0.5;
	vec2 grid_uv = (mod(local_uv * 8.0, 1.0) + vec2(grid_x, grid_y)) / 8.0;
	vec4 col = texture(tex, grid_uv);
	ALBEDO = col.rgb;
	ALPHA = col.a;
}
