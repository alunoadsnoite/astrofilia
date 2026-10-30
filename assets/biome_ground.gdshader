shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Terreno único que mistura os três biomas de forma suave, com ruído
// para evitar faixas artificiais. Nada de z-fighting: fica 2 cm acima do piso.

uniform vec3 desert_color : source_color = vec3(0.760, 0.545, 0.340);
uniform vec3 forest_color : source_color = vec3(0.220, 0.450, 0.280);
uniform vec3 snow_color : source_color = vec3(0.880, 0.930, 0.960);
uniform float half_width = 45.0;
uniform float noise_scale = 0.45;
uniform float grain_scale = 2.8;
uniform float transition = 0.13;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.55;
	for (int i = 0; i < 4; i++) {
		value += vnoise(p) * amplitude;
		p *= 2.03;
		amplitude *= 0.5;
	}
	return value;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float t = clamp((world_pos.x + half_width) / (half_width * 2.0), 0.0, 1.0);
	float warp = (fbm(world_pos.xz * noise_scale) - 0.5) * 0.10;
	t = clamp(t + warp, 0.0, 1.0);

	// Deserto -> Floresta
	float forest_factor = smoothstep(0.30 - transition, 0.30 + transition, t);
	// Floresta -> Nevado
	float snow_factor = smoothstep(0.70 - transition, 0.70 + transition, t);

	vec3 base = mix(desert_color, forest_color, forest_factor);
	base = mix(base, snow_color, snow_factor);

	// Grãos e manchas para dar textura sem precisar de imagens.
	float coarse = fbm(world_pos.xz * grain_scale);
	float fine = vnoise(world_pos.xz * grain_scale * 7.0);
	vec3 color = base * (0.90 + coarse * 0.18 + fine * 0.05);

	// Umidade/vegetação deixa a floresta mais escura em manchas.
	float moss = smoothstep(0.55, 0.85, fbm(world_pos.xz * 1.7)) * forest_factor * (1.0 - snow_factor);
	color = mix(color, color * vec3(0.78, 0.95, 0.74), moss * 0.65);

	// Neve ganha brilho frio.
	color += snow_factor * vec3(0.035, 0.045, 0.06) * (0.4 + fine);

	ALBEDO = color;
	ROUGHNESS = mix(0.96, 0.55, snow_factor);
	SPECULAR = mix(0.04, 0.25, snow_factor);
}
