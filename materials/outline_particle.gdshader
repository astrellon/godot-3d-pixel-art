shader_type spatial;
render_mode depth_prepass_alpha;

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D normal_roughness_texture : hint_normal_roughness_texture, repeat_disable, filter_nearest;

group_uniforms color;
uniform vec4 albedo : source_color = vec4(0.75, 0.75, 0.75, 1.0);
uniform vec3 outline_color : source_color = vec3(0, 0, 1);
uniform vec3 edge_color : source_color = vec3(1, 0, 0);

group_uniforms outline;
uniform float depth_threshold : hint_range(0.0, 1.0, 0.01) = 0.25;
uniform float depth_normal_threshold : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float depth_normal_threshold_scale = 2.0;

group_uniforms edge;
uniform float convex_threshold = 0.5;
uniform float convex_normal_threshold : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float convex_normal_threshold_scale = 2.0;

// a little function/macro to encapsulate getting the view position
vec3 _view_from_screen(vec2 _uv, float _depth, mat4 _inv_proj) {
	vec4 _upos = _inv_proj * vec4(_uv * 2.0 - 1.0, _depth, 1.0);
	return _upos.xyz / _upos.w;
}
#define view_from_screen(uv, depth_tex) _view_from_screen((uv), textureLod((depth_tex), (uv), 0.0).r, INV_PROJECTION_MATRIX)

float remap(float value, float low1, float high1, float low2, float high2) {
    return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}



mat3 rotateX(float theta)
{
	
	float cosa = cos(theta);
	float sina = sin(theta);

 
    //Y rotation	
	mat3 rotate_x  = mat3(
	   vec3(1.0, 0.0, 0.0),
	   vec3(0.0, cosa, -sina),
	   vec3(0.0, sina, cosa)
	);
	
	return rotate_x;
}





mat3 rotateY(float theta)
{
	
	float cosa = cos(theta);
	float sina = sin(theta);

 
    //Y rotation	
	mat3 rotate_y  = mat3(
	   vec3(cosa, 0.0, sina),
	   vec3(0.0, 1.0, 0.0),
	   vec3(-sina, 0.0, cosa)
	);
	
	return rotate_y;
}



mat3 rotateZ(float theta)
{
	
	float cosa = cos(theta);
	float sina = sin(theta);

 
    //Y rotation	
	mat3 rotate_z  = mat3(
	   vec3(cosa,-sina, 0.0),
	   vec3(sina, cosa, 0.0),
	   vec3(0.0, 0.0, 1.0)
	);
	
	return rotate_z;
}


void vertex()
{
	float t = TIME + float(INSTANCE_ID);
	float x = t;
	float y = t * 0.75;
	float z = t * 0.4;
	mat3 rotation_matrix =  rotateX(x) * rotateY(y) * rotateZ(z);
	vec3 rotated_vertex =  rotation_matrix * VERTEX;
	vec3 rotated_normals =  rotation_matrix * NORMAL;

	VERTEX =  rotated_vertex;
	NORMAL =  rotated_normals;
}

void fragment() {
	ALBEDO = albedo.rgb;
	
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
	
	// same for convexity; remap normal from 0..max -> low..1
	float convex_threshold_normal_bias = remap(
		min(norm[2].z, convex_normal_threshold),
		0.0, convex_normal_threshold,
		convex_normal_threshold_scale, 1.0
	);
	float convex_thresh = convex_threshold * convex_threshold_normal_bias;
	
	if (length(edge_color) > 0.01) {
		// ===== edge ===== //
		float is_edge = 0.0;
		for (int i = 0; i < 5; i++) {
			if (i == 2) continue;
			// cross product gets convexity/concavity (mostly)
			vec3 cp = cross(norm[2], norm[i]);
			float convexity = dot(cp, vec3(offset[i].yx, 0));
			float norm_bias = i < 2 ? 1e-5 : 0.0;
			is_edge +=
				// is this below the depth threshold
				abs(pos[i].z - pos[2].z) < depth_thresh
				// is the normal more oblique; less aligned with the camera (up/left takes priority when even)
				&& norm[i].z + norm_bias > norm[2].z
				// is this a convex edge
				&& convexity > convex_thresh
				? 1.0 : 0.0;
		}
		EMISSION = is_edge > 0.0 ? edge_color : EMISSION;
	}
	
	// ===== outline ===== //
	ALBEDO =
		pos[2].z - pos[0].z > depth_thresh ||
		pos[2].z - pos[1].z > depth_thresh ||
		pos[2].z - pos[3].z > depth_thresh ||
		pos[2].z - pos[4].z > depth_thresh
		? outline_color : ALBEDO;
	
	// ===== DEBUGS ===== //
	float depth = texture(depth_texture, SCREEN_UV).r;
	// make it easier to see
	depth = remap(depth, 0.12, 1.0, 0.0, 1.0);
	//EMISSION = vec3(depth);
	//EMISSION = texture(normal_roughness_texture, SCREEN_UV).xyz * 2.0 - 1.0;
	
	//EMISSION = vec3(mix(1.0, norm[2].z, convex_normal_threshold_scale));
	//EMISSION = vec3(norm[2].z);
	//EMISSION = vec3(remap(min(norm[2].z, 0.5), 0.0, 0.5, 0.1, 1.0));
	
	//EMISSION = vec3(mix(1.0, 1.0 - norm[2].z, depth_normal_threshold_scale));
	//EMISSION = vec3(depth_thresh);
}
