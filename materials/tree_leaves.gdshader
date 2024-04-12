shader_type spatial;
render_mode depth_prepass_alpha;

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D normal_roughness_texture : hint_normal_roughness_texture, repeat_disable, filter_nearest;

uniform sampler2D albedo : source_color, filter_nearest;

group_uniforms outline;
uniform float depth_threshold : hint_range(0.0, 1.0, 0.01) = 0.25;
uniform float depth_normal_threshold : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float depth_normal_threshold_scale = 2.0;

// a little function/macro to encapsulate getting the view position
vec3 _view_from_screen(vec2 _uv, float _depth, mat4 _inv_proj) {
	vec4 _upos = _inv_proj * vec4(_uv * 2.0 - 1.0, _depth, 1.0);
	return _upos.xyz / _upos.w;
}
#define view_from_screen(uv, depth_tex) _view_from_screen((uv), textureLod((depth_tex), (uv), 0.0).r, INV_PROJECTION_MATRIX)

float remap(float value, float low1, float high1, float low2, float high2) {
    return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

varying float instance_id;

void vertex() {
	instance_id = float(INSTANCE_ID);
	float t = TIME + instance_id;
	
	VERTEX += vec3(sin(t * 0.5), cos(t * 0.65), sin(t * 0.1)) * 0.05;
	NORMAL = normalize(VERTEX);
	
	vec3 local_up = MODEL_MATRIX[1].xyz;
	//cross of:
	//	local_transform.basis.y     and    to_world(view_space.forward)
	//normalized
	//(represents right direction)
	vec4 ax = vec4(normalize(cross(local_up, INV_VIEW_MATRIX[2].xyz)), 0.0);
	//local_transform.basis.y
	//(represents up direction)
	vec4 ay = vec4(local_up.xyz, 0.0);
	//cross of:
	//	to_world(view_space.right)    and    local_transform.basis.y
	//(represents forward direction)
	vec4 az = vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, local_up)), 0.0);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(ax, ay, az, MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	float x_offset = mod(instance_id, 2.0);
	float y_offset = floor(instance_id * 0.5);
	vec2 uv_offset = vec2(x_offset, y_offset) * 0.5;
	vec2 uv = UV * 0.5 + uv_offset;
	vec4 col = texture(albedo, uv);
	ALBEDO = col.rgb;
	ALPHA = col.a;
	
	if (ALPHA < 0.1) {
		discard;
	}
	
	vec2 texel_size = 1.0 / VIEWPORT_SIZE;
	
	vec2 offset[5] = {
					 vec2(-1, 0),
		vec2(0, -1), vec2( 0, 0), vec2(0, 1),
					 vec2( 1, 0)
	};
	vec3 pos[5];
	vec3 norm[5];
	
	// loop over offsets
	for (int i = 0; i < 5; i++) {
		// fragment uv + neighbour offset
		vec2 uv = SCREEN_UV + offset[i] * texel_size;
		// fragment position in view space
		pos[i] = view_from_screen(uv, depth_texture);
		// fragment normal in view space
		norm[i] = texture(normal_roughness_texture, uv).xyz * 2.0 - 1.0;
	}
	
	// scale depth threshold based on view normal; remap normal from min..1 -> 1..max
	float depth_threshold_normal_bias = remap(
		// NOTE(david): in orthogonal projections, normal.z is equivalent to dot(normal, -view_forward)
		max(depth_normal_threshold, 1.0 - norm[2].z),
		depth_normal_threshold, 1.0,
		1.0, depth_normal_threshold_scale
	);
	
	// final depth threshold
	float depth_thresh = depth_threshold * depth_threshold_normal_bias;
	
	// ===== outline ===== //
	ALBEDO =
		pos[2].z - pos[0].z > depth_thresh ||
		pos[2].z - pos[1].z > depth_thresh ||
		pos[2].z - pos[3].z > depth_thresh ||
		pos[2].z - pos[4].z > depth_thresh
		? ALBEDO * 0.25 : ALBEDO;
		
	ROUGHNESS = 0.9;
	METALLIC = 0.1;
}
