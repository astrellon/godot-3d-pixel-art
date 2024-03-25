shader_type spatial;
render_mode world_vertex_coords, depth_prepass_alpha;

global uniform vec2 screen_size;

instance uniform vec2 texture_offset = vec2(0.0, 0.0);

uniform sampler2D tex: filter_nearest, source_color;
uniform vec2 texture_size = vec2(128.0, 128.0);

varying vec2 world_offset;

const float WOOD1 = 0.0;
const float WOOD2 = 1.0;
const float RED_WOOD = 2.0;
const float GLASS = 6.0;

void vertex() {
	vec4 world_pos = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	world_pos = PROJECTION_MATRIX * world_pos;
	world_offset = world_pos.xy * 0.5;
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 grid = floor(UV * 8.0);
	float grid_pos = grid.x + grid.y * 8.0;
	
	vec2 local_uv = (SCREEN_UV - world_offset + texture_offset / 32.0 + UV * 32.0) * screen_size / texture_size * 0.5;
	vec2 grid_uv = (mod(local_uv * 8.0, 1.0) + grid) / 8.0;
	vec4 col = texture(tex, grid_uv);
	ALBEDO = col.rgb;
	ALPHA = col.a;
	
	ROUGHNESS = 0.9;
	if (abs(grid_pos - GLASS) < 0.01) {
		ROUGHNESS = 0.0;
		METALLIC = 0.25;
	}
	
	//ALBEDO = vec3(SCREEN_UV.xy, 0.0);
}
