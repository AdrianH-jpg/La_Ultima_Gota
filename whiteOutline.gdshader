
shader_type canvas_item;

// CONFIGURACIÓN DEL BORDE
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_size : hint_range(0.0, 10.0, 0.5) = 3.0;

// TEXTURA DE PAPEL
uniform sampler2D paper_texture : source_color, repeat_enable;
uniform float texture_strength : hint_range(0.0, 1.0) = 0.20;
uniform float texture_scale : hint_range(1.0, 20.0, 0.5) = 8.0;

void fragment() {
    vec4 original = texture(TEXTURE, UV);
    vec2 pixel = TEXTURE_PIXEL_SIZE * outline_size;

    // Detectar la silueta del personaje
    float surrounding_alpha = 0.0;

    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 offset = vec2(float(x), float(y)) * pixel;

            surrounding_alpha = max(
                surrounding_alpha,
                texture(TEXTURE, UV + offset).a
            );
        }
    }

    // Generar el borde exterior
    float outline = surrounding_alpha * (1.0 - original.a);

    // Aplicar textura de papel al borde
    float grain = texture(
        paper_texture,
        UV * texture_scale
    ).r;

    float textured_white = mix(
        1.0,
        grain,
        texture_strength
    );

    // Combinar borde y personaje
    vec3 final_rgb = mix(
        outline_color.rgb * textured_white,
        original.rgb,
        original.a
    );

float textured_alpha = mix(
    1.0,
    grain,
    texture_strength
);

float final_alpha = max(
    original.a,
    outline * outline_color.a * textured_alpha
);

    COLOR = vec4(final_rgb, final_alpha);
}
