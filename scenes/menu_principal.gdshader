
shader_type canvas_item;

uniform float intensidad : hint_range(0.0, 1.0) = 0.35;
uniform float velocidad : hint_range(0.1, 3.0) = 1.0;
uniform float inclinacion : hint_range(-0.5, 0.5) = 0.16;

float aleatorio(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 p = UV * vec2(125.0, 48.0);

    // Movimiento descendente y diagonal
    p.y -= TIME * 22.0 * velocidad;
    p.x += p.y * inclinacion;

    vec2 celda = floor(p);
    vec2 pos = fract(p);

    // Distribución irregular de las gotas
    float semilla = aleatorio(celda);
    float x = 0.2 + 0.6 * aleatorio(celda + vec2(3.4, 7.7));
    float y = 0.2 + 0.6 * aleatorio(celda + vec2(8.1, 2.2));

    // Forma alargada de cada gota
    float ancho = 1.0 - smoothstep(0.02, 0.08, abs(pos.x - x));
    float largo = 1.0 - smoothstep(0.0, 0.43, abs(pos.y - y));

    float gota = ancho * largo * step(0.82, semilla);

    // Gris frío con fondo transparente
    COLOR = vec4(vec3(0.38, 0.43, 0.50), gota * intensidad);
}
