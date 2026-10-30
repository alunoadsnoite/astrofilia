shader_type spatial;

// Cores do planeta
uniform vec3 ocean_color : source_color = vec3(0.15, 0.4, 0.85);
uniform vec3 continent_color : source_color = vec3(0.1, 0.5, 0.2);
uniform vec3 desert_color : source_color = vec3(0.8, 0.7, 0.3);
uniform vec3 ice_color : source_color = vec3(0.9, 0.95, 1.0);

// Parâmetros de ruído
uniform float noise_scale = 3.0;
uniform float continent_threshold = 0.3;
uniform float desert_threshold = 0.6;
uniform float ice_threshold = 0.8;

// Função de ruído simples (Perlin-like)
float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	
	float n000 = hash(i + vec3(0, 0, 0));
	float n100 = hash(i + vec3(1, 0, 0));
	float n010 = hash(i + vec3(0, 1, 0));
	float n110 = hash(i + vec3(1, 1, 0));
	float n001 = hash(i + vec3(0, 0, 1));
	float n101 = hash(i + vec3(1, 0, 1));
	float n011 = hash(i + vec3(0, 1, 1));
	float n111 = hash(i + vec3(1, 1, 1));
	
	float nx00 = mix(n000, n100, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx11 = mix(n011, n111, f.x);
	
	float nxy0 = mix(nx00, nx10, f.y);
	float nxy1 = mix(nx01, nx11, f.y);
	
	return mix(nxy0, nxy1, f.z);
}

float fbm(vec3 p) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	for (int i = 0; i < 5; i++) {
		value += amplitude * noise(p * frequency);
		amplitude *= 0.5;
		frequency *= 2.0;
	}
	return value;
}

void fragment() {
	vec3 pos = NORMAL * noise_scale;
	float n = fbm(pos);
	
	vec3 color = ocean_color;
	
	// Continentes (verde)
	if (n > continent_threshold) {
		color = continent_color;
	}
	// Desertos (amarelo) - mais no meio
	if (n > desert_threshold && pos.y > 0.0) {
		color = desert_color;
	}
	// Gelo (branco) - mais nas pontas (polos)
	if (n > ice_threshold || abs(pos.y) > 0.7) {
		color = ice_color;
	}
	
	ALBEDO = color;
	ROUGHNESS = 0.7;
	METALLIC = 0.05;
}
