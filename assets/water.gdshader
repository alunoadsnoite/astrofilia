shader_type spatial;
render_mode blend_mix, cull_disabled, specular_schlick_ggx;

// Água estilizada com ondas animadas e brilho suave.

uniform vec3 deep_color : source_color = vec3(0.035, 0.210, 0.360);
uniform vec3 shallow_color : source_color = vec3(0.180, 0.660, 0.700);
uniform float wave_speed = 1.4;
uniform float wave_scale = 0.85;
uniform float opacity = 0.88;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float wx = sin(world_pos.x * wave_scale + TIME * wave_speed);
	float wz = sin(world_pos.z * wave_scale * 1.3 - TIME * wave_speed * 0.8);
	float ripple = (wx + wz) * 0.25 + 0.5;

	vec3 color = mix(deep_color, shallow_color, clamp(ripple, 0.0, 1.0));
	float sparkle = smoothstep(0.86, 1.0, sin(world_pos.x * 2.3 + TIME * 2.0) * sin(world_pos.z * 2.1 - TIME * 1.7));
	color += vec3(0.20, 0.30, 0.35) * sparkle;

	ALBEDO = color;
	ALPHA = opacity;
	ROUGHNESS = 0.10;
	METALLIC = 0.35;
	EMISSION = color * (0.10 + sparkle * 0.15);
	NORMAL = normalize(vec3(wx * 0.10, 1.0, wz * 0.10));
}
