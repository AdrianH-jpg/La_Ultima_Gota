shader_type canvas_item;
// Shader de pantalla completa para el clima emocional.
// climate: 0 = sombrío/apagado, 0.5 = neutral (imagen sin tocar), 1 = eufórico/saturado.

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform float climate : hint_range(0.0, 1.0) = 0.5;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	float c = (climate - 0.5) * 2.0;      // -1 .. 1
	float high = max(c, 0.0);              // 0..1 hacia euforia
	float low = max(-c, 0.0);              // 0..1 hacia sombrío
	float extreme = abs(c);

	vec2 uv = SCREEN_UV;

	// Deformación ondulante (más fuerte en euforia, leve en sombrío)
	float warp = (high * high * 0.0045 + low * low * 0.0015) * intensity;
	uv += vec2(
		sin(uv.y * 18.0 + TIME * 2.0),
		cos(uv.x * 14.0 + TIME * 1.7)
	) * warp;

	// Aberración cromática en los extremos
	vec2 dir = normalize(uv - vec2(0.5) + 0.0001);
	float ca = extreme * extreme * 0.003 * intensity;
	vec3 col;
	col.r = texture(screen_tex, uv + dir * ca).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - dir * ca).b;

	// Saturación y contraste
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	float sat = 1.0 + (high * 0.9 - low * 0.85) * intensity;
	col = mix(vec3(lum), col, sat);
	float contrast = 1.0 + (high * 0.15 + low * 0.12) * intensity;
	col = (col - 0.5) * contrast + 0.5;

	// Tinte: cálido en euforia, frío en sombrío
	vec3 warm = vec3(1.06, 0.97, 0.88);
	vec3 cold = vec3(0.82, 0.90, 1.05);
	col *= mix(vec3(1.0), warm, high * intensity);
	col *= mix(vec3(1.0), cold, low * intensity);

	// Brillo: más oscuro en sombrío, un poco más luminoso en euforia
	col *= 1.0 - low * 0.25 * intensity + high * 0.06 * intensity;

	// Viñeta: fuerte en sombrío, sutil y pulsante en euforia
	float d = distance(SCREEN_UV, vec2(0.5));
	float pulse = 0.5 + 0.5 * sin(TIME * 2.2);
	float vig_amount = low * 0.6 + high * 0.15 * pulse;
	col *= 1.0 - smoothstep(0.35, 0.85, d) * vig_amount * intensity;

	COLOR = vec4(clamp(col, 0.0, 1.5), 1.0);
}
