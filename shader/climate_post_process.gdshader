shader_type canvas_item;
// Clima emocional de Eva.
//   climate 0.0  -> desesperanza: casi blanco y negro, frío, oscuro, grano, viñeta
//   climate 0.5  -> calidez: cálido y colorido
//   climate 1.0  -> descontrol: sobresaturado, distorsión, aberración, pulso
// effect_mix: 0 = imagen original (flashbacks/pesadillas/créditos), 1 = efecto completo.

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform float climate : hint_range(0.0, 1.0) = 0.15;
uniform float effect_mix : hint_range(0.0, 1.0) = 0.0;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 suv = SCREEN_UV;
	vec3 raw = texture(screen_tex, suv).rgb;

	float lo = clamp(climate / 0.5, 0.0, 1.0);            // 0 = desesperanza, 1 = punto medio
	float hi = clamp((climate - 0.5) / 0.5, 0.0, 1.0);    // 0 = punto medio, 1 = descontrol
	float despair = 1.0 - lo;
	float hi2 = hi * hi;
	bool upper = climate >= 0.5;

	// Distorsión ondulante (solo en la zona de descontrol)
	float warp = hi2 * 0.006 * intensity;
	vec2 uv = suv + vec2(
		sin(suv.y * 20.0 + TIME * 2.5),
		cos(suv.x * 16.0 + TIME * 2.0)
	) * warp;

	// Aberración cromática
	vec2 dir = normalize(uv - vec2(0.5) + 0.0001);
	float ca = (hi2 * 0.006 + despair * despair * 0.0008) * intensity;
	vec3 col;
	col.r = texture(screen_tex, uv + dir * ca).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - dir * ca).b;

	// Saturación
	float sat = upper ? mix(1.25, 3.0, hi) : mix(0.10, 1.25, lo);
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(lum), col, mix(1.0, sat, intensity));

	// Contraste
	float contrast = upper ? mix(1.05, 1.40, hi) : mix(1.12, 1.05, lo);
	col = (col - 0.5) * mix(1.0, contrast, intensity) + 0.5;

	// Tinte: frío -> cálido -> caliente/magenta
	vec3 cold = vec3(0.78, 0.88, 1.06);
	vec3 warm = vec3(1.06, 0.98, 0.88);
	vec3 hot = vec3(1.12, 0.88, 1.02);
	vec3 tint = upper ? mix(warm, hot, hi) : mix(cold, warm, lo);
	col *= mix(vec3(1.0), tint, intensity);

	// Brillo
	float bright = upper ? mix(1.0, 1.10, hi) : mix(0.78, 1.0, lo);
	col *= mix(1.0, bright, intensity);

	// Grano de película en desesperanza
	float grain = (hash(suv * 600.0 + vec2(fract(TIME) * 10.0)) - 0.5) * 0.08 * despair * despair * intensity;
	col += vec3(grain);

	// Viñeta: fuerte en desesperanza, pulsante en descontrol
	float d = distance(suv, vec2(0.5));
	float pulse = 0.5 + 0.5 * sin(TIME * (2.0 + hi * 6.0));
	float vig = despair * 0.65 + hi * 0.3 * pulse;
	col *= 1.0 - smoothstep(0.30, 0.85, d) * vig * intensity;

	COLOR = vec4(mix(raw, clamp(col, 0.0, 1.0), effect_mix), 1.0);
}
