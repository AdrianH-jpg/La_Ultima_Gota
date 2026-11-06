
shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_size : hint_range(0.0, 10.0, 0.5) = 3.0;

void fragment() {
    vec4 original = texture(TEXTURE, UV);
    vec2 pixel = TEXTURE_PIXEL_SIZE * outline_size;

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

    float outline = surrounding_alpha * (1.0 - original.a);

    vec3 final_rgb = mix(
        outline_color.rgb,
        original.rgb,
        original.a
    );

    float final_alpha = max(original.a, outline * outline_color.a);

    COLOR = vec4(final_rgb, final_alpha);
}
